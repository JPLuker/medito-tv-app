/// Strongly typed mock data for contributor mock mode.
/// Uses real model constructors so the data is always in sync with the app's types.
library;

import 'package:medito/models/home/home_model.dart';
import 'package:medito/models/home/shortcuts/shortcuts_model.dart';
import 'package:medito/models/home/announcement/announcement_model.dart';
import 'package:medito/models/pack/pack_model.dart';
import 'package:medito/models/track/track.dart';
import 'package:medito/models/me/me_model.dart';
import 'package:medito/models/stats/all_stats_model.dart';
import 'package:medito/models/favorites/favorite_item.dart';
import 'package:medito/models/background_sounds/background_sounds_model.dart';
import 'package:medito/models/events/donation/donation_page_model.dart';
import 'package:medito/models/maintenance/maintenance_model.dart';

// The sample file is genuinely ~15 seconds long. TrackAudioFile.duration is in
// milliseconds, so keeping the metadata at 15,000 makes mock playback useful
// for progress, seek, completion and end-state testing instead of showing 0 min.
const _trackAudioUrl = 'https://download.samplelib.com/mp3/sample-15s.mp3';
const _trackAudioDurationMs = 15000;
const _bgSoundAudioUrl = 'https://download.samplelib.com/mp3/sample-9s.mp3';

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

final mockHome = HomeModel(
  greeting: 'Welcome back',
  shortcuts: [
    const ShortcutsModel(
      id: 'shortcut-1',
      type: 'track',
      title: 'Daily Calm',
      path: 'tracks/track-1',
      icon: '🧘',
    ),
    const ShortcutsModel(
      id: 'shortcut-2',
      type: 'pack',
      title: 'Sleep',
      path: 'packs/pack-2',
      icon: '🌙',
    ),
  ],
  carousel: [
    const HomeCarouselModel(
      id: 'carousel-1',
      title: 'New: Mindful Morning',
      subtitle: 'Start your day with intention',
      coverUrl: 'https://picsum.photos/seed/medito1/800/400',
      path: 'packs/pack-1',
      type: 'pack',
    ),
    const HomeCarouselModel(
      id: 'carousel-2',
      title: 'Sleep Stories',
      subtitle: 'Drift off to peaceful sleep',
      coverUrl: 'https://picsum.photos/seed/medito2/800/400',
      path: 'packs/pack-2',
      type: 'pack',
    ),
  ],
  todayQuote: const HomeQuoteModel(
    id: 'quote-1',
    quote:
        'The present moment is filled with joy and happiness. If you are attentive, you will see it.',
    author: 'Thich Nhat Hanh',
  ),
);

// ---------------------------------------------------------------------------
// Packs
// ---------------------------------------------------------------------------

final mockPacks = [
  const PackModel(
    id: 'pack-1',
    title: "Beginner's Guide to Meditation",
    subtitle: '3 quick TV test sessions',
    coverUrl: 'https://picsum.photos/seed/pack1/400/400',
    path: 'packs/pack-1',
    description:
        'Short mock sessions for testing TV navigation, playback, favorites, ambient sound and completion.',
    isPublished: true,
    items: [
      PackItemsModel(
        type: 'track',
        id: 'track-1',
        title: 'Introduction to Meditation',
        subtitle: '15 sec test',
        coverUrl: 'https://picsum.photos/seed/track1/400/400',
        path: 'tracks/track-1',
      ),
      PackItemsModel(
        type: 'track',
        id: 'track-2',
        title: 'Breath Awareness',
        subtitle: '15 sec test',
        coverUrl: 'https://picsum.photos/seed/track2/400/400',
        path: 'tracks/track-2',
      ),
      PackItemsModel(
        type: 'track',
        id: 'track-3',
        title: 'Body Scan',
        subtitle: '15 sec · two guide options',
        coverUrl: 'https://picsum.photos/seed/track3/400/400',
        path: 'tracks/track-3',
      ),
    ],
  ),
  const PackModel(
    id: 'pack-2',
    title: 'Sleep Stories',
    subtitle: '2 quick TV test sessions',
    coverUrl: 'https://picsum.photos/seed/pack2/400/400',
    path: 'packs/pack-2',
    description: 'Short mock sessions for testing the television experience.',
    isPublished: true,
    items: [
      PackItemsModel(
        type: 'track',
        id: 'track-4',
        title: 'Rainy Night',
        subtitle: '15 sec test · no ambient sound',
        path: 'tracks/track-4',
      ),
      PackItemsModel(
        type: 'track',
        id: 'track-5',
        title: 'Ocean Waves',
        subtitle: '15 sec test · no ambient sound',
        path: 'tracks/track-5',
      ),
    ],
  ),
  const PackModel(
    id: 'pack-3',
    title: 'Stress & Anxiety',
    subtitle: 'Layout test collection',
    coverUrl: 'https://picsum.photos/seed/pack3/400/400',
    path: 'packs/pack-3',
    description: 'Techniques to manage stress and find calm in daily life.',
    isPublished: true,
  ),
];

