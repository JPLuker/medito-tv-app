import 'package:flutter/material.dart';
import 'package:medito/views/search/search_results.dart';

class TvSearchView extends StatefulWidget {
  const TvSearchView({super.key});

  @override
  State<TvSearchView> createState() => _TvSearchViewState();
}

class _TvSearchViewState extends State<TvSearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 28, 40, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    final ascii = value.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
                    if (_query != ascii) setState(() => _query = ascii);
                  },
                  style: theme.textTheme.titleLarge,
                  decoration: InputDecoration(
                    hintText: 'Search Medito',
                    prefixIcon: const Icon(Icons.search_rounded, size: 30),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                              _focusNode.requestFocus();
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SearchResults(
                  query: _query,
                  onBeforeNavigate: _focusNode.unfocus,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
