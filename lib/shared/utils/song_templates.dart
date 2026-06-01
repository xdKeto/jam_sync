import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<Map<String, dynamic>> songTemplates = [
  {
    "id": "kj415",
    "name": "KJ 415 - Gembala Baik",
    "description": "Kidung Jemaat 415",
    "canvas": {"title": "KJ 415", "tempo": 75, "timeSignature": "4/4", "type": "manual"},
    "sections": [
      {
        "name": "Intro",
        "order": 0,
        "bars": [
          {
            "chords": ["", "", "", ""],
          },
          {
            "chords": ["C#m", "", "G#m", ""],
          },
          {
            "chords": ["F#m", "", "", ""],
          },
          {
            "chords": ["C#m", "", "G#m", ""],
          },
          {
            "chords": ["D", "", "", ""],
          },
          {
            "chords": ["B", "", "", ""],
          },
        ],
      },
      {
        "name": "Verse 1",
        "order": 1,
        "bars": [
          {
            "chords": ["E", "", "", ""],
          },
          {
            "chords": ["A", "", "", ""],
          },
          {
            "chords": ["G#m", "", "C#m", ""],
          },
          {
            "chords": ["D", "", "B", ""],
          },
          {
            "chords": ["E", "", "", ""],
          },
          {
            "chords": ["A", "", "", ""],
          },
          {
            "chords": ["F#m", "", "B", ""],
          },
          {
            "chords": ["E", "", "E7", ""],
          },
        ],
      },
      {
        "name": "Chorus 1",
        "order": 2,
        "bars": [
          {
            "chords": ["A", "", "", ""],
          },
          {
            "chords": ["G#m", "", "C#m", ""],
          },
          {
            "chords": ["F#m", "", "B", ""],
          },
          {
            "chords": ["E", "", "E7", ""],
          },
          {
            "chords": ["A", "", "", ""],
          },
          {
            "chords": ["G#m", "", "C#m", ""],
          },
          {
            "chords": ["F#m", "", "B", ""],
          },
          {
            "chords": ["E", "", "E7", ""],
          },
        ],
      },
      {
        "name": "Intro",
        "order": 3,
        "bars": [
          {
            "chords": ["C#m", "", "G#m", ""],
          },
          {
            "chords": ["F#m", "", "", ""],
          },
          {
            "chords": ["C#m", "", "G#m", ""],
          },
          {
            "chords": ["D", "", "", ""],
          },
          {
            "chords": ["B", "", "", ""],
          },
        ],
      },
      {
        "name": "Verse 2",
        "order": 4,
        "bars": [
          {
            "chords": ["E", "", "", ""],
          },
          {
            "chords": ["A", "", "", ""],
          },
          {
            "chords": ["G#m", "", "C#m", ""],
          },
          {
            "chords": ["D", "", "B", ""],
          },
          {
            "chords": ["E", "", "", ""],
          },
          {
            "chords": ["A", "", "", ""],
          },
          {
            "chords": ["F#m", "", "B", ""],
          },
          {
            "chords": ["E", "", "E7", ""],
          },
        ],
      },
      {
        "name": "Chorus 2",
        "order": 5,
        "bars": [
          {
            "chords": ["A", "", "", ""],
          },
          {
            "chords": ["G#m", "", "C#m", ""],
          },
          {
            "chords": ["F#m", "", "B", ""],
          },
          {
            "chords": ["E", "", "E7", ""],
          },
          {
            "chords": ["A", "", "", ""],
          },
          {
            "chords": ["G#m", "", "C#m", ""],
          },
          {
            "chords": ["F#m", "", "B", ""],
          },
          {
            "chords": ["E", "", "", ""],
          },
          {
            "chords": ["E", "", "", ""],
          },
        ],
      },
    ],
  },
];

Future<void> loadSongTemplatesFromSupabase() async {
  try {
    final response = await Supabase.instance.client.storage
        .from('song-template')
        .download('song_templates.json');

    final jsonString = utf8.decode(response);
    final List<dynamic> decoded = json.decode(jsonString);

    songTemplates = decoded.cast<Map<String, dynamic>>();
  } catch (e) {
    debugPrint(e.toString());
  }
}
