import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sync_provider.dart';

// Check if Firebase is supported on the current platform
bool isFirebaseSupported() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.windows;
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

  // Generate a cryptographically secure random verifier for PKCE
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  }

  // Generate SHA-256 code challenge for PKCE
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  }

  Future<UserCredential> _signInWithGoogleWindows() async {
    // 1. Bind to loopback server on a random port
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;

    // 2. Generate PKCE verifier and challenge
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    // 3. Construct OAuth URL
    const String clientId = '981770496770-vjquhdkpekv4t22gaqtm5ng975u7927r.apps.googleusercontent.com';
    final redirectUri = 'http://127.0.0.1:$port';

    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    // 4. Launch URL
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      server.close(force: true);
      throw Exception('Could not launch Google Sign-In browser.');
    }

    // 5. Complete with code or throw timeout error after 3 minutes
    final Completer<String> codeCompleter = Completer<String>();
    final timeoutTimer = Timer(const Duration(minutes: 3), () {
      if (!codeCompleter.isCompleted) {
        codeCompleter.completeError(TimeoutException('Sign-in timed out after 3 minutes.'));
        server.close(force: true);
      }
    });

    // 6. Listen for local server redirect request
    unawaited(() async {
      try {
        await for (HttpRequest request in server) {
          final code = request.uri.queryParameters['code'];
          if (code != null) {
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.html
              ..write('''
                <html>
                  <head>
                    <title>Sign-in Success</title>
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <style>
                      body {
                        font-family: sans-serif;
                        background-color: #09090B;
                        color: #FFFFFF;
                        display: flex;
                        flex-direction: column;
                        justify-content: center;
                        align-items: center;
                        height: 100vh;
                        margin: 0;
                      }
                      .card {
                        background-color: #131316;
                        border: 1px solid rgba(255,255,255,0.08);
                        border-radius: 16px;
                        padding: 40px;
                        text-align: center;
                        box-shadow: 0 10px 30px rgba(0,0,0,0.5);
                        max-width: 400px;
                      }
                      h2 { color: #22D3EE; margin-top: 0; }
                      p { color: #A1A1AA; font-size: 14px; line-height: 1.5; }
                    </style>
                  </head>
                  <body>
                    <div class="card">
                      <h2>GATEletics Login Success</h2>
                      <p>Authentication was successful. You may now close this tab and return to the application.</p>
                    </div>
                  </body>
                </html>
              ''');
            await request.response.close();
            codeCompleter.complete(code);
            server.close(force: true);
            break;
          } else {
            request.response
              ..statusCode = 400
              ..headers.contentType = ContentType.text
              ..write('Authorization code missing in callback.');
            await request.response.close();
          }
        }
      } catch (e) {
        if (!codeCompleter.isCompleted) {
          codeCompleter.completeError(e);
        }
      }
    }());

    try {
      final code = await codeCompleter.future;
      timeoutTimer.cancel();

      // 7. Token exchange POST request
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': code,
          'client_id': clientId,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Token exchange failed: ${response.body}');
      }

      final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = tokenData['access_token'] as String?;
      final idToken = tokenData['id_token'] as String?;

      if (idToken == null) {
        throw Exception('ID Token missing from token exchange.');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      timeoutTimer.cancel();
      rethrow;
    }
  }

  // Handle Google Sign-In
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      if (!isFirebaseSupported()) {
        throw UnsupportedError('Firebase is not supported on this platform.');
      }

      final UserCredential userCredential;

      if (kIsWeb) {
        // Use Firebase Auth's native signInWithPopup for Web. This runs inside Firebase's
        // auth handler domain, bypassing GIS (Google Identity Services) iframe restrictions
        // and resolving the common 'popup_closed' error in Firefox/Safari.
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        // Windows Desktop OAuth 2.0 Loopback flow
        userCredential = await _signInWithGoogleWindows();
      } else {
        // Mobile platform (Android/iOS) uses the GoogleSignIn package flow
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

        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

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
        if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
          await GoogleSignIn().signOut();
        }
        await FirebaseAuth.instance.signOut();
      }
      await _prefs.setBool('has_chosen_offline', false);
      try {
        await ref.read(syncProvider.notifier).clearSyncState();
      } catch (e) {
        debugPrint("Error clearing sync state: $e");
      }
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
      if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        await GoogleSignIn().signOut();
      }
      await FirebaseAuth.instance.signOut();
    }
    try {
      await ref.read(syncProvider.notifier).clearSyncState();
    } catch (e) {
      debugPrint("Error clearing sync state: $e");
    }
    state = AsyncValue.data(AuthState(
      user: null,
      isOfflineMode: false,
      isLoading: false,
    ));
  }

  // Delete user account and all Firestore backups
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete Firestore document first
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        } catch (e) {
          debugPrint("Error deleting user Firestore data: $e");
        }
        // Delete FirebaseAuth user
        await user.delete();
      }
      if (isFirebaseSupported()) {
        if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
          await GoogleSignIn().signOut();
        }
      }
      await _prefs.setBool('has_chosen_offline', false);
      try {
        await ref.read(syncProvider.notifier).clearSyncState();
      } catch (e) {
        debugPrint("Error clearing sync state: $e");
      }
      state = AsyncValue.data(AuthState(
        user: null,
        isOfflineMode: false,
        isLoading: false,
      ));
    } catch (e) {
      final currentOffline = _prefs.getBool('has_chosen_offline') ?? false;
      state = AsyncValue.data(AuthState(
        user: FirebaseAuth.instance.currentUser,
        isOfflineMode: currentOffline,
        isLoading: false,
      ));
      rethrow;
    }
  }

  // Delete user account data on Firebase/Firestore server only
  Future<void> deleteServerAccountOnly() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Delete Firestore document first
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      } catch (e) {
        debugPrint("Error deleting user Firestore data: $e");
      }
      // Delete FirebaseAuth user
      await user.delete();
    }
  }

  // Complete local sign out after confirming server deletion
  Future<void> completeLocalSignOut() async {
    state = const AsyncValue.loading();
    try {
      if (isFirebaseSupported()) {
        if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
          await GoogleSignIn().signOut();
        }
        await FirebaseAuth.instance.signOut();
      }
      await _prefs.setBool('has_chosen_offline', false);
      try {
        await ref.read(syncProvider.notifier).clearSyncState();
      } catch (e) {
        debugPrint("Error clearing sync state: $e");
      }
      state = AsyncValue.data(AuthState(
        user: null,
        isOfflineMode: false,
        isLoading: false,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
