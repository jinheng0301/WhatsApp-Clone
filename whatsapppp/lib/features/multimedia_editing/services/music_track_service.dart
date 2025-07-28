// External Music Selection Service
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Music Track Model
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String previewUrl;
  final String downloadUrl;
  final String artworkUrl;
  final String genre;
  final bool isPremium;

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.previewUrl,
    required this.downloadUrl,
    required this.artworkUrl,
    required this.genre,
    this.isPremium = false,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      album: json['album'] ?? 'Unknown Album',
      duration: Duration(seconds: json['duration'] ?? 0),
      previewUrl: json['preview_url'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      artworkUrl: json['artwork_url'] ?? '',
      genre: json['genre'] ?? 'Unknown',
      isPremium: json['is_premium'] ?? false,
    );
  }
}

// Music Category Model
class MusicCategory {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final Color color;

  MusicCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.color,
  });
}

// External Music Service Class
class ExternalMusicService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Predefined music categories
  static final List<MusicCategory> musicCategories = [
    MusicCategory(
      id: 'ambient',
      name: 'Ambient',
      description: 'Calm background music',
      iconUrl: '🌙',
      color: Colors.purple,
    ),
    MusicCategory(
      id: 'electronic',
      name: 'Electronic',
      description: 'Modern electronic beats',
      iconUrl: '🎛️',
      color: Colors.blue,
    ),
    MusicCategory(
      id: 'acoustic',
      name: 'Acoustic',
      description: 'Natural instrumental sounds',
      iconUrl: '🎸',
      color: Colors.brown,
    ),
    MusicCategory(
      id: 'cinematic',
      name: 'Cinematic',
      description: 'Epic movie-style music',
      iconUrl: '🎬',
      color: Colors.red,
    ),
    MusicCategory(
      id: 'jazz',
      name: 'Jazz',
      description: 'Smooth jazz melodies',
      iconUrl: '🎷',
      color: Colors.orange,
    ),
    MusicCategory(
      id: 'classical',
      name: 'Classical',
      description: 'Timeless classical pieces',
      iconUrl: '🎼',
      color: Colors.indigo,
    ),
  ];

  // Fetch trending music tracks
  static Future<List<MusicTrack>> fetchTrendingMusic({int limit = 20}) async {
    try {
      // Simulating API call with sample data
      // In production, replace with actual API endpoints
      await Future.delayed(const Duration(seconds: 1));

      return _generateSampleTracks('trending', limit);
    } catch (e) {
      print('Error fetching trending music: $e');
      return [];
    }
  }

  // Fetch music by category
  static Future<List<MusicTrack>> fetchMusicByCategory(
    String categoryId, {
    int limit = 20,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return _generateSampleTracks(categoryId, limit);
    } catch (e) {
      print('Error fetching music by category: $e');
      return [];
    }
  }

  // Search music tracks
  static Future<List<MusicTrack>> searchMusic(
    String query, {
    int limit = 20,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return _generateSampleTracks('search', limit, query: query);
    } catch (e) {
      print('Error searching music: $e');
      return [];
    }
  }

  // Preview music track
  static Future<void> previewTrack(MusicTrack track) async {
    try {
      if (track.previewUrl.isNotEmpty) {
        await _audioPlayer.play(UrlSource(track.previewUrl));
      } else {
        throw Exception('No preview available');
      }
    } catch (e) {
      throw Exception('Error playing preview: $e');
    }
  }

  // Stop preview
  static Future<void> stopPreview() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping preview: $e');
    }
  }

  // Download music track
  static Future<String?> downloadTrack(MusicTrack track) async {
    try {
      if (track.downloadUrl.isEmpty) {
        throw Exception('Download URL not available');
      }

      // Request storage permission
      if (await Permission.storage.request().isGranted) {
        final response = await http.get(Uri.parse(track.downloadUrl));

        if (response.statusCode == 200) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = '${track.artist}_${track.title}.mp3'
              .replaceAll(RegExp(r'[^\w\s-]'), '')
              .replaceAll(' ', '_');

          final file = File('${directory.path}/music/$fileName');
          await file.create(recursive: true);
          await file.writeAsBytes(response.bodyBytes);

          return file.path;
        } else {
          throw Exception('Failed to download: ${response.statusCode}');
        }
      } else {
        throw Exception('Storage permission denied');
      }
    } catch (e) {
      print('Error downloading track: $e');
      return null;
    }
  }

  // Get popular playlists
  static Future<List<Map<String, dynamic>>> fetchPopularPlaylists() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      return [
        {
          'id': 'chill_vibes',
          'name': 'Chill Vibes',
          'description': 'Relaxing tracks for your videos',
          'trackCount': 25,
          'duration': '1h 32m',
          'artwork': '🌊',
        },
        {
          'id': 'upbeat_motivation',
          'name': 'Upbeat Motivation',
          'description': 'Energetic music for action videos',
          'trackCount': 30,
          'duration': '2h 15m',
          'artwork': '⚡',
        },
        {
          'id': 'cinematic_scores',
          'name': 'Cinematic Scores',
          'description': 'Epic background music',
          'trackCount': 18,
          'duration': '1h 48m',
          'artwork': '🎭',
        },
        {
          'id': 'nature_sounds',
          'name': 'Nature & Ambient',
          'description': 'Natural soundscapes',
          'trackCount': 22,
          'duration': '2h 5m',
          'artwork': '🌿',
        },
      ];
    } catch (e) {
      print('Error fetching playlists: $e');
      return [];
    }
  }

  // Generate sample tracks for demonstration
  static List<MusicTrack> _generateSampleTracks(
    String category,
    int limit, {
    String? query,
  }) {
    final sampleTracks = <MusicTrack>[];
    final random = DateTime.now().millisecondsSinceEpoch;

    final trackNames = [
      'Sunset Dreams',
      'Ocean Waves',
      'Mountain Echo',
      'City Lights',
      'Peaceful Journey',
      'Electric Pulse',
      'Gentle Breeze',
      'Starlit Night',
      'Golden Hour',
      'Distant Thunder',
      'Whispered Secrets',
      'Neon Glow',
      'Forest Path',
      'Digital Dawn',
      'Silent Storm',
      'Mystic River',
      'Cosmic Dance',
      'Velvet Sky',
      'Morning Dew',
      'Infinity Loop'
    ];

    final artists = [
      'AudioNova',
      'SoundWave Studios',
      'Harmony Collective',
      'Echo Chamber',
      'Melody Makers',
      'Rhythm Factory',
      'Sonic Landscapes',
      'Beat Architects',
      'Frequency Labs',
      'Audio Artisans',
      'Sound Sculptors',
      'Music Mindset'
    ];

    for (int i = 0; i < limit && i < trackNames.length; i++) {
      sampleTracks.add(MusicTrack(
        id: '${category}_track_$i',
        title: trackNames[i],
        artist: artists[i % artists.length],
        album: '${category.capitalize()} Collection',
        duration: Duration(seconds: 120 + (i * 15)), // 2-7 minutes
        previewUrl: 'https://example.com/preview/${category}_$i.mp3',
        downloadUrl: 'https://example.com/download/${category}_$i.mp3',
        artworkUrl: 'https://picsum.photos/200/200?random=$random$i',
        genre: category.capitalize(),
        isPremium: i % 5 == 0, // Every 5th track is premium
      ));
    }

    return sampleTracks;
  }

  // Dispose resources
  static void dispose() {
    _audioPlayer.dispose();
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
