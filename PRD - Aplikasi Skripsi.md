## **PRD: Collaborative Music Score App with Real-Time Synchronization**

**Project:** Thesis \- Server-Authoritative Clock \+ Client-Side Interpolation for Real-Time Music Collaboration **Student:** Yestoya Lumenchristo Minggus (C14220331) **Institution:** Universitas Kristen Petra, Informatika **Timeline:** 4 months (Jan 12 \- May 12, 2026\) **Budget:** Zero (Free tier only, no credit card)

---

## **1\. SYSTEM OVERVIEW**

### **1.1 Core Problem**

Musicians using individual devices for digital scores lack synchronized visual playback, causing coordination issues during rehearsals. Target: MAD ≤30ms between clients.

### **1.2 Solution Architecture**

* **Frontend:** Flutter (Android \+ iOS, min SDK 24\)  
* **Backend:** Firebase (Firestore \+ Realtime Database)  
* **Audio Processing:** Python container on Cloud Run  
* **Auth:** Google Sign-In  
* **Storage:** Firebase Storage (for audio files)

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
\- flutter\_riverpod: ^2.5.0  
\- riverpod\_annotation: ^2.3.0  
\- riverpod\_generator: ^2.4.0

\# Firebase  
\- firebase\_core: ^3.0.0  
\- firebase\_auth: ^5.0.0  
\- cloud\_firestore: ^5.0.0  
\- firebase\_database: ^11.0.0  
\- firebase\_storage: ^12.0.0  
\- google\_sign\_in: ^6.2.0

\# Audio  
\- just\_audio: ^0.9.0 (for playback)  
\- file\_picker: ^8.0.0 (for audio upload)

\# HTTP  
\- dio: ^5.0.0 (for Cloud Run API calls)  
\- http: ^1.2.0

\# Utilities  
\- freezed: ^2.5.0 (immutable models)  
\- freezed\_annotation: ^2.4.0  
\- json\_annotation: ^4.9.0  
\- json\_serializable: ^6.8.0  
\- uuid: ^4.0.0  
\- intl: ^0.19.0

\# Dev Dependencies  
\- build\_runner: ^2.4.0  
\- riverpod\_lint: ^2.3.0

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
   \- Storage → Production mode  
     
3\. Add Android app:  
   \- Package name: com.petra.collaborative\_score (or your choice)  
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
  \- tempo: number (BPM)  
  \- timeSignature: string (e.g., "4/4")  
  \- totalBars: number  
  \- audioUrl: string? (optional, for Play Along mode)  
  \- audioFileName: string?  
  \- extractionStatus: string ("pending" | "processing" | "completed" | "failed")  
  \- mode: string ("play\_along" | "play\_together")  
  \- leaderId: userId  
    
  /sheets/{sheetId} \[subcollection\]  
    \- barNumber: number  
    \- beatIndex: number  
    \- chord: string  
    \- notes: string?  
    \- updatedAt: timestamp  
    \- updatedBy: userId  
    
  /participants/{userId} \[subcollection\]  
    \- role: string ("leader" | "member")  
    \- displayName: string  
    \- isReady: boolean  
    \- joinedAt: timestamp  
    
  /logs/{logId} \[subcollection\]  
    \- clientId: string  
    \- timestamp: number (milliseconds)  
    \- currentPositionMs: number  
    \- serverTimeOffset: number  
    \- eventType: string ("playback\_sample" | "sync\_event")  
    \- metadata: map

#### **Realtime Database Structure**

