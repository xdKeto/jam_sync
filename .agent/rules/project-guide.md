---
trigger: always_on
---

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