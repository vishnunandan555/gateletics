import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Check if Firebase is supported on the current platform
bool isFirebaseSupported() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class AuthState {
  final User? user;
  final bool isOfflineMode;
  final bool isLoading;

  AuthState({
    this.user,
    required this.isOfflineMode,
    required this.isLoading,
  });

  AuthState copyWith({
    User? user,
    bool? isOfflineMode,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  late SharedPreferences _prefs;

  @override
  Future<AuthState> build() async {
    _prefs = await SharedPreferences.getInstance();
    final hasChosenOffline = _prefs.getBool('has_chosen_offline') ?? false;

    if (!isFirebaseSupported()) {
      // Force offline mode for unsupported platforms (e.g. desktop)
      return AuthState(user: null, isOfflineMode: true, isLoading: false);
    }

    // Return the initial state matching current FirebaseAuth user
    final auth = FirebaseAuth.instance;
    return AuthState(
      user: auth.currentUser,
      isOfflineMode: hasChosenOffline,
      isLoading: false,
    );
  }

  // Set the offline choice
  Future<void> chooseOfflineMode() async {
    state = const AsyncValue.loading();
    await _prefs.setBool('has_chosen_offline', true);
    state = AsyncValue.data(AuthState(
      user: null,
      isOfflineMode: true,
      isLoading: false,
    ));
  }

  // Handle Google Sign-In
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      if (!isFirebaseSupported()) {
        throw UnsupportedError('Firebase is not supported on this platform.');
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow
        final currentOffline = _prefs.getBool('has_chosen_offline') ?? false;
        state = AsyncValue.data(AuthState(
          user: null,
          isOfflineMode: currentOffline,
          isLoading: false,
        ));
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Disable offline mode on successful login
      await _prefs.setBool('has_chosen_offline', false);

      state = AsyncValue.data(AuthState(
        user: userCredential.user,
        isOfflineMode: false,
        isLoading: false,
      ));
    } catch (e, stack) {
      final currentOffline = _prefs.getBool('has_chosen_offline') ?? false;
      state = AsyncValue.error(e, stack);
      // Fallback to previous state
      state = AsyncValue.data(AuthState(
        user: FirebaseAuth.instance.currentUser,
        isOfflineMode: currentOffline,
        isLoading: false,
      ));
      rethrow;
    }
  }

  // Handle Sign-Out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      if (isFirebaseSupported()) {
        await GoogleSignIn().signOut();
        await FirebaseAuth.instance.signOut();
      }
      await _prefs.setBool('has_chosen_offline', false);
      state = AsyncValue.data(AuthState(
        user: null,
        isOfflineMode: false,
        isLoading: false,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Reset the onboarding choice (e.g. to configure again)
  Future<void> resetAuthChoice() async {
    state = const AsyncValue.loading();
    await _prefs.remove('has_chosen_offline');
    if (isFirebaseSupported()) {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    }
    state = AsyncValue.data(AuthState(
      user: null,
      isOfflineMode: false,
      isLoading: false,
    ));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
