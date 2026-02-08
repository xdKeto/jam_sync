# Proof of Concept: Real-Time Synchronization Guide

## Overview

Tujuan: Membuktikan bahwa strategi **server-authoritative clock + client-side interpolation** bekerja untuk sinkronisasi playback antar device dengan MAD ≤30ms.

**Hardcoded Settings:**

- Time Signature: 4/4
- Tempo: 110 BPM
- Beat duration: 60000ms / 110 = **545.45ms per beat**
- Bar duration: 545.45ms × 4 = **2181.82ms per bar**
- Countdown buffer: **5 detik** (5000ms)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Firebase RTDB                           │
│  /playback_sessions/{roomId}                                │
│    ├── isPlaying: boolean                                   │
│    ├── serverStartTime: number (epoch ms)                   │
│    ├── leaderId: string                                     │
│    └── roomCode: string                                     │
│                                                             │
│  /rooms/{roomCode}                                          │
│    └── roomId: string (maps code → roomId)                  │
└─────────────────────────────────────────────────────────────┘
           │
           │ Real-time listeners
           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Clients                          │
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Leader    │    │   Member    │    │   Member    │     │
│  │  (Device A) │    │  (Device B) │    │  (Device C) │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│        │                  │                  │              │
│        └──────────────────┴──────────────────┘              │
│                           │                                 │
│              Local playback calculation:                    │
│         currentPosition = serverTime - serverStartTime      │
└─────────────────────────────────────────────────────────────┘
           │
           │ Logs setiap 500ms
           ▼
┌─────────────────────────────────────────────────────────────┐
│                     Firestore                               │
│  /poc_sessions/{sessionId}/logs/{logId}                     │
│    ├── clientId: string                                     │
│    ├── timestamp: serverTimestamp                           │
│    ├── currentPositionMs: number                            │
│    ├── currentBoxIndex: number                              │
│    └── localTimeMs: number                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Feature 1: Room System

### 1.1 Data Model (RTDB)

```
/rooms/{roomCode}
  └── roomId: string

/playback_sessions/{roomId}
  ├── roomCode: string
  ├── leaderId: string
  ├── isPlaying: boolean
  ├── serverStartTime: number (0 jika belum mulai)
  ├── createdAt: number
  └── participants/
      └── {userId}: true
```

### 1.2 Create Room Flow

```
1. Generate 6-digit random code (pastikan unique)
2. Generate roomId menggunakan uuid
3. Write ke RTDB:
   - /rooms/{code} → { roomId: roomId }
   - /playback_sessions/{roomId} → {
       roomCode: code,
       leaderId: currentUserId,
       isPlaying: false,
       serverStartTime: 0,
       createdAt: ServerValue.timestamp
     }
4. Add self ke participants:
   - /playback_sessions/{roomId}/participants/{userId} → true
5. Navigate ke Room Screen
```

### 1.3 Join Room Flow

```
1. User input 6-digit code
2. Read /rooms/{code} untuk dapat roomId
3. Jika tidak exist → show error "Room tidak ditemukan"
4. Jika exist:
   - Add self ke /playback_sessions/{roomId}/participants/{userId}
   - Navigate ke Room Screen
5. Listen ke /playback_sessions/{roomId} untuk real-time updates
```

### 1.4 Code Generation (Helper)

```dart
String generateRoomCode() {
  final random = Random();
  return List.generate(6, (_) => random.nextInt(10)).join();
}
```

---

## Feature 2: Server Time Synchronization

### 2.1 Core Concept

Firebase RTDB menyediakan `/.info/serverTimeOffset` yang berisi selisih antara server time dan local time dalam milliseconds.

```
estimatedServerTime = DateTime.now().millisecondsSinceEpoch + serverTimeOffset
```

### 2.2 Implementation

