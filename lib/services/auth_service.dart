import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A service that handles Firebase Authentication operations in Flutter.
/// This includes Email/Password registration, Email/Password login,
/// Google Sign-In, and Logout, as well as accessing the current user state.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Creates an [AuthService] instance.
  ///
  /// Allows injecting custom [FirebaseAuth] and [GoogleSignIn] instances
  /// for easier testing and mocking.
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  bool _isGoogleSignInInitialized = false;

  /// A getter for the currently authenticated [User].
  ///
  /// Returns `null` if no user is signed in.
  User? get currentUser => _auth.currentUser;

  /// A stream of [User] auth state changes.
  ///
  /// Useful for listening to real-time login/logout state changes in the UI.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs up a user using their [email] and [password].
  ///
  /// Returns the authenticated [User] if successful.
  /// Throws a [FirebaseAuthException] if Firebase authentication fails,
  /// or a generic [Exception] for other failures.
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException {
      // Re-throw the FirebaseAuthException so the UI can catch it and display custom messages
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during email sign up: $e');
    }
  }

  /// Logs in a user using their [email] and [password].
  ///
  /// Returns the authenticated [User] if successful.
  /// Throws a [FirebaseAuthException] if Firebase authentication fails,
  /// or a generic [Exception] for other failures.
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException {
      // Re-throw the FirebaseAuthException so the UI can catch it and display custom messages
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during email sign in: $e');
    }
  }

  /// Sends a password reset email to the provided [email].
  ///
  /// Throws a [FirebaseAuthException] if Firebase authentication fails,
  /// or a generic [Exception] for other failures.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(
        'An unexpected error occurred while sending password reset email: $e',
      );
    }
  }

  /// Signs in the user using Google Sign-In.
  ///
  /// Returns the authenticated [User] if successful.
  /// Returns `null` if the user cancelled the Google Sign-In flow.
  /// Throws a [FirebaseAuthException] if Firebase authentication fails,
  /// or a generic [Exception] for other failures.
  Future<User?> signInWithGoogle() async {
    try {
      if (!_isGoogleSignInInitialized) {
        await _googleSignIn.initialize(
          serverClientId:
              '474953957370-lgrnatl4sonntfvjvsua18b9pqk6595m.apps.googleusercontent.com',
        );
        _isGoogleSignInInitialized = true;
      }

      // Trigger the interactive Google Sign-In flow (google_sign_in v7 API)
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain the idToken from the authenticated account
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Obtain the accessToken by authorizing scopes via the authorizationClient
      final GoogleSignInClientAuthorization? clientAuth = await googleUser
          .authorizationClient
          .authorizationForScopes(['email']);

      // Create a new Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth?.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during Google Sign-In: $e');
    }
  }

  /// Signs out the current user from both Firebase and Google Sign-In.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('An error occurred while signing out: $e');
    }
  }
}