// ---------------------------------------------------------------------------
// Tracks
// ---------------------------------------------------------------------------

final mockTracks = <String, Track>{
  'track-1': Track(
    id: 'track-1',
    title: 'Introduction to Meditation',
    subtitle: 'A gentle start to your practice',
    description:
        'This short mock session is designed to test TV playback, seeking, ambient sound and completion without waiting several minutes.',
    coverUrl: 'https://picsum.photos/seed/track1/400/400',
    isPublished: true,
    hasBackgroundSound: true,
    artist: TrackArtist(name: 'Medito Team', path: ''),
    voices: [
      TrackVoice(
        guideName: 'Default',
        audioFiles: [
          TrackAudioFile(
            id: 'file-1',
            path: _trackAudioUrl,
            duration: _trackAudioDurationMs,
          ),
        ],
      ),
    ],
  ),
  'track-2': Track(
    id: 'track-2',
    title: 'Breath Awareness',
    subtitle: 'Focus on your natural breath',
    description:
        'A short mock playback item for testing remote controls and the player progress state.',
    coverUrl: 'https://picsum.photos/seed/track2/400/400',
    isPublished: true,
    hasBackgroundSound: true,
    artist: TrackArtist(name: 'Medito Team', path: ''),
    voices: [
      TrackVoice(
        guideName: 'Default',
        audioFiles: [
          TrackAudioFile(
            id: 'file-2',
            path: _trackAudioUrl,
            duration: _trackAudioDurationMs,
          ),
        ],
      ),
    ],
  ),
  'track-3': Track(
    id: 'track-3',
    title: 'Body Scan',
    subtitle: 'Relax from head to toe',
    description:
        'TV test session with two guide choices, favorites, ambient sound, seeking and a fast completion path.',
    coverUrl: 'https://picsum.photos/seed/track3/400/400',
    isPublished: true,
    hasBackgroundSound: true,
    artist: TrackArtist(name: 'Medito Team', path: ''),
    voices: [
      TrackVoice(
        guideName: 'Alex',
        audioFiles: [
          TrackAudioFile(
            id: 'file-3-alex',
            path: _trackAudioUrl,
            duration: _trackAudioDurationMs,
          ),
        ],
      ),
      TrackVoice(
        guideName: 'Sam',
        audioFiles: [
          TrackAudioFile(
            id: 'file-3-sam',
            path: _trackAudioUrl,
            duration: _trackAudioDurationMs,
          ),
        ],
      ),
    ],
  ),
  'track-4': Track(
    id: 'track-4',
    title: 'Rainy Night',
    subtitle: 'A calming sleep story',
    description:
        'A short mock session with ambient sound disabled so the TV player can test that alternate state.',
    coverUrl: 'https://picsum.photos/seed/track4/400/400',
    isPublished: true,
    hasBackgroundSound: false,
    artist: TrackArtist(name: 'Medito Team', path: ''),
    voices: [
      TrackVoice(
        guideName: 'Default',
        audioFiles: [
          TrackAudioFile(
            id: 'file-4',
            path: _trackAudioUrl,
            duration: _trackAudioDurationMs,
          ),
        ],
      ),
    ],
  ),
  'track-5': Track(
    id: 'track-5',
    title: 'Ocean Waves',
    subtitle: 'Let the waves carry you to sleep',
    description:
        'Another short mock session for player, focus restoration and completion testing.',
    coverUrl: 'https://picsum.photos/seed/track5/400/400',
    isPublished: true,
    hasBackgroundSound: false,
    artist: TrackArtist(name: 'Medito Team', path: ''),
    voices: [
      TrackVoice(
        guideName: 'Default',
        audioFiles: [
          TrackAudioFile(
            id: 'file-5',
            path: _trackAudioUrl,
            duration: _trackAudioDurationMs,
          ),
        ],
      ),
    ],
  ),
};

