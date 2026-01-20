## **PRD: Collaborative Music Score App with Real-Time Synchronization**

**Project:** Thesis \- Server-Authoritative Clock \+ Client-Side Interpolation for Real-Time Music Collaboration **Student:** Yestoya Lumenchristo Minggus (C14220331) **Institution:** Universitas Kristen Petra, Informatika **Timeline:** 4 months (Jan 12 \- May 12, 2026\) **Budget:** Zero (Free tier only, no credit card)

---

## **1\. SYSTEM OVERVIEW**

### **1.1 Core Problem**

Musicians using individual devices for digital scores lack synchronized visual playback, causing coordination issues during rehearsals. Target: MAD ≤30ms between clients.

### **1.2 Solution Architecture**

- **Frontend:** Flutter (Android \+ iOS, min SDK 24\)
- **Backend:** Firebase (Firestore \+ Realtime Database)
- **Audio Processing:** Python on Hugging Face Spaces (Gradio)
- **Auth:** Google Sign-In
- **Storage:** Supabase Storage (for audio/image files \- Firebase Storage requires Blaze plan)

### **1.3 Key Features**

1. Chord extraction from audio files
2. Collaborative score editing (Last-Write-Wins)
3. Synchronized playback with server-authoritative clock
4. Two modes: Play Along (with audio) & Play Together (live collaboration)

---

## **2\. TECHNICAL ARCHITECTURE**

### **2.1 Flutter Stack**

\# Core  
\- Flutter SDK: Latest stable  
\- Dart: 3.x  
\- Min Android SDK: 24 (Android 7.0)  
\- Min iOS: 12.0

\# State Management  
\- riverpod: ^2.5.0  
\- flutter_riverpod: ^2.5.0  
\- riverpod_annotation: ^2.3.0  
\- riverpod_generator: ^2.4.0

\# Firebase  
\- firebase_core: ^3.0.0  
\- firebase_auth: ^5.0.0  
\- cloud_firestore: ^5.0.0  
\- firebase_database: ^11.0.0  
\- google_sign_in: ^6.2.0

\# Supabase (Storage only)  
\- supabase_flutter: ^2.0.0

\# Audio  
\- just_audio: ^0.9.0 (for playback)  
\- file_picker: ^8.0.0 (for audio upload)

\# HTTP  
\- dio: ^5.0.0 (for Hugging Face Spaces API calls)  
\- http: ^1.2.0

\# Utilities  
\- freezed: ^2.5.0 (immutable models)  
\- freezed_annotation: ^2.4.0  
\- json_annotation: ^4.9.0  
\- json_serializable: ^6.8.0  
\- uuid: ^4.0.0  
\- intl: ^0.19.0

\# Dev Dependencies  
\- build_runner: ^2.4.0  
\- riverpod_lint: ^2.3.0

### **2.2 Firebase Project Structure**

#### **Project Setup (NO CREDIT CARD REQUIRED)**

1\. Create Firebase project: https://console.firebase.google.com  
 \- Project name: "collaborative-music-score" or similar  
 \- Disable Google Analytics (not needed, saves quota)  
 \- Region: asia-southeast1 (closest to Indonesia)

2\. Enable services:  
 \- Authentication → Google Sign-In  
 \- Firestore Database → Production mode  
 \- Realtime Database → Locked mode initially  
 \- ~~Storage~~ (NOT USED \- requires Blaze plan, using Supabase instead)

3\. Add Android app:  
 \- Package name: com.petra.collaborative_score (or your choice)  
 \- Download google-services.json → android/app/

4\. Add iOS app:  
 \- Bundle ID: com.petra.collaborativeScore  
 \- Download GoogleService-Info.plist → ios/Runner/

#### **Firestore Structure**

/users/{userId}  
 \- email: string  
 \- displayName: string  
 \- photoUrl: string  
 \- createdAt: timestamp  
 \- lastSeenAt: timestamp

/projects/{projectId}  
 \- name: string  
 \- createdBy: userId  
 \- createdAt: timestamp  
 \- updatedAt: timestamp  
 \- defaultTempo: number (BPM, default for new pages)  
 \- defaultTimeSignature: string (e.g., "4/4")  
 \- leaderId: userId

