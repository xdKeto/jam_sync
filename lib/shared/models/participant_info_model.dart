class ParticipantInfo {
  final String uid;
  final String displayName;
  final String? photoURL;
  final bool isOnline;
  final bool isLeader;
  final int? latencyMs;
  final bool isReady;

  ParticipantInfo({
    required this.uid,
    required this.displayName,
    this.photoURL,
    required this.isOnline,
    required this.isLeader,
    this.latencyMs,
    required this.isReady,
  });

  factory ParticipantInfo.fromMap(Map<String, dynamic> map) {
    return ParticipantInfo(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      isOnline: map['isOnline'] ?? false,
      isLeader: map['isLeader'] ?? false,
      latencyMs: map['latencyMs'],
      isReady: map['isReady'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoURL': photoURL,
      'isOnline': isOnline,
      'isLeader': isLeader,
      'latencyMs': latencyMs,
      'isReady': isReady,
    };
  }
}