```dart
class SyncService {
  final DatabaseReference _rtdb = FirebaseDatabase.instance.ref();
  int _serverTimeOffset = 0;

  // Call this di initState atau saat app start
  void initializeServerTimeSync() {
    _rtdb.child('.info/serverTimeOffset').onValue.listen((event) {
      _serverTimeOffset = (event.snapshot.value as int?) ?? 0;
    });
  }

  int getEstimatedServerTime() {
    return DateTime.now().millisecondsSinceEpoch + _serverTimeOffset;
  }
}
```

### 2.3 Accuracy Notes

- Typical offset accuracy: 10-50ms dalam kondisi normal
- Akan ada jitter karena network latency
- Ini acceptable untuk target MAD ≤30ms

---

## Feature 3: Scheduled Start dengan Countdown

### 3.1 Flow Diagram

```
Leader presses START
        │
        ▼
Calculate scheduledStartTime:
  = getEstimatedServerTime() + 5000ms (buffer)
        │
        ▼
Write ke RTDB:
  /playback_sessions/{roomId}/serverStartTime = scheduledStartTime
  /playback_sessions/{roomId}/isPlaying = true
        │
        ▼
All clients receive update via listener
        │
        ▼
Each client calculates countdown:
  countdown = serverStartTime - getEstimatedServerTime()
        │
        ▼
Show countdown UI (5... 4... 3... 2... 1...)
        │
        ▼
When countdown <= 0:
  Start autonomous playback
```

### 3.2 Leader: Start Playback

```dart
Future<void> startPlayback(String roomId) async {
  final scheduledStartTime = getEstimatedServerTime() + 5000; // 5 detik buffer

  await _rtdb.child('playback_sessions/$roomId').update({
    'isPlaying': true,
    'serverStartTime': scheduledStartTime,
  });
}
```

### 3.3 All Clients: Listen & Countdown

```dart
// Di Room Screen initState
_rtdb.child('playback_sessions/$roomId').onValue.listen((event) {
  final data = event.snapshot.value as Map<dynamic, dynamic>?;
  if (data == null) return;

  final isPlaying = data['isPlaying'] as bool? ?? false;
  final serverStartTime = data['serverStartTime'] as int? ?? 0;

  if (isPlaying && serverStartTime > 0) {
    _startCountdownAndPlayback(serverStartTime);
  }
});

void _startCountdownAndPlayback(int serverStartTime) {
  // Cancel any existing timer
  _countdownTimer?.cancel();

  _countdownTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
    final now = getEstimatedServerTime();
    final remaining = serverStartTime - now;

    if (remaining <= 0) {
      timer.cancel();
      _startAutonomousPlayback(serverStartTime);
    } else {
      // Update countdown UI
      setState(() {
        _countdownSeconds = (remaining / 1000).ceil();
      });
    }
  });
}
```

---

## Feature 4: Autonomous Playback

### 4.1 Core Concept

Setelah countdown selesai, setiap client menghitung posisi playback secara **autonomous** berdasarkan waktu server.

```
currentPositionMs = getEstimatedServerTime() - serverStartTime
```

Tidak ada polling atau streaming posisi dari server. Semua client menghitung sendiri.

### 4.2 Dummy UI: Kotak Berjejer

**Visual:**

```
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │...│...│...│...│...│...│16 │
└───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
      ▲
      │
   Cursor (kotak hijau/highlight)
```

**Settings:**

- Total kotak: 16 (4 bars × 4 beats)
- Durasi per kotak: 545.45ms (1 beat at 110 BPM)
- Total durasi: ~8.7 detik

### 4.3 Position Calculation

```dart
class PlaybackController {
  int serverStartTime = 0;
  bool isPlaying = false;
  Timer? _playbackTimer;

  void startAutonomousPlayback(int startTime) {
    serverStartTime = startTime;
    isPlaying = true;

    // Update UI setiap 16ms (~60fps)
    _playbackTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!isPlaying) {
        timer.cancel();
        return;
      }

      final currentPositionMs = getEstimatedServerTime() - serverStartTime;
      final currentBoxIndex = _calculateBoxIndex(currentPositionMs);

      // Update UI
      setState(() {
        _currentBox = currentBoxIndex;
      });

      // Stop jika sudah selesai
      if (currentBoxIndex >= 16) {
        stopPlayback();
      }
    });
  }

  int _calculateBoxIndex(int positionMs) {
    const beatDurationMs = 545.45; // 60000 / 110 BPM
    return (positionMs / beatDurationMs).floor();
  }
}
```