{  
  "playback\_sessions": {  
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

rules\_version \= '2';  
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
        
      match /sheets/{sheetId} {  
        allow read: if isAuthenticated() && isProjectParticipant(projectId);  
        allow write: if isAuthenticated() && isProjectParticipant(projectId);  
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
    "playback\_sessions": {  
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

#### **Security Rules \- Storage**

rules\_version \= '2';  
service firebase.storage {  
  match /b/{bucket}/o {  
    match /audio\_uploads/{userId}/{fileName} {  
      allow read: if request.auth \!= null;  
      allow write: if request.auth \!= null   
                   && request.auth.uid \== userId  
                   && request.resource.size \< 50 \* 1024 \* 1024  // 50MB max  
                   && request.resource.contentType.matches('audio/.\*');  
    }  
  }  
}

### **2.3 Cloud Run \- Chord Extraction Service**

#### **Dockerfile**

FROM python:3.11-slim

WORKDIR /app

\# Install system dependencies for audio processing  
RUN apt-get update && apt-get install \-y \\  
    libsndfile1 \\  
    ffmpeg \\  
    && rm \-rf /var/lib/apt/lists/\*

COPY requirements.txt .  
RUN pip install \--no-cache-dir \-r requirements.txt

COPY . .

\# Cloud Run will set PORT env variable  
ENV PORT=8080

CMD exec gunicorn \--bind :$PORT \--workers 1 \--threads 8 \--timeout 300 main:app

#### **requirements.txt (Python Service)**

chord-extractor==1.1.0  
yt-dlp==2024.8.6  
librosa==0.10.1  
vamp==1.1.0  
flask==3.0.0  
gunicorn==21.2.0  
firebase-admin==6.5.0  
google-cloud-storage==2.16.0

#### **main.py Structure**

from flask import Flask, request, jsonify  
import firebase\_admin  
from firebase\_admin import credentials, firestore, storage  
import tempfile  
import os  
import json  
from chord\_extractor import extract\_chords  
import librosa

app \= Flask(\_\_name\_\_)

\# Initialize Firebase Admin  
cred \= credentials.ApplicationDefault()  
firebase\_admin.initialize\_app(cred, {  
    'storageBucket': 'YOUR\_PROJECT\_ID.appspot.com'  
})

db \= firestore.client()  
bucket \= storage.bucket()

@app.route('/extract-chords', methods=\['POST'\])  
def extract\_chords\_endpoint():  
    """  
    Expected payload:  
    {  
      "projectId": "string",  
      "audioUrl": "gs://bucket/path/to/file.mp3",  
      "tempo": 120 (optional),  
      "timeSignature": "4/4" (optional)  
    }  
    """  
    try:  
        data \= request.json  
        project\_id \= data\['projectId'\]  
        audio\_url \= data\['audioUrl'\]  
          
        \# Update status to processing  
        db.collection('projects').document(project\_id).update({  
            'extractionStatus': 'processing'  
        })  
          
        \# Download audio from Firebase Storage  
        blob \= bucket.blob(audio\_url.replace('gs://{}/'.format(bucket.name), ''))  
          
        with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as temp\_file:  
            blob.download\_to\_filename(temp\_file.name)  
            audio\_path \= temp\_file.name  
          
        \# Process audio  
        result \= process\_audio(  
            audio\_path,  
            tempo=data.get('tempo'),  
            time\_signature=data.get('timeSignature', '4/4')  
        )  
          
        \# Save to Firestore sheets subcollection  
        sheets\_ref \= db.collection('projects').document(project\_id).collection('sheets')  
        batch \= db.batch()  
          
        for sheet\_data in result\['sheets'\]:  
            doc\_ref \= sheets\_ref.document()  
            batch.set(doc\_ref, sheet\_data)  
          
        batch.commit()  
          
        \# Update project metadata  
        db.collection('projects').document(project\_id).update({  
            'extractionStatus': 'completed',  
            'tempo': result\['tempo'\],  
            'timeSignature': result\['timeSignature'\],  
            'totalBars': result\['totalBars'\]  
        })  
          
        \# Cleanup  
        os.unlink(audio\_path)  
          
        return jsonify({'status': 'success', 'result': result}), 200  
          
    except Exception as e:  
        db.collection('projects').document(project\_id).update({  
            'extractionStatus': 'failed'  
        })  
        return jsonify({'status': 'error', 'message': str(e)}), 500

def process\_audio(audio\_path, tempo=None, time\_signature='4/4'):  
    """  
    Process audio file and extract chords, tempo, beats  
    Returns structured data for Firestore  
    """  
    \# Your existing Python chord extraction logic here  
    \# Return format:  
    return {  
        'tempo': 120,  
        'timeSignature': '4/4',  
        'totalBars': 32,  
        'sheets': \[  
            {  
                'barNumber': 1,  
                'beatIndex': 0,  
                'chord': 'Cmaj7',  
                'notes': '',  
                'updatedAt': firestore.SERVER\_TIMESTAMP,  
                'updatedBy': 'system'  
            }  
            \# ... more sheets  
        \]  
    }

if \_\_name\_\_ \== '\_\_main\_\_':  
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))

#### **Cloud Run Deployment (FREE TIER)**

\# 1\. Enable APIs (no billing required for deployment setup)  
gcloud services enable run.googleapis.com  
gcloud services enable containerregistry.googleapis.com

\# 2\. Set project  
gcloud config set project YOUR\_PROJECT\_ID

\# 3\. Build and deploy (stays in free tier: 2M requests/month, 360k GB-seconds)  
gcloud run deploy chord-extraction-service \\  
  \--source . \\  
  \--platform managed \\  
  \--region asia-southeast1 \\  
  \--allow-unauthenticated \\  
  \--memory 2Gi \\  
  \--timeout 300s \\  
  \--max-instances 1 \\  
  \--cpu 1 \\  
  \--concurrency 1  
    
\# Note: Keep max-instances=1 to stay in free tier  
\# Free tier: 180k vCPU-seconds, 360k GiB-seconds per month

---

## **3\. SYNCHRONIZATION MECHANISM**

### **3.1 Server-Authoritative Clock Implementation**

// lib/core/sync/sync\_service.dart

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
3\. Project Settings Screen (Upload audio, set tempo/time sig)  
4\. Extraction Loading Screen (Progress indicator)  
5\. Score Canvas Screen  
   \- Edit mode (collaborative editing)  
   \- Playback mode (synchronized cursor)  
6\. Play Together Screen  
   \- Ready/Not Ready indicators  
   \- Countdown before start  
   \- Synchronized metronome click  
   \- Bar/beat progress indicator

### **4.2 Key UI Components**

// Score Canvas Widget  
\- Bar lines (vertical separators)  
\- Beat subdivisions (4 beats per bar in 4/4)  
\- Chord TextField (editable, LWW conflict resolution)  
\- Playback cursor (animated, interpolated position)  
\- Metronome visual (beat flash/highlight)

// Playback Controls (Leader only)  
\- Play/Pause button  
\- Seek bar (disabled during sync playback)  
\- Tempo adjuster (updates global state)

// Participant Status (All users)  
\- Ready checkbox (before playback start)  
\- Sync status indicator (Syncing... / Ready / Playing)  
\- Connection quality indicator (MAD display for testing)

---

## **5\. TESTING REQUIREMENTS**

### **5.1 Technical Testing \- MAD Calculation**

// lib/core/testing/mad\_calculator.dart

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
// Calculate MAD per window: MAD \= Σ|position\_i \- mean\_position| / N

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

collaborative\_music\_score/  
├── android/  
├── ios/  
├── lib/  
│   ├── core/  
│   │   ├── sync/  
│   │   │   ├── sync\_service.dart  
│   │   │   └── sync\_models.dart  
│   │   ├── testing/  
│   │   │   └── mad\_calculator.dart  
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
│   │   ├── score\_canvas/  
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
├── chord\_extraction\_service/  
│   ├── main.py  
│   ├── requirements.txt  
│   ├── Dockerfile  
│   └── .gcloudignore  
└── admin\_dashboard/ (separate simple web app for MAD analysis)

### **6.2 Development Phases (4 months)**

**Month 1 (Jan 12 \- Feb 12): Foundation**

* Week 1-2: Firebase setup, auth implementation, basic UI scaffold  
* Week 3-4: Firestore integration, project CRUD, basic score canvas

**Month 2 (Feb 13 \- Mar 12): Core Features**

* Week 1-2: Collaborative editing (LWW), real-time updates  
* Week 3-4: Cloud Run deployment, audio upload & extraction integration

**Month 3 (Mar 13 \- Apr 12): Synchronization**

* Week 1-2: Server-authoritative clock implementation  
* Week 3-4: Client-side interpolation, scheduled start, resync mechanism

**Month 4 (Apr 13 \- May 12): Testing & Documentation**

* Week 1-2: Technical testing (MAD calculation), bug fixes  
* Week 3: User testing with musicians  
* Week 4: Thesis writing, final polish

---

## **7\. CRITICAL CONSTRAINTS & WARNINGS**

### **7.1 Free Tier Limits (STAY VIGILANT)**

Firebase Firestore:  
\- 50k reads/day (1.5M/month)  
\- 20k writes/day (600k/month)  
\- 20k deletes/day (600k/month)  
\- 1 GiB storage  
⚠️ Strategy: Minimize writes, use RTDB for high-frequency updates

Firebase Realtime Database:  
\- 100 simultaneous connections  
\- 10 GB/month data transfer  
\- 1 GB storage  
⚠️ Strategy: Use only for playback\_sessions (high-frequency, small payload)

Firebase Storage:  
\- 5 GB storage  
\- 1 GB/day downloads  
\- 20k upload operations/day  
⚠️ Strategy: Delete audio after extraction, keep only metadata

Firebase Auth:  
\- Unlimited on free tier ✓

Cloud Run:  
\- 2M requests/month  
\- 360k GB-seconds compute time  
\- 180k vCPU-seconds  
⚠️ Strategy: Keep max-instances=1, optimize extraction speed

### **7.2 iOS Deployment Without Apple Developer Account**

Option 1: TestFlight (Requires $99/year \- NOT FREE)  
Option 2: Direct Install (Free but limited)  
  \- Enable Developer Mode on device  
  \- Install via Xcode with free Apple ID  
  \- Limitation: 7-day certificate, max 3 devices  
  \- Re-sign weekly via Xcode  
    
Recommendation for thesis: Focus on Android for main testing  
iOS testing: Use your own device \+ 2 testers max with weekly re-signing

### **7.3 Known Risks**

Risk 1: Cloud Run cold start (first request after idle \= slow)  
Mitigation: Keep service warm with scheduled ping, or accept 5-10s first-time delay

Risk 2: Firestore quota exhaustion during testing  
Mitigation: Implement rate limiting, batch writes, monitor usage daily

Risk 3: RTDB connection limits with many concurrent users  
Mitigation: Thesis scope \= same-room testing (2-3 clients), acceptable

Risk 4: Audio extraction accuracy  
Mitigation: Out of scope for thesis (focus on sync, not MIR quality)

Risk 5: Network jitter \> 100ms breaks interpolation  
Mitigation: Document as limitation, recommend WiFi for optimal experience

---

## **8\. AGENT CONTEXT SUMMARY**

When working with AntiGravity IDE agents, provide this context:

**You are building a Flutter mobile app (Android \+ iOS) for real-time collaborative music score synchronization. This is a thesis project with strict constraints:**

1. **Zero Budget:** All services must use free tiers (Firebase, Cloud Run)  
2. **Timeline:** 4 months to completion (testing \+ thesis writing included)  
3. **Tech Stack:** Flutter \+ Riverpod \+ Firebase (Firestore \+ RTDB) \+ Cloud Run (Python)  
4. **Core Innovation:** Server-authoritative clock \+ client-side interpolation for sub-30ms sync accuracy (MAD metric)

**Key Implementation Rules:**

* Firestore: Low-frequency data (projects, sheets, users)  
* RTDB: High-frequency data (playback state, presence)  
* Security rules: Production-ready from day 1  
* LWW conflict resolution for collaborative editing  
* Scheduled start mechanism for sync (server determines absolute start time)  
* Periodic resync every 3 minutes to prevent clock drift  
* Logging every 500ms for MAD calculation (stored in Firestore logs subcollection)

**Critical Files:**

* `lib/core/sync/sync_service.dart`: Contains all synchronization logic  
* `lib/core/testing/mad_calculator.dart`: Handles test logging  
* Firebase security rules (see PRD sections 2.2)  
* Cloud Run `main.py`: Chord extraction service

**When generating code:**

1. Always use Riverpod providers for state management  
2. Never hardcode Firebase config (use FlutterFire CLI or google-services.json)  
3. Always handle offline scenarios (Firestore has offline persistence)  
4. Use `FieldValue.serverTimestamp()` for consistent timestamps  
5. Implement error boundaries and loading states for all async operations  
6. Follow Material Design 3 principles for UI  
7. Keep Cloud Run handler under 300s timeout (optimize extraction speed)

**Testing Requirements:**

* Log playback position every 500ms to Firestore  
* Calculate MAD from logs (separate admin dashboard, not in main app)  
* Test scenarios: Same room (WiFi), Different networks (4G), Cross-location (\>1km)  
* Target: MAD ≤ 30ms for 95% of samples

**Out of Scope:**

* Audio streaming between clients (only visual sync)  
* Chord extraction accuracy improvements (use library as-is)  
* Advanced CRDT conflict resolution (LWW is sufficient)  
* Scalability beyond 10 concurrent users per project

---

## **9\. FIREBASE SETUP CHECKLIST**

Before coding, complete these steps:

\# 1\. Create Firebase project  
https://console.firebase.google.com → Create Project

\# 2\. Install FlutterFire CLI  
dart pub global activate flutterfire\_cli

\# 3\. Configure Flutter app  
flutterfire configure

\# 4\. Enable services in Firebase Console:  
\- Authentication → Google Sign-In  
\- Firestore Database → Create database (Production mode, asia-southeast1)  
\- Realtime Database → Create database (Locked mode, asia-southeast1)  
\- Storage → Get started (Production mode)

\# 5\. Deploy security rules (copy from PRD sections 2.2)  
firebase deploy \--only firestore:rules  
firebase deploy \--only database:rules  
firebase deploy \--only storage:rules

\# 6\. Set up Cloud Run project  
gcloud config set project YOUR\_PROJECT\_ID  
gcloud services enable run.googleapis.com

\# 7\. Deploy chord extraction service  
cd chord\_extraction\_service/  
gcloud run deploy chord-extraction-service \\  
  \--source . \\  
  \--region asia-southeast1 \\  
  \--allow-unauthenticated \\  
  \--memory 2Gi \\  
  \--timeout 300s \\  
  \--max-instances 1

\# Save the service URL for Flutter integration

---

## **10\. FIRST SPRINT TASKS (Week 1-2)**

Priority 1: Authentication  
\[ \] Set up Firebase project  
\[ \] Implement Google Sign-In flow  
\[ \] Create user profile screen  
\[ \] Test on Android device

Priority 2: Basic Navigation  
\[ \] Set up Riverpod state management  
\[ \] Create Home screen with project list  
\[ \] Implement Create Project flow  
\[ \] Add navigation routing

Priority 3: Firestore Integration  
\[ \] Define Firestore models with Freezed  
\[ \] Implement CRUD operations for projects  
\[ \] Test data persistence  
\[ \] Implement offline support

Priority 4: UI Scaffold  
\[ \] Design score canvas layout (bars, beats)  
\[ \] Create chord input TextField  
\[ \] Implement bar navigation  
\[ \] Add tempo/time signature controls

Deliverable: Working app with auth \+ basic project management (no sync yet)

---

**END OF PRD**

**This document is the single source of truth for the thesis implementation. All code generation, architectural decisions, and debugging should refer back to these specifications. Update this PRD if scope changes are approved.**

