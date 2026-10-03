// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/constants/constants.dart';
import 'package:medito/exceptions/app_error.dart';
import 'package:medito/l10n/app_localizations.dart';
import 'package:medito/providers/favorites/favorites_provider.dart';
import 'package:medito/providers/device_capabilities_provider.dart';
import 'package:medito/providers/me/me_provider.dart';
import 'package:medito/providers/shared_preference/shared_preference_provider.dart';
import 'package:medito/providers/stats_provider.dart';
import 'package:medito/repositories/auth/auth_repository.dart';
import 'package:medito/services/analytics/crashlytics_service.dart';
import 'package:medito/services/analytics/firebase_analytics_service.dart';
import 'package:medito/services/analytics/meta_sdk_service.dart';
import 'package:medito/services/network/header_service.dart';
import 'package:medito/utils/logger.dart';
import 'package:email_validator/email_validator.dart';
import 'package:medito/widgets/dialogs/dialogs.dart';
import 'package:medito/widgets/snackbar_widget.dart';
import 'package:medito/utils/utils.dart';
import 'package:medito/routes/routes.dart' as routes;
import 'package:flutter/gestures.dart';
import 'package:medito/views/onboarding/onboarding_pager_screen.dart';
import 'package:medito/views/bottom_navigation/bottom_navigation_bar_view.dart';
import 'package:medito/views/root/root_page_view.dart';
import 'package:medito/views/tv/tv_sign_up_log_in_page.dart';
import 'package:app_links/app_links.dart';

import '../../providers/device_and_app_info/device_and_app_info_provider.dart';
import '../../providers/pack/pack_provider.dart';

final dev = const AppLoggerAdapter('SIGN_UP');

class SignUpLogInPage extends ConsumerWidget {
  const SignUpLogInPage({super.key, this.fromSettings = false});

  final bool fromSettings;
  static const routeName = '/signup';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositorySyncProvider);
    final user = authRepository.currentUser;

    dev.log('[SIGN_UP] Building SignUpLogInPage', level: 1000);
    dev.log('[SIGN_UP] Current user: $user', level: 1000);
    dev.log('[SIGN_UP] User email: ${user?.email}', level: 1000);

    if (user?.email != null && user?.email?.isNotEmpty == true) {
      dev.log(
        '[SIGN_UP] User has email, navigating back or to home',
        level: 1000,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: context.brandPurple),
        ),
      );
    }

    dev.log('[SIGN_UP] User has no email, showing sign-up form', level: 1000);
    final capabilities = ref.watch(deviceCapabilitiesProvider);
    return capabilities.when(
      data: (value) => value.isAndroidTv
          ? TvSignUpLogInFrame(
              child: SignUpLogInForm(
                fromSettings: fromSettings,
                tvEmbedded: true,
              ),
            )
          : SignUpLogInForm(fromSettings: fromSettings),
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: context.brandPurple),
        ),
      ),
      error: (_, _) => SignUpLogInForm(fromSettings: fromSettings),
    );
  }
}

class SignUpLogInForm extends ConsumerStatefulWidget {
  const SignUpLogInForm({
    super.key,
    required this.fromSettings,
    this.tvEmbedded = false,
  });

  final bool fromSettings;
  final bool tvEmbedded;

  @override
  ConsumerState<SignUpLogInForm> createState() => SignUpLogInFormState();
}