### 4.4 UI Widget

```dart
Widget _buildBoxGrid() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(16, (index) {
      final isActive = index == _currentBox;
      final isPassed = index < _currentBox;

      return Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isActive
            ? Colors.green
            : isPassed
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.shade300,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text('${index + 1}'),
        ),
      );
    }),
  );
}
```

---

## Feature 5: Client-Side Interpolation

### 5.1 Purpose

Interpolation digunakan untuk **smoothing** jika ada jitter atau drift antara calculated position dan actual position.

### 5.2 Basic Interpolation Formula

```
smoothedPosition = previousPosition + alpha × (targetPosition - previousPosition)
```

Dimana `alpha` antara 0.1 - 0.3 (semakin kecil = lebih smooth tapi lebih lambat catch up).

### 5.3 Implementation

```dart
class InterpolatedPlayback {
  double _smoothedPositionMs = 0;
  final double alpha = 0.15; // Tuning parameter

  void updatePosition() {
    // Calculated position from server time
    final targetPositionMs = (getEstimatedServerTime() - serverStartTime).toDouble();

    // Apply interpolation
    _smoothedPositionMs = _smoothedPositionMs + alpha * (targetPositionMs - _smoothedPositionMs);

    // Use smoothed position for UI
    final currentBoxIndex = (_smoothedPositionMs / 545.45).floor();
  }
}
```

### 5.4 When to Use

- Selalu gunakan untuk visual cursor movement
- Interpolation membuat pergerakan cursor lebih smooth
- Jangan pakai untuk logging (log actual calculated position)

---

## Feature 6: Resynchronization

### 6.1 Purpose

Setelah beberapa menit, clock drift bisa accumulate. Resync memastikan semua client tetap aligned.

### 6.2 Periodic Resync - 3 Menit (PRD Strategy - Primary)

> [!IMPORTANT]
> Ini strategi utama dari proposal: setiap 3 menit, **regardless** seberapa besar drift-nya, kita lakukan "reset" sinkronisasi.

**Konsep:**

- Setiap 3 menit autonomous playback, leader trigger resync
- Semua client menerima `newServerStartTime` baru
- Client recalculate posisi berdasarkan start time baru
- Ini seperti "scheduled start" mini tanpa countdown

**Flow:**

```
3 menit berlalu
       │
       ▼
Leader calculates:
  currentPosition = getEstimatedServerTime() - serverStartTime
  newServerStartTime = getEstimatedServerTime() - currentPosition
       │
       ▼
Write ke RTDB:
  /playback_sessions/{roomId}/serverStartTime = newServerStartTime
  /playback_sessions/{roomId}/resyncCount += 1
       │
       ▼
All clients receive update via listener
       │
       ▼
Each client recalculates position from new serverStartTime
```

**Implementation:**

