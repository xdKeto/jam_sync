import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_sign_in/google_sign_in.dart';

// auth stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// provider to firestore
final userProvider = FutureProvider.family<Map<String, dynamic>?, String>((
  ref,
  uid,
) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  return doc.data();
});

// cek status user
final isNewUserProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  if (!doc.exists) return true;

  final data = doc.data()!;
  return data['profileCompleted'] != true;
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool isInitialize = false;

  AuthNotifier() : super(const AsyncValue.data(null));

  static Future<void> initSignIn() async {
    if (!isInitialize) {
      await _googleSignIn.initialize(
        serverClientId:
            '888936093592-3nn700cedmuo4gseash2uhstfu7352ij.apps.googleusercontent.com',
      );
    }

    isInitialize = true;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      await initSignIn();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final authClient = googleUser.authorizationClient;
      GoogleSignInClientAuthorization? authorization = await authClient
          .authorizationForScopes(['email', 'profile']);

      final accessToken = authorization?.accessToken;
      if (accessToken == null) {
        final authorization2 = await authClient.authorizationForScopes([
          'email',
          'profile',
        ]);

        if (authorization2?.accessToken == null) {
          throw FirebaseAuthException(code: 'error', message: 'error');
        }

        authorization = authorization2;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;
      if (user != null) {
        final userData = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final docSnapshot = await userData.get();
        if (!docSnapshot.exists) {
          await userData.set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName ?? '',
            'photoURL': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeenAt': FieldValue.serverTimestamp(),
            'profileCompleted': false,
          });
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, string) {
      state = AsyncValue.error(e, string);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, string) {
      state = AsyncValue.error(e, string);
    }
  }

  Future<void> saveUser({required String displayName, String? photoURL}) async {
    state = AsyncValue.loading();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'displayName': displayName,
            if (photoURL != null) 'photoURL': photoURL,
            'profileCompleted': true,
            'lastSeenAt': FieldValue.serverTimestamp(),
          });

      state = AsyncValue.data(null);
    } catch (e, string) {
      state = AsyncValue.error(e, string);
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
      (ref) => AuthNotifier(),
    );