/pages/{pageId} \[subcollection\]  
 \- title: string ("Untitled", "Verse 1", etc.)  
 \- source: string ("manual" | "audio_extraction")  
 \- audioUrl: string? (only if source = audio_extraction)  
 \- audioFileName: string?  
 \- extractionStatus: string? ("pending" | "processing" | "completed" | "failed")  
 \- tempo: number (BPM)  
 \- timeSignature: string  
 \- totalBars: number  
 \- order: number (for tab sorting)  
 \- createdAt: timestamp  
 \- updatedAt: timestamp  
 \- createdBy: userId

/bars/{barId} \[subcollection of pages\]  
 \- barNumber: number (1, 2, 3, ...)  
 \- beats: array \[  
 { beatIndex: 0, chord: "C", notes: "" },  
 { beatIndex: 1, chord: "Dm", notes: "" },  
 ...  
 \]  
 \- updatedAt: timestamp  
 \- updatedBy: userId

/participants/{userId} \[subcollection\]  
 \- role: string ("leader" | "member")  
 \- displayName: string  
 \- isReady: boolean  
 \- joinedAt: timestamp

/logs/{logId} \[subcollection\]  
 \- clientId: string  
 \- pageId: string (which page was being played)  
 \- timestamp: number (milliseconds)  
 \- currentPositionMs: number  
 \- serverTimeOffset: number  
 \- eventType: string ("playback_sample" | "sync_event")  
 \- metadata: map

#### **Realtime Database Structure**

{  
 "playback_sessions": {  
 "{projectId}": {  
 "isPlaying": false,  
 "serverStartTime": 0,  
 "currentPositionMs": 0,  
 "lastSyncTime": 0,  
 "leaderId": "userId",  
 "readyClients": {  
 "client1Id": true,  
 "client2Id": false  
 }  
 }  
 },  
 "presence": {  
 "{userId}": {  
 "online": true,  
 "lastSeen": 1705000000000,  
 "currentProject": "projectId"  
 }  
 }  
}

#### **Security Rules \- Firestore**

rules_version \= '2';  
service cloud.firestore {  
 match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth \!= null;
    }

    function isProjectParticipant(projectId) {
      return exists(/databases/$(database)/documents/projects/$(projectId)/participants/$(request.auth.uid));
    }

    function isProjectLeader(projectId) {
      return get(/databases/$(database)/documents/projects/$(projectId)/participants/$(request.auth.uid)).data.role \== "leader";
    }

    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid \== userId;
    }

    match /projects/{projectId} {
      allow read: if isAuthenticated() && isProjectParticipant(projectId);
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && isProjectLeader(projectId);
      allow delete: if isAuthenticated() && isProjectLeader(projectId);

      match /pages/{pageId} {
        allow read: if isAuthenticated() && isProjectParticipant(projectId);
        allow create: if isAuthenticated() && isProjectParticipant(projectId);
        allow update: if isAuthenticated() && isProjectParticipant(projectId);
        allow delete: if isAuthenticated() && isProjectLeader(projectId);

        match /bars/{barId} {
          allow read: if isAuthenticated() && isProjectParticipant(projectId);
          allow write: if isAuthenticated() && isProjectParticipant(projectId);
        }
      }

      match /participants/{userId} {
        allow read: if isAuthenticated() && isProjectParticipant(projectId);
        allow create: if isAuthenticated();
        allow update: if isAuthenticated() && (request.auth.uid \== userId || isProjectLeader(projectId));
        allow delete: if isAuthenticated() && (request.auth.uid \== userId || isProjectLeader(projectId));
      }

      match /logs/{logId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() && isProjectParticipant(projectId);
      }
    }

}  
}

#### **Security Rules \- Realtime Database**

{  
 "rules": {  
 "playback_sessions": {  
 "$projectId": {  
        ".read": "auth \!= null",  
        ".write": "auth \!= null"  
      }  
    },  
    "presence": {  
      "$userId": {  
 ".read": "auth \!= null",  
 ".write": "auth \!= null && auth.uid \=== $userId"  
 }  
 }  
 }  
}

#### **Supabase Storage Setup (for Audio/Image Files)**

