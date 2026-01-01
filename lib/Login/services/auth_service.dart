import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

/// Service for handling authentication using Firebase and Google Sign-In.
///
/// This service provides methods for signing up, signing in, signing out,
/// and syncing user data with the backend. It implements the Singleton pattern.
class AuthService {
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor to return the singleton instance.
  factory AuthService() => _instance;

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '522424214900-dalkqs7t7kba0r25doeg66j1bcms6jku.apps.googleusercontent.com',
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  // Backend URLs
  static const String _baseUrl =
      'http://localhost:8000/api/v1'; // travelpro-backend
  static const String _travelAgentUrl = 'http://localhost:8001'; // travel-agent

  /// Returns the current authenticated user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Returns true if a user is currently logged in.
  bool get isLoggedIn => currentUser != null;

  /// Stream to listen for authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs up a new user with email and password.
  ///
  /// Forces email trim before submission.
  /// Automatically syncs the new user with the backend upon successful creation.
  ///
  /// Throws [FirebaseAuthException] if registration fails.
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Sync user info with backend
      await _syncUserWithBackend(credential.user!);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Checks if an email address is already registered.
  ///
  /// Uses [sendPasswordResetEmail] as a workaround since `fetchSignInMethodsForEmail`
  /// is deprecated or restricted.
  ///
  /// Returns a map with 'exists' (bool) and a message.
  Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      // Try to send password reset email to check existence
      try {
        await _auth.sendPasswordResetEmail(email: email.trim());
        return {
          'exists': true,
          'message':
              'Email này đã được đăng ký', // Keeping original message for UI consistency
        };
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          return {'exists': false, 'message': 'Email này chưa được đăng ký'};
        }
        // Email exists but other error occurred
        return {'exists': true, 'message': 'Email này đã được đăng ký'};
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Signs in a user with email and password.
  ///
  /// Syncs user data with the backend after successful login.
  ///
  /// Throws [FirebaseAuthException] if sign-in fails.
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sync with backend
      await _syncUserWithBackend(credential.user!);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Signs in a user using Google Sign-In.
  ///
  /// Signs out of Google first to ensure the account picker is shown.
  /// Syncs user data with the backend after successful login.
  ///
  /// Returns [UserCredential] if successful, or null if cancelled.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out first to ensure account selection prompt
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Only accessToken is strictly required, idToken might be null on web
      if (googleAuth.accessToken == null) {
        throw Exception('Không thể lấy token từ Google');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Sync with backend
      await _syncUserWithBackend(userCredential.user!);

      return userCredential;
    } catch (e) {
      // Only throw if not cancelled/popup closed
      if (!e.toString().contains('popup_closed')) {
        rethrow;
      }
      return null;
    }
  }

  /// Signs out the current user from both Firebase and Google.
  ///
  /// Also clears secure storage.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Lỗi đăng xuất: ${e.toString()}');
    }
  }

  /// Sends a password reset email to the specified address.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Changes the password for the current user.
  ///
  /// Requires [currentPassword] for re-authentication before updating to [newPassword].
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update to new password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Syncs the user's data with the backend database.
  ///
  /// Stores the Firebase ID token in secure storage and sends user profile
  /// data to the backend API.
  Future<void> _syncUserWithBackend(User user) async {
    try {
      final idToken = await user.getIdToken();

      // Save token to secure storage
      await _storage.write(key: 'firebase_token', value: idToken);
      await _storage.write(key: 'user_id', value: user.uid);

      // Send user info to backend
      await _dio.post(
        '$_baseUrl/auth/sync-user',
        data: {
          'uid': user.uid,
          'email': user.email,
          'display_name': user.displayName,
          'photo_url': user.photoURL,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (e) {
      // Fail silently for sync issues to avoid blocking login flow
    }
  }

  /// Retrieves the current user's Firebase ID token.
  ///
  /// Returns null if no user is logged in or an error occurs.
  Future<String?> getIdToken() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      return await user.getIdToken();
    } catch (e) {
      return null;
    }
  }

  /// Calls the Travel Agent API.
  ///
  /// Sends user [input] and conversation [history] to the AI agent.
  /// Requires authentication.
  Future<Map<String, dynamic>> callTravelAgent(
    String input,
    List<Map<String, String>> history,
  ) async {
    try {
      final token = await getIdToken();

      final response = await _dio.post(
        '$_travelAgentUrl/invoke',
        data: {'input': input, 'history': history},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      throw Exception('Lỗi gọi API travel agent: ${e.toString()}');
    }
  }

  /// Handles Firebase Authentication exceptions and returns user-friendly error messages.
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Vui lòng sử dụng email khác.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng. Vui lòng thử lại.';
      case 'invalid-email':
        return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt.';
      default:
        return 'Đã xảy ra lỗi: ${e.message}';
    }
  }

  /// Checks connectivity to the backend API.
  Future<bool> checkBackendConnection() async {
    try {
      final response = await _dio.get('$_baseUrl/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Checks connectivity to the Travel Agent API.
  Future<bool> checkTravelAgentConnection() async {
    try {
      final response = await _dio.get('$_travelAgentUrl/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