```dart
class PeriodicResync {
  Timer? _resyncTimer;
  int _resyncCount = 0;

  void startPeriodicResync(String roomId, bool isLeader) {
    if (!isLeader) return; // Hanya leader yang trigger

    _resyncTimer = Timer.periodic(Duration(minutes: 3), (timer) {
      if (!isPlaying) return;

      _triggerResync(roomId);
    });
  }

  Future<void> _triggerResync(String roomId) async {
    // Hitung posisi saat ini
    final currentPosition = getEstimatedServerTime() - serverStartTime;

    // Hitung start time baru yang akan menghasilkan posisi yang sama
    final newServerStartTime = getEstimatedServerTime() - currentPosition;

    _resyncCount++;

    await _rtdb.child('playback_sessions/$roomId').update({
      'serverStartTime': newServerStartTime,
      'resyncCount': _resyncCount,
      'lastResyncTime': ServerValue.timestamp,
    });

    print('Periodic resync #$_resyncCount triggered');
  }
}

// All clients listen
_rtdb.child('playback_sessions/$roomId').onValue.listen((event) {
  final data = event.snapshot.value as Map<dynamic, dynamic>?;
  if (data == null) return;

  final newResyncCount = data['resyncCount'] as int? ?? 0;

  if (newResyncCount > _localResyncCount) {
    // Resync event received
    _localResyncCount = newResyncCount;
    serverStartTime = data['serverStartTime'] as int;

    // Force update smoothed position
    _smoothedPositionMs = (getEstimatedServerTime() - serverStartTime).toDouble();

    print('Resync applied from leader, count: $newResyncCount');
  }
});
```

### 6.3 Drift Check - 30 Detik (Complementary)

Sebagai tambahan dari periodic resync, kita juga check drift setiap 30 detik untuk menangani kasus jitter yang lebih sering:

```dart
// Setiap 30 detik, check drift (berjalan di semua client)
Timer.periodic(Duration(seconds: 30), (timer) {
  if (!isPlaying) return;

  final calculatedPosition = getEstimatedServerTime() - serverStartTime;
  final smoothedPosition = _smoothedPositionMs;
  final drift = (calculatedPosition - smoothedPosition).abs();

  // Jika drift > 100ms, force local resync
  if (drift > 100) {
    _smoothedPositionMs = calculatedPosition.toDouble();
    print('Local drift correction applied, drift was: ${drift}ms');
  }
});
```

> [!NOTE]
> Drift check 30 detik adalah **local correction** di masing-masing client.
> Periodic resync 3 menit adalah **global reset** dari leader ke semua client.

### 6.4 Combined Resync Strategy

```dart
class ResyncManager {
  Timer? _driftCheckTimer;
  Timer? _periodicResyncTimer;

  void initialize(String roomId, bool isLeader) {
    // Semua client: drift check setiap 30 detik
    _driftCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkAndCorrectDrift();
    });

    // Leader only: periodic resync setiap 3 menit
    if (isLeader) {
      _periodicResyncTimer = Timer.periodic(Duration(minutes: 3), (timer) {
        _triggerGlobalResync(roomId);
      });
    }
  }

  void dispose() {
    _driftCheckTimer?.cancel();
    _periodicResyncTimer?.cancel();
  }
}
```

---

## Feature 7: MAD Logging

### 7.1 Data Model (Firestore)

```
/poc_sessions/{sessionId}
  ├── roomId: string
  ├── startedAt: timestamp
  ├── endedAt: timestamp?
  └── logs/ (subcollection)
      └── {logId}
          ├── clientId: string
          ├── timestamp: timestamp (server)
          ├── localTimeMs: number
          ├── currentPositionMs: number
          ├── currentBoxIndex: number
          └── serverTimeOffset: number
```

### 7.2 Create Session (When Playback Starts)

```dart
Future<String> createLogSession(String roomId) async {
  final doc = await FirebaseFirestore.instance
    .collection('poc_sessions')
    .add({
      'roomId': roomId,
      'startedAt': FieldValue.serverTimestamp(),
    });
  return doc.id;
}
```

### 7.3 Log Position Every 500ms