> [!NOTE]
> Firebase Storage requires Blaze plan (credit card). Using Supabase Storage instead.
> Free tier: 1GB storage, 2GB bandwidth/month, no credit card required.

**Setup Steps:**

1\. Create Supabase project: https://supabase.com
 \- Project name: "jamsync-storage" or similar
 \- Region: Southeast Asia (Singapore)
 \- Save Project URL and anon key

2\. Create Storage Bucket:
 \- Go to Storage → New Bucket
 \- Name: "audio-files"
 \- Public bucket: Yes (for playback access)

3\. Storage Policies (RLS):


```sql
-- Public bucket: Allow all operations
-- Security handled via Firestore (who can access projectId)
-- File path: projects/{projectId}/{filename}

CREATE POLICY "Allow public uploads"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'audio-files');

CREATE POLICY "Allow public reads"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'audio-files');

CREATE POLICY "Allow public deletes"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'audio-files');
```


4\. Flutter Integration:

```dart
// Initialize in main.dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_ANON_KEY',
);

// Upload audio file
Future<String> uploadAudio(String projectId, String fileName, Uint8List bytes) async {
  final path = 'projects/$projectId/$fileName';
  await Supabase.instance.client.storage
      .from('audio-files')
      .uploadBinary(path, bytes);
  
  return Supabase.instance.client.storage
      .from('audio-files')
      .getPublicUrl(path);
}
```


### **2.3 Hugging Face Spaces \- Chord Extraction Service**

> \[!IMPORTANT\]  
> Hugging Face Spaces gratis tanpa credit card, namun Space harus di-set **public** (kode terlihat publik).  
> Ini acceptable untuk thesis project. Cold start ~30-60 detik setelah idle.

#### **Struktur File untuk HF Spaces**

```
chord_extraction_service/
├── app.py              # Main Gradio app
├── requirements.txt    # Python dependencies
└── README.md          # HF Spaces config (YAML frontmatter)
```

#### **README.md (HF Spaces Config)**

```yaml
---
title: Chord Extraction Service
emoji: 🎵
colorFrom: purple
colorTo: blue
sdk: gradio
sdk_version: 4.44.0
app_file: app.py
pinned: false
---
```

#### **requirements.txt (Python Service)**

```
chord-extractor==1.1.0
librosa==0.10.1
vamp==1.1.0
gradio==4.44.0
requests==2.31.0
```

#### **app.py Structure**