// ---------------------------------------------------------------------------
// Me
// ---------------------------------------------------------------------------

const mockMe = MeModel(
  id: 'mock-user-001',
  email: 'contributor@medito.app',
  hasActiveSubscription: false,
);

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

final mockStats = AllStats(
  streakLongest: 7,
  totalTracksCompleted: 12,
  totalTimeListened: 5400,
  tracksChecked: ['track-1', 'track-2'],
  audioCompleted: [
    AudioCompleted(id: 'track-1', timestamp: 1700000000),
    AudioCompleted(id: 'track-2', timestamp: 1700100000),
  ],
  updated: DateTime.now().millisecondsSinceEpoch ~/ 1000,
);

// ---------------------------------------------------------------------------
// Favorites (server format uses FavoriteItemDto)
// ---------------------------------------------------------------------------

const mockFavorites = [
  FavoriteItemDto(
    id: 'track-1',
    title: 'Introduction to Meditation',
    subtitle: 'A gentle start to your practice',
    path: 'tracks/track-1',
    type: 'track',
    timestamp: 1700000000,
  ),
  FavoriteItemDto(
    id: 'pack-2',
    title: 'Sleep Stories',
    subtitle: 'Calming stories',
    path: 'packs/pack-2',
    type: 'pack',
    timestamp: 1700050000,
  ),
];

// ---------------------------------------------------------------------------
// Background Sounds
// ---------------------------------------------------------------------------

const mockBackgroundSounds = [
  BackgroundSoundsModel(
    id: 'bg-1',
    title: 'Rain',
    path: _bgSoundAudioUrl,
    duration: 9,
  ),
  BackgroundSoundsModel(
    id: 'bg-2',
    title: 'Forest',
    path: _bgSoundAudioUrl,
    duration: 9,
  ),
  BackgroundSoundsModel(
    id: 'bg-3',
    title: 'White Noise',
    path: _bgSoundAudioUrl,
    duration: 9,
  ),
];

// ---------------------------------------------------------------------------
// Announcement
// ---------------------------------------------------------------------------

const mockAnnouncement = AnnouncementModel(
  id: 'announcement-1',
  text: 'Welcome to Medito mock mode! You are running with sample data.',
  colorBackground: '#1C1C1E',
  colorText: '#FFFFFF',
);

// ---------------------------------------------------------------------------
// Donation
// ---------------------------------------------------------------------------

const mockDonation = DonationPageModel(
  id: 'donation-1',
  title: 'Support Medito',
  text: 'Help keep meditation free for everyone.',
  footerText: 'All donations go directly to the Medito Foundation.',
  buttons: [
    ButtonModel(title: '\$5', path: 'donate/5', type: 'donation'),
    ButtonModel(title: '\$10', path: 'donate/10', type: 'donation'),
  ],
);

// ---------------------------------------------------------------------------
// Maintenance
// ---------------------------------------------------------------------------

const mockMaintenance = MaintenanceModel(isUnderMaintenance: false);