```dart
class MADLogger {
  Timer? _loggingTimer;
  String? _sessionId;
  final String _clientId = Uuid().v4(); // Unique per device instance

  void startLogging(String sessionId) {
    _sessionId = sessionId;

    _loggingTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!isPlaying) return;

      final positionMs = getEstimatedServerTime() - serverStartTime;
      final boxIndex = (positionMs / 545.45).floor();

      FirebaseFirestore.instance
        .collection('poc_sessions')
        .doc(_sessionId)
        .collection('logs')
        .add({
          'clientId': _clientId,
          'timestamp': FieldValue.serverTimestamp(),
          'localTimeMs': DateTime.now().millisecondsSinceEpoch,
          'currentPositionMs': positionMs,
          'currentBoxIndex': boxIndex,
          'serverTimeOffset': _serverTimeOffset,
        });
    });
  }

  void stopLogging() {
    _loggingTimer?.cancel();

    // Mark session as ended
    if (_sessionId != null) {
      FirebaseFirestore.instance
        .collection('poc_sessions')
        .doc(_sessionId)
        .update({
          'endedAt': FieldValue.serverTimestamp(),
        });
    }
  }
}
```

### 7.4 MAD Calculation (Post-Analysis)

MAD dihitung **setelah** test selesai, bukan real-time. Bisa pakai Python script atau Firestore queries:

```
1. Group logs by timestamp window (round to nearest 500ms)
2. For each window:
   - Get all positionMs values from different clients
   - Calculate mean position
   - Calculate MAD = average of |position - mean|
3. Report: MAD per window, overall MAD, max MAD
```

**Formula:**

```
MAD = (1/N) × Σ |position_i - mean_position|
```

---

## File Structure Recommendation

```
lib/
├── features/
│   └── poc_sync/
│       ├── screens/
│       │   ├── poc_home_screen.dart      # Create/Join room
│       │   └── poc_room_screen.dart      # Playback + kotak UI
│       ├── providers/
│       │   ├── room_provider.dart        # Room CRUD
│       │   ├── sync_provider.dart        # Server time sync
│       │   └── playback_provider.dart    # Playback state
│       ├── services/
│       │   ├── sync_service.dart         # Core sync logic
│       │   └── mad_logger_service.dart   # Logging
│       └── widgets/
│           ├── box_grid_widget.dart      # Kotak berjejer
│           └── countdown_widget.dart     # Countdown display
└── core/
    └── sync/
        └── server_time_service.dart      # Reusable server time
```

---

## Testing Checklist

### Phase 1: Basic Functionality (1 Device)

- [ ] Create room menghasilkan 6-digit code
- [ ] Room data tersimpan di RTDB
- [ ] Server time offset terbaca dengan benar
- [ ] Countdown berjalan setelah start
- [ ] Kotak berubah warna sesuai timing
- [ ] Logs tersimpan ke Firestore

### Phase 2: Multi-Device Sync (2-3 Devices)

- [ ] Device 2 berhasil join dengan code
- [ ] Countdown tersinkron di semua device
- [ ] Playback dimulai bersamaan (visual check)
- [ ] Kotak yang aktif sama di semua device
- [ ] Logs dari semua device tersimpan

### Phase 3: MAD Analysis

- [ ] Export logs dari Firestore
- [ ] Calculate MAD per time window
- [ ] Verify MAD ≤30ms untuk majority samples
- [ ] Identify outliers dan investigate

---

## Common Pitfalls

1. **Jangan pakai `DateTime.now()` langsung** - Selalu tambahkan serverTimeOffset
2. **Timer accuracy** - `Timer.periodic` bisa jitter ±10ms, ini normal
3. **RTDB listener delay** - Ada ~100-200ms delay saat receive update
4. **Firestore write batching** - Jangan write terlalu cepat, 500ms interval sudah cukup
5. **Device sleep** - Pastikan device tidak sleep saat testing

---

## Next Steps After PoC

Jika PoC berhasil (MAD ≤30ms tercapai):

1. Migrate ke actual Score Canvas UI
2. Implement proper room management dengan Firestore
3. Add audio playback (Play Along mode)
4. Add participant ready/not ready states
5. Implement proper error handling & reconnection

Jika PoC gagal:

1. Analyze logs untuk identify bottleneck
2. Consider alternative: WebSocket server, atau
3. Reduce target MAD (50ms mungkin acceptable)
4. Adjust buffer dan resync interval