```python
import gradio as gr
import tempfile
import os
import json
import requests
from chord_extractor.extractors import Chordino
import librosa

def extract_chords_from_url(audio_url: str, tempo: int = None, time_signature: str = "4/4"):
    """
    Download audio from URL (Firebase Storage public URL) and extract chords.
    Returns JSON with chord data.
    """
    try:
        # Download audio from URL
        response = requests.get(audio_url)
        response.raise_for_status()

        with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as temp_file:
            temp_file.write(response.content)
            audio_path = temp_file.name

        # Process audio
        result = process_audio(audio_path, tempo, time_signature)

        # Cleanup
        os.unlink(audio_path)

        return json.dumps(result, indent=2)

    except Exception as e:
        return json.dumps({'status': 'error', 'message': str(e)})

def extract_chords_from_file(audio_file, tempo: int = None, time_signature: str = "4/4"):
    """
    Process uploaded audio file directly.
    Returns JSON with chord data.
    """
    try:
        if audio_file is None:
            return json.dumps({'status': 'error', 'message': 'No file uploaded'})

        result = process_audio(audio_file, tempo, time_signature)
        return json.dumps(result, indent=2)

    except Exception as e:
        return json.dumps({'status': 'error', 'message': str(e)})

def process_audio(audio_path, tempo=None, time_signature='4/4'):
    """
    Process audio file and extract chords, tempo, beats.
    Returns structured data for Flutter app.
    """
    # Initialize chord extractor
    chordino = Chordino()

    # Extract chords
    chords = chordino.extract(audio_path)

    # Get audio duration and detect tempo if not provided
    y, sr = librosa.load(audio_path)
    duration = librosa.get_duration(y=y, sr=sr)

    if tempo is None:
        tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
        tempo = float(tempo)

    # Calculate bar/beat structure
    beats_per_bar = int(time_signature.split('/')[0])
    beat_duration = 60.0 / tempo
    bar_duration = beat_duration * beats_per_bar
    total_bars = int(duration / bar_duration) + 1

    # Map chords to bars/beats
    sheets = []
    for chord in chords:
        bar_number = int(chord.timestamp / bar_duration) + 1
        beat_in_bar = (chord.timestamp % bar_duration) / beat_duration
        beat_index = int(beat_in_bar)

        sheets.append({
            'barNumber': bar_number,
            'beatIndex': beat_index,
            'chord': chord.chord,
            'timestamp': chord.timestamp,
            'notes': ''
        })

    return {
        'status': 'success',
        'tempo': tempo,
        'timeSignature': time_signature,
        'totalBars': total_bars,
        'duration': duration,
        'sheets': sheets
    }

# Gradio Interface with API endpoint
with gr.Blocks() as demo:
    gr.Markdown("# 🎵 Chord Extraction Service")
    gr.Markdown("Extract chords from audio files for collaborative music score app.")

    with gr.Tab("From URL"):
        url_input = gr.Textbox(label="Audio URL (Firebase Storage public URL)")
        tempo_input_url = gr.Number(label="Tempo (BPM, optional)", value=None)
        time_sig_url = gr.Textbox(label="Time Signature", value="4/4")
        url_output = gr.Textbox(label="Result (JSON)", lines=20)
        url_btn = gr.Button("Extract Chords")
        url_btn.click(
            extract_chords_from_url,
            inputs=[url_input, tempo_input_url, time_sig_url],
            outputs=url_output
        )

    with gr.Tab("From File"):
        file_input = gr.Audio(type="filepath", label="Upload Audio File")
        tempo_input_file = gr.Number(label="Tempo (BPM, optional)", value=None)
        time_sig_file = gr.Textbox(label="Time Signature", value="4/4")
        file_output = gr.Textbox(label="Result (JSON)", lines=20)
        file_btn = gr.Button("Extract Chords")
        file_btn.click(
            extract_chords_from_file,
            inputs=[file_input, tempo_input_file, time_sig_file],
            outputs=file_output
        )

demo.launch()
```

#### **Hugging Face Spaces Deployment (FREE)**

```bash
# 1. Create HuggingFace account di https://huggingface.co (gratis)

# 2. Create new Space
# - Go to: https://huggingface.co/new-space
# - Space name: chord-extraction-service
# - SDK: Gradio
# - Hardware: CPU Basic (FREE)
# - Visibility: Public (REQUIRED for free tier)

# 3. Clone dan push code
git clone https://huggingface.co/spaces/YOUR_USERNAME/chord-extraction-service
cd chord-extraction-service
# Copy app.py, requirements.txt, README.md ke folder ini
git add .
git commit -m "Initial chord extraction service"
git push

# 4. Space otomatis build dan deploy
# URL: https://YOUR_USERNAME-chord-extraction-service.hf.space

# 5. API Endpoint (auto-generated by Gradio)
# POST: https://YOUR_USERNAME-chord-extraction-service.hf.space/api/predict
```

#### **Flutter Integration**

```dart
// lib/services/chord_extraction_service.dart

import 'package:dio/dio.dart';

class ChordExtractionService {
  final Dio _dio = Dio();

  // Replace with your HF Spaces URL
  static const String _baseUrl = 'https://YOUR_USERNAME-chord-extraction-service.hf.space';

  Future<Map<String, dynamic>> extractChords({
    required String audioUrl,
    int? tempo,
    String timeSignature = '4/4',
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/predict',
        data: {
          'data': [audioUrl, tempo, timeSignature],
          'fn_index': 0,  // Index of extract_chords_from_url function
        },
      );

      if (response.statusCode == 200) {
        final result = response.data['data'][0];
        return json.decode(result);
      }
      throw Exception('Failed to extract chords');
    } catch (e) {
      rethrow;
    }
  }
}
```

---

## **3\. SYNCHRONIZATION MECHANISM**

### **3.1 Server-Authoritative Clock Implementation**

// lib/core/sync/sync_service.dart