class SignUpLogInFormState extends ConsumerState<SignUpLogInForm> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  var _isLoading = false;
  var _isEmailValid = false;
  var _isOtpValid = false;
  var _hasRequestedOtp = false;
  var _isRateLimited = false;
  var _retryAfterSeconds = 0;
  Timer? _timer;
  StreamSubscription? _linkSubscription;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _otpController.addListener(_validateOtp);
    _setupDeepLinkHandling();
  }

  void _setupDeepLinkHandling() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (!mounted) return;

      if (uri.path.startsWith('/otp/')) {
        final otp = uri.pathSegments[1];
        if (otp.length == 6) {
          if (!mounted) return;

          if (!_hasRequestedOtp) {
            showSnackBar(
              context,
              AppLocalizations.of(context)!.requestOtpBeforeDeepLink,
            );
            return;
          }

          setState(() {
            _otpController.text = otp;
            _verifyOtp();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _linkSubscription?.cancel();
    _emailController.removeListener(_validateEmail);
    _otpController.removeListener(_validateOtp);
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = EmailValidator.validate(_emailController.text.trim());
    });
  }

  void _validateOtp() {
    setState(() {
      _isOtpValid = _otpController.text.trim().length == 6;
    });
  }

  bool get _isFormValid =>
      _isEmailValid && (_hasRequestedOtp ? _isOtpValid : true);

  Future<void> _requestOtp() async {
    if (_isLoading || _isRateLimited) return;

    final hasLocalStats = await ref.read(statsManagerProvider).hasLocalStats();

    if (hasLocalStats) {
      final proceed =
          await showDialog<bool>(
            context: context,
            builder: (context) => MeditoDialog(
              title: AppLocalizations.of(
                context,
              )!.accountTransitionWarningTitle,
              content: MeditoDialogBody(
                AppLocalizations.of(context)!.loginWarningExplanation,
              ),
              actions: [
                MeditoDialogSecondaryButton(
                  label: AppLocalizations.of(context)!.cancelAction,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                MeditoDialogDestructiveButton(
                  label: AppLocalizations.of(context)!.continueLogin,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;

      if (!proceed) return;
    }

    await _sendOtp();
  }

  Future<void> _sendOtp({bool allowNewAccount = true}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(authRepositorySyncProvider)
          .requestOtp(_emailController.text.trim().toLowerCase());
      setState(() {
        _hasRequestedOtp = true;
      });
    } on RateLimitError catch (e) {
      showSnackBar(context, e.message);
      setState(() {
        _isRateLimited = true;
        _retryAfterSeconds = e.tryAfterSeconds ?? 60;
      });
      _startRetryTimer();
    } on InactiveEmailError {
      showSnackBar(context, AppLocalizations.of(context)!.accountInactiveError);
    } on EmailMismatchError catch (e) {
      if (!mounted) return;
      if (!allowNewAccount) {
        showSnackBar(context, e.message);
        return;
      }
      final startNew =
          await showDialog<bool>(
            context: context,
            builder: (context) => MeditoDialog(
              title: AppLocalizations.of(context)!.emailMismatchDialogTitle,
              content: MeditoDialogBody(
                AppLocalizations.of(context)!.emailMismatchDialogMessage,
              ),
              actions: [
                MeditoDialogSecondaryButton(
                  label: AppLocalizations.of(context)!.emailMismatchGoBack,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                MeditoDialogPrimaryButton(
                  label: AppLocalizations.of(
                    context,
                  )!.emailMismatchStartNewAccount,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;
      if (!startNew || !mounted) return;

      final statsManager = ref.read(statsManagerProvider);
      await statsManager.initialize();
      await statsManager.clearAllStats();
      await ref
          .read(sharedPreferencesProvider)
          .remove(SharedPreferenceConstants.userId);
      setState(() {
        _isLoading = false;
      });
      await _sendOtp(allowNewAccount: false);
      return;
    } catch (e) {
      showSnackBar(
        context,
        '${AppLocalizations.of(context)!.errorPrefix}${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startRetryTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_retryAfterSeconds > 0) {
        setState(() {
          _retryAfterSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isRateLimited = false;
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      dev.log('[SIGN_UP] Starting OTP verification', level: 1000);
      dev.log('[SIGN_UP] Email: ${_emailController.text.trim()}', level: 1000);
      dev.log(
        '[SIGN_UP] OTP length: ${_otpController.text.trim().length}',
        level: 1000,
      );

      final previousUserId = ref
          .read(sharedPreferencesProvider)
          .getString(SharedPreferenceConstants.userId);

      var success = await ref
          .read(authRepositorySyncProvider)
          .verifyOtp(
            _emailController.text.trim().toLowerCase(),
            _otpController.text.trim(),
          );

      dev.log('[SIGN_UP] OTP verification result: $success', level: 1000);

      if (success) {
        dev.log(
          '[SIGN_UP] OTP verification successful, refreshing user info',
          level: 1000,
        );
        await _refreshUserInfo();
        ref.invalidate(userIdProvider);

        final authRepo = ref.read(authRepositorySyncProvider);
        dev.log(
          '[SIGN_UP] User after successful login: ${authRepo.currentUser}',
          level: 1000,
        );
        dev.log(
          '[SIGN_UP] User email after login: ${authRepo.getUserEmail()}',
          level: 1000,
        );

        try {
          final userId = ref.read(userIdProvider);
          if (userId != null && userId.isNotEmpty) {
            await FirebaseAnalyticsService().setUserId(userId);
            await MetaSdkService.instance.setUserId(userId);
            dev.log(
              '[SIGN_UP] User ID set for analytics: $userId',
              level: 1000,
            );
          }
        } catch (e) {
          dev.log(
            '[SIGN_UP] Error setting user ID for analytics: $e',
            level: 1000,
          );
        }

        await FirebaseAnalyticsService().logEvent(
          name: FirebaseAnalyticsService.eventOnboardingSignupCompleted,
        );

        final statsManager = ref.read(statsManagerProvider);
        await statsManager.initialize();
        final newUserId = authRepo.currentUser?.id;
        if (newUserId != previousUserId) {
          await statsManager.clearAllStats();
        }
        await statsManager.sync(force: true);
        ref.read(statsProvider.notifier).refresh();
        ref.invalidate(packProvider);

        unawaited(
          ref.read(favoritesNotifierProvider.notifier).syncWithServer(),
        );

        if (!mounted) return;

        dev.log(
          '[SIGN_UP] Login complete, navigating to next screen',
          level: 1000,
        );
        if (widget.fromSettings) {
          Navigator.of(context).pop();
        } else {
          final isTv = await ref.read(deviceCapabilitiesProvider.future).then(
                (value) => value.isAndroidTv,
                onError: (_) => false,
              );
          if (!mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => isTv
                  ? const RootPageView(firstChild: BottomNavigationBarView())
                  : const OnboardingPagerScreen(),
            ),
            (route) => false,
          );
        }
      } else {
        showSnackBar(
          context,
          AppLocalizations.of(context)!.authenticationFailed,
        );
      }
    } catch (e, st) {
      dev.log('[SIGN_UP] Error during OTP verification', error: e, level: 1000);
      if (e.toString().contains('403')) {
        showSnackBar(
          context,
          AppLocalizations.of(context)!.invalidVerificationCode,
        );
      } else {
        CrashlyticsService().recordError(
          e,
          st,
          reason: 'OTP verify post-success',
        );
        showSnackBar(
          context,
          '${AppLocalizations.of(context)!.errorPrefix}${e.toString()}',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshUserInfo() async {
    dev.log('[SIGN_UP] Starting user info refresh', level: 1000);

    ref.invalidate(meProvider);
    ref.invalidate(deviceAppAndUserInfoProvider);

    final authRepo = ref.read(authRepositorySyncProvider);
    dev.log(
      '[SIGN_UP] Auth state before header init: ${authRepo.currentUser}',
      level: 1000,
    );

    final deviceInfo = await ref.read(deviceAndAppInfoProvider.future);
    await HeaderService(deviceInfo).initialise();

    dev.log(
      '[SIGN_UP] Headers initialized, auth state after: ${authRepo.currentUser}',
      level: 1000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: widget.tvEmbedded ? 20 : null,
    );

    if (widget.tvEmbedded) {
      return Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(36, 28, 36, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasRequestedOtp) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _hasRequestedOtp = false;
                              _otpController.clear();
                            });
                          },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Change email'),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              _hasRequestedOtp
                  ? _buildOtpVerificationView(inputTextStyle)
                  : _buildInitialView(inputTextStyle),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _hasRequestedOtp
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _hasRequestedOtp = false;
                    _otpController.clear();
                  });
                },
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            32.0,
            0,
            32.0,
            MediaQuery.of(context).viewInsets.bottom + 32.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _hasRequestedOtp
                    ? _buildOtpVerificationView(inputTextStyle)
                    : _buildInitialView(inputTextStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialView(TextStyle inputTextStyle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.tvEmbedded
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        _buildBenefitsText(AppLocalizations.of(context)!.createAccountBenefits),
        widget.tvEmbedded ? height32 : height64,
        Text(
          AppLocalizations.of(context)!.emailVerificationText,
          textAlign: widget.tvEmbedded ? TextAlign.left : TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: widget.tvEmbedded ? 18 : 13,
            height: 1.5,
            fontWeight: FontWeight.normal,
          ),
        ),
        height16,
        _buildEmailField(inputTextStyle),
        height16,
        ElevatedButton(
          onPressed: (_isLoading || !_isFormValid || _isRateLimited)
              ? null
              : _requestOtp,
          style: _getButtonStyle(),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.onBrandPurple,
                    ),
                  ),
                )
              : _isRateLimited
              ? Text(
                  AppLocalizations.of(
                    context,
                  )!.retryInSeconds(_retryAfterSeconds.toString()),
                )
              : Text(AppLocalizations.of(context)!.sendMeMyPasswordText),
        ),
        if (!widget.tvEmbedded &&
            !ref.watch(deviceCapabilitiesProvider).maybeWhen(
              data: (value) => value.isAndroidTv,
              orElse: () => false,
            ))
          _buildPrivacyPolicyLink(),
        if (!widget.tvEmbedded) SizedBox.square(dimension: 100),
      ],
    );
  }

  Widget _buildOtpVerificationView(TextStyle inputTextStyle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.tvEmbedded
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${AppLocalizations.of(context)!.otpInstructions}\n',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: widget.tvEmbedded ? 22 : 18,
                  height: 1.5,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: _emailController.text,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: widget.tvEmbedded ? 22 : 18,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          textAlign: widget.tvEmbedded ? TextAlign.left : TextAlign.center,
        ),
        height32,
        _buildOtpField(inputTextStyle),
        height16,
        ElevatedButton(
          onPressed: (_isLoading || !_isOtpValid) ? null : _verifyOtp,
          style: _getButtonStyle(),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.onBrandPurple,
                    ),
                  ),
                )
              : Text(AppLocalizations.of(context)!.verifyOtpButtonText),
        ),
        height16,
        TextButton(
          onPressed: _isLoading || _isRateLimited ? null : _requestOtp,
          style: TextButton.styleFrom(
            minimumSize: Size(0, widget.tvEmbedded ? 52 : 32),
            tapTargetSize: widget.tvEmbedded
                ? MaterialTapTargetSize.padded
                : MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isRateLimited
                ? AppLocalizations.of(
                    context,
                  )!.resendCodeInSeconds(_retryAfterSeconds.toString())
                : AppLocalizations.of(context)!.resendCode,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _isLoading || _isRateLimited
                  ? Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacityValue(0.38)
                  : ColorConstants.brightSky,
              fontSize: widget.tvEmbedded ? 18 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(TextStyle inputTextStyle) {
    return TextField(
      controller: _emailController,
      enabled: !_hasRequestedOtp,
      decoration:
          getInputDecoration(
            AppLocalizations.of(context)!.emailLabel,
            _isEmailValid || _emailController.text.isEmpty,
            AppLocalizations.of(context)!.invalidEmailError,
          ).copyWith(
            fillColor: Theme.of(context).colorScheme.surface,
            filled: true,
            suffixIcon: _emailController.text.isNotEmpty && !_hasRequestedOtp
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacityValue(0.6),
                    ),
                    onPressed: () {
                      _emailController.clear();
                      _validateEmail();
                    },
                  )
                : null,
          ),
      onChanged: (_) => setState(() {}),
      style: inputTextStyle,
      keyboardType: TextInputType.emailAddress,
      inputFormatters: [
        TextInputFormatter.withFunction(
          (oldValue, newValue) => TextEditingValue(
            text: newValue.text.toLowerCase(),
            selection: newValue.selection,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpField(TextStyle inputTextStyle) {
    return TextField(
      controller: _otpController,
      decoration:
          getInputDecoration(
            AppLocalizations.of(context)!.otpLabel,
            _isOtpValid || _otpController.text.isEmpty,
            AppLocalizations.of(context)!.invalidOtpError,
          ).copyWith(
            fillColor: Theme.of(context).colorScheme.surface,
            filled: true,
          ),
      style: inputTextStyle,
      keyboardType: TextInputType.number,
      maxLength: 6,
    );
  }

  Widget _buildPrivacyPolicyLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: Text.rich(
          TextSpan(
            text: AppLocalizations.of(context)!.byContinuingAgreeTo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacityValue(0.7),
              fontSize: 12,
            ),
            children: [
              TextSpan(
                text: 'Terms of Service',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => routes.handleNavigation(
                    TypeConstants.url,
                    ['https://meditofoundation.org/terms'],
                    context,
                    ref: ref,
                  ),
              ),
              TextSpan(text: AppLocalizations.of(context)!.andText),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => routes.handleNavigation(
                    TypeConstants.url,
                    ['https://meditofoundation.org/privacy'],
                    context,
                    ref: ref,
                  ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      backgroundColor: context.brandPurple,
      disabledForegroundColor: context.onBrandPurple.withValues(alpha: 0.6),
      disabledBackgroundColor: context.brandPurple.withOpacityValue(0.5),
      minimumSize: Size(double.infinity, widget.tvEmbedded ? 62 : 48),
      textStyle: widget.tvEmbedded
          ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )
          : null,
    );
  }

  InputDecoration getInputDecoration(
    String hint,
    bool isValid,
    String? errorText,
  ) {
    final borderRadius = BorderRadius.all(
      Radius.circular(widget.tvEmbedded ? 12 : 4),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacityValue(0.6),
        fontSize: widget.tvEmbedded ? 19 : null,
      ),
      contentPadding: widget.tvEmbedded
          ? const EdgeInsets.symmetric(horizontal: 22, vertical: 21)
          : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: ColorConstants.softGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: context.brandPurple,
          width: widget.tvEmbedded ? 3 : 1,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: ColorConstants.softGrey),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red),
      ),
      errorText: !isValid && errorText != null ? errorText : null,
      errorStyle: const TextStyle(color: Colors.red),
    );
  }

  Widget _buildBenefitsText(String text) {
    return Text(
      text,
      textAlign: TextAlign.start,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontSize: widget.tvEmbedded ? 28 : 20,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