class SyncService {  
 final FirebaseDatabase \_rtdb \= FirebaseDatabase.instance;  
 final Ref \_ref;

// Server time offset from Firebase RTDB  
 int \_serverTimeOffset \= 0;

// Listen to server offset changes  
 void initializeSync() {  
 \_rtdb.ref('.info/serverTimeOffset').onValue.listen((event) {  
 \_serverTimeOffset \= (event.snapshot.value as int?) ?? 0;  
 });  
 }

// Get estimated server time  
 int getEstimatedServerTime() {  
 return DateTime.now().millisecondsSinceEpoch \+ \_serverTimeOffset;  
 }

// Leader starts playback  
 Future\<void\> startPlayback(String projectId, int bufferMs) async {  
 final serverTime \= getEstimatedServerTime();  
 final startTime \= serverTime \+ bufferMs; // 500-1000ms buffer

    await \_rtdb.ref('playback\_sessions/$projectId').update({
      'isPlaying': true,
      'serverStartTime': startTime,
      'lastSyncTime': serverTime,
      'leaderId': \_ref.read(authProvider).currentUser\!.uid,
    });

}

// Calculate current playback position  
 int getCurrentPositionMs(int serverStartTime) {  
 final currentServerTime \= getEstimatedServerTime();  
 return currentServerTime \- serverStartTime;  
 }

// Client-side interpolation for smooth visual  
 double interpolatePosition(  
 double localPosition,  
 double serverPosition,  
 double alpha, // 0.1 \- 0.3 typical  
 ) {  
 return localPosition \+ alpha \* (serverPosition \- localPosition);  
 }  
}

### **3.2 Scheduled Start Flow**

1\. Leader presses Play  
2\. All members press Ready  
3\. Leader triggers startPlayback()  
4\. Server calculates: serverStartTime \= currentServerTime \+ 800ms  
5\. All clients receive serverStartTime via RTDB listener  
6\. Each client calculates countdown:  
 countdown \= serverStartTime \- getEstimatedServerTime()  
7\. When countdown reaches 0, all clients start playback simultaneously  
8\. Position updates every frame using getCurrentPositionMs()  
9\. Interpolation smooths visual jitter

### **3.3 Resynchronization Strategy**

// Periodic resync every 3 minutes to prevent clock drift  
Timer.periodic(Duration(minutes: 3), (timer) {  
 if (isPlaying) {  
 // Smooth resync using interpolation  
 final serverPosition \= getCurrentPositionMs(serverStartTime);  
 final localPosition \= \_currentLocalPosition;

    // If drift \> 50ms, apply interpolation correction
    if ((serverPosition \- localPosition).abs() \> 50\) {
      \_applyInterpolationCorrection(serverPosition);
    }

}  
});

---

## **4\. UI/UX REQUIREMENTS**

### **4.1 Screen Structure**

1\. Auth Screen (Google Sign-In)
2\. Home Screen (Project list, Create new)
3\. Project Creation Screen (Name, default tempo/time sig only - no audio upload required)
4\. Score Canvas Screen
\- Page tabs at top (like Google Docs document tabs)
\- "+" button to add new page (manual/empty)
\- Upload audio button in toolbar → triggers background extraction
\- Edit mode (collaborative editing)
\- Playback mode (synchronized cursor)
5\. Play Mode Screen (can be triggered from canvas)
\- Select which page to play
\- Play Along mode: requires page with audioUrl
\- Play Together mode: any page, no audio needed
\- Ready/Not Ready indicators
\- Countdown before start
\- Synchronized metronome click
\- Bar/beat progress indicator

### **4.2 Audio Extraction Flow (Background Process)**

1\. User uploads audio file from canvas toolbar
2\. App creates new page with status "pending"
3\. Upload to Firebase Storage in background
4\. User sees "Extracting chords..." indicator on tab, can continue editing other pages
5\. When extraction completes:
\- Page status updates to "completed"
\- Bars data populated
\- Notification shown to user
6\. If extraction fails:
\- Page status updates to "failed"
\- User can retry or delete page

### **4.3 Key UI Components**

// Page Tabs Bar
\- Horizontal scrollable tabs at top of canvas
\- Each tab shows: title, extraction status indicator (if pending/processing)
\- Close button on each tab (leader only for delete)
\- "+" button at end to add new page

// Score Canvas Widget
\- Bar lines (vertical separators)
\- Beat subdivisions (4 beats per bar in 4/4)
\- Chord TextField (editable, LWW conflict resolution)
\- Playback cursor (animated, interpolated position)
\- Metronome visual (beat flash/highlight)

// Playback Controls (Leader only)
\- Play/Pause button
\- Seek bar (disabled during sync playback)
\- Tempo adjuster (updates page tempo)

// Participant Status (All users)
\- Ready checkbox (before playback start)
\- Sync status indicator (Syncing... / Ready / Playing)
\- Connection quality indicator (MAD display for testing)

---

## **5\. TESTING REQUIREMENTS**

### **5.1 Technical Testing \- MAD Calculation**

// lib/core/testing/mad_calculator.dart

class MADCalculator {  
 final FirebaseFirestore \_firestore \= FirebaseFirestore.instance;

// Log position every 500ms during playback  
 Timer? \_loggingTimer;

void startLogging(String projectId, String clientId) {  
 \_loggingTimer \= Timer.periodic(Duration(milliseconds: 500), (timer) {  
 final position \= \_syncService.getCurrentPositionMs(serverStartTime);  
 final serverOffset \= \_syncService.getEstimatedServerTime() \- DateTime.now().millisecondsSinceEpoch;

      \_firestore
        .collection('projects')
        .doc(projectId)
        .collection('logs')
        .add({
          'clientId': clientId,
          'timestamp': FieldValue.serverTimestamp(),
          'currentPositionMs': position,
          'serverTimeOffset': serverOffset,
          'eventType': 'playback\_sample',
          'metadata': {
            'localTime': DateTime.now().millisecondsSinceEpoch,
          }
        });
    });

}

void stopLogging() {  
 \_loggingTimer?.cancel();  
 }  
}

// Analysis will be done via separate admin dashboard  
// Fetch logs grouped by timestamp windows (500ms)  
// Calculate MAD per window: MAD \= Σ|position_i \- mean_position| / N

### **5.2 Test Scenarios**

Scenario 1: Same Room, WiFi, No Resync  
\- Duration: 5 minutes  
\- Clients: 2-3 Android devices  
\- Measure MAD at: 1min, 2min, 3min, 4min, 5min  
\- Goal: Identify clock drift rate

Scenario 2: Same Room, WiFi, With Resync  
\- Duration: 5 minutes  
\- Resync interval: 3 minutes  
\- Measure MAD before/after resync  
\- Goal: Validate resync effectiveness

Scenario 3: Different Networks (4G/5G)  
\- Duration: 5 minutes  
\- Clients on different mobile networks  
\- Measure MAD stability  
\- Goal: Test high-latency conditions

Scenario 4: Cross-Location (\>1km apart)  
\- Duration: 5 minutes  
\- Clients in different geographic areas  
\- Measure MAD and connection stability  
\- Goal: Worst-case scenario validation

### **5.3 User Testing Protocol**

Participants: 2-3 groups, 2-3 musicians per group

Session 1: With Ear Monitor \+ Metronome Click  
\- Play together for 3-5 minutes  
\- Record audio output  
\- Goal: Measure rhythmic consistency

Session 2: Without Ear Monitor  
\- Visual-only synchronization  
\- Play together for 3-5 minutes  
\- Goal: Test practical usage

Post-Session Questionnaire:  
1\. Perceived delay (1-5 Likert scale)  
2\. Comfort level during collaboration (1-5)  
3\. Visual sync quality (1-5)  
4\. Comparison with traditional rehearsal (better/same/worse)  
5\. Open feedback

---

## **6\. DEVELOPMENT WORKFLOW**

### **6.1 Project Structure**

```
collaborative_music_score/
├── android/
├── ios/
├── lib/
│   ├── core/
│   │   ├── sync/
│   │   │   ├── sync_service.dart
│   │   │   └── sync_models.dart
│   │   ├── testing/
│   │   │   └── mad_calculator.dart
│   │   └── constants.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── projects/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   ├── models/
│   │   │   └── widgets/
│   │   ├── score_canvas/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   ├── models/
│   │   │   └── widgets/
│   │   └── playback/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── shared/
│   │   ├── widgets/
│   │   └── utils/
│   └── main.dart
├── huggingface_spaces/
│   ├── app.py
│   ├── requirements.txt
│   └── README.md
└── admin_dashboard/ (separate simple web app for MAD analysis)
```

### **6.2 Development Phases (4 months)**

**Month 1 (Jan 12 - Feb 12): Foundation**

- Week 1-2: Firebase setup, auth implementation, basic UI scaffold
- Week 3-4: Firestore integration, project CRUD, basic score canvas

**Month 2 (Feb 13 - Mar 12): Core Features**

- Week 1-2: Collaborative editing (LWW), real-time updates
- Week 3-4: Hugging Face Spaces deployment, audio upload & extraction integration

**Month 3 (Mar 13 - Apr 12): Synchronization**

- Week 1-2: Server-authoritative clock implementation
- Week 3-4: Client-side interpolation, scheduled start, resync mechanism

**Month 4 (Apr 13 - May 12): Testing & Documentation**

- Week 1-2: Technical testing (MAD calculation), bug fixes
- Week 3: User testing with musicians
- Week 4: Thesis writing, final polish

---

## **7. CRITICAL CONSTRAINTS & WARNINGS**

### **7.1 Free Tier Limits (STAY VIGILANT)**

Firebase Firestore:

- 50k reads/day (1.5M/month)
- 20k writes/day (600k/month)
- 20k deletes/day (600k/month)
- 1 GiB storage
  ⚠️ Strategy: Minimize writes, use RTDB for high-frequency updates

Firebase Realtime Database:

- 100 simultaneous connections
- 10 GB/month data transfer
- 1 GB storage
  ⚠️ Strategy: Use only for playback_sessions (high-frequency, small payload)

Firebase Storage:

- 5 GB storage
- 1 GB/day downloads
- 20k upload operations/day
  ⚠️ Strategy: Delete audio after extraction, keep only metadata

Firebase Auth:

- Unlimited on free tier ✓

Hugging Face Spaces:

- CPU Basic: FREE (unlimited)
- Storage: 50GB (per Space)
- Timeout: ~5 minutes per request
  ⚠️ Limitation: Space MUST be public, cold start ~30-60s after idle
  ⚠️ Strategy: Accept cold start delay, keep Space active during testing sessions

### **7.2 iOS Deployment Without Apple Developer Account**

Option 1: TestFlight (Requires $99/year - NOT FREE)
Option 2: Direct Install (Free but limited)

- Enable Developer Mode on device
- Install via Xcode with free Apple ID
- Limitation: 7-day certificate, max 3 devices
- Re-sign weekly via Xcode

Recommendation for thesis: Focus on Android for main testing
iOS testing: Use your own device + 2 testers max with weekly re-signing

### **7.3 Known Risks**

Risk 1: Hugging Face Spaces cold start (first request after idle ~30-60s)
Mitigation: Keep browser tab open to Space during testing, or accept initial delay

Risk 2: Firestore quota exhaustion during testing
Mitigation: Implement rate limiting, batch writes, monitor usage daily

Risk 3: RTDB connection limits with many concurrent users
Mitigation: Thesis scope = same-room testing (2-3 clients), acceptable

Risk 4: Audio extraction accuracy
Mitigation: Out of scope for thesis (focus on sync, not MIR quality)

Risk 5: Network jitter > 100ms breaks interpolation
Mitigation: Document as limitation, recommend WiFi for optimal experience

---

## **8. AGENT CONTEXT SUMMARY**

When working with AntiGravity IDE agents, provide this context:

**You are building a Flutter mobile app (Android + iOS) for real-time collaborative music score synchronization. This is a thesis project with strict constraints:**

1. **Zero Budget:** All services must use free tiers (Firebase, Hugging Face Spaces)
2. **Timeline:** 4 months to completion (testing + thesis writing included)
3. **Tech Stack:** Flutter + Riverpod + Firebase (Firestore + RTDB) + Hugging Face Spaces (Python/Gradio)
4. **Core Innovation:** Server-authoritative clock + client-side interpolation for sub-30ms sync accuracy (MAD metric)

**Key Implementation Rules:**

- Firestore: Low-frequency data (projects, sheets, users)
- RTDB: High-frequency data (playback state, presence)
- Security rules: Production-ready from day 1
- LWW conflict resolution for collaborative editing
- Scheduled start mechanism for sync (server determines absolute start time)
- Periodic resync every 3 minutes to prevent clock drift
- Logging every 500ms for MAD calculation (stored in Firestore logs subcollection)

**Critical Files:**

- `lib/core/sync/sync_service.dart`: Contains all synchronization logic
- `lib/core/testing/mad_calculator.dart`: Handles test logging
- Firebase security rules (see PRD sections 2.2)
- Hugging Face Spaces `app.py`: Chord extraction service (Gradio)

**When generating code:**

1. Always use Riverpod providers for state management
2. Never hardcode Firebase config (use FlutterFire CLI or google-services.json)
3. Always handle offline scenarios (Firestore has offline persistence)
4. Use `FieldValue.serverTimestamp()` for consistent timestamps
5. Implement error boundaries and loading states for all async operations
6. Follow Material Design 3 principles for UI
7. Keep Hugging Face Spaces handler efficient (avoid >5min processing)

**Testing Requirements:**

- Log playback position every 500ms to Firestore
- Calculate MAD from logs (separate admin dashboard, not in main app)
- Test scenarios: Same room (WiFi), Different networks (4G), Cross-location (>1km)
- Target: MAD ≤ 30ms for 95% of samples

**Out of Scope:**

- Audio streaming between clients (only visual sync)
- Chord extraction accuracy improvements (use library as-is)
- Advanced CRDT conflict resolution (LWW is sufficient)
- Scalability beyond 10 concurrent users per project

---

## **9. FIREBASE & HUGGING FACE SETUP CHECKLIST**

Before coding, complete these steps:

```bash
# 1. Create Firebase project
# https://console.firebase.google.com → Create Project

# 2. Install FlutterFire CLI
dart pub global activate flutterfire_cli

# 3. Configure Flutter app
flutterfire configure

# 4. Enable services in Firebase Console:
# - Authentication → Google Sign-In
# - Firestore Database → Create database (Production mode, asia-southeast1)
# - Realtime Database → Create database (Locked mode, asia-southeast1)
# - Storage → Get started (Production mode)

# 5. Deploy security rules (copy from PRD sections 2.2)
firebase deploy --only firestore:rules
firebase deploy --only database:rules
firebase deploy --only storage:rules

# 6. Set up Hugging Face Space
# Go to https://huggingface.co/new-space
# - SDK: Gradio, Hardware: CPU Basic (FREE), Visibility: Public

# 7. Deploy chord extraction service
cd huggingface_spaces/
git clone https://huggingface.co/spaces/YOUR_USERNAME/chord-extraction-service
# Copy app.py, requirements.txt, README.md
git add . && git commit -m "Deploy" && git push

# Save the Space URL for Flutter integration
# URL: https://YOUR_USERNAME-chord-extraction-service.hf.space
```

---

## **10. FIRST SPRINT TASKS (Week 1-2)**

Priority 1: Authentication

- [ ] Set up Firebase project
- [ ] Implement Google Sign-In flow
- [ ] Create user profile screen
- [ ] Test on Android device

Priority 2: Basic Navigation

- [ ] Set up Riverpod state management
- [ ] Create Home screen with project list
- [ ] Implement Create Project flow
- [ ] Add navigation routing

Priority 3: Firestore Integration

- [ ] Define Firestore models with Freezed
- [ ] Implement CRUD operations for projects
- [ ] Test data persistence
- [ ] Implement offline support

Priority 4: UI Scaffold

- [ ] Design score canvas layout (bars, beats)
- [ ] Create chord input TextField
- [ ] Implement bar navigation
- [ ] Add tempo/time signature controls

Deliverable: Working app with auth + basic project management (no sync yet)

---

**END OF PRD**

**This document is the single source of truth for the thesis implementation. All code generation, architectural decisions, and debugging should refer back to these specifications. Update this PRD if scope changes are approved.**
