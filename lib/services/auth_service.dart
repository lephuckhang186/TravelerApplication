import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '522424214900-dalkqs7t7kba0r25doeg66j1bcms6jku.apps.googleusercontent.com',
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  // Backend URLs
  static const String _baseUrl = 'http://localhost:8000/api/v1'; // travelpro-backend
  static const String _travelAgentUrl = 'http://localhost:8001'; // travel-agent

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Stream để theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký bằng email và password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Gửi thông tin user lên backend
      await _syncUserWithBackend(credential.user!);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Đăng nhập bằng email và password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Đồng bộ với backend
      await _syncUserWithBackend(credential.user!);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Bắt đầu đăng nhập Google...');
      
      // Đăng xuất trước để đảm bảo prompt chọn tài khoản
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Người dùng đã hủy đăng nhập Google');
        throw Exception('Đăng nhập Google đã bị hủy');
      }

      print('Đăng nhập Google thành công cho: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // DEBUG: In ra thông tin token
      print('Access Token: ${googleAuth.accessToken}');
      print('ID Token: ${googleAuth.idToken}');
      
      // CHỈ CẦN accessToken là đủ, idToken có thể null trên web
      if (googleAuth.accessToken == null) {
        throw Exception('Không thể lấy token từ Google');
      }
      print('Đã lấy token từ Google');
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      print('Đăng nhập Firebase thành công cho: ${userCredential.user?.email}');
      
      // Đồng bộ với backend
      await _syncUserWithBackend(userCredential.user!);
      
      print('Đồng bộ với backend hoàn tất');
      
      return userCredential;
    } catch (e) {
      print('Lỗi đăng nhập Google: ${e.toString()}');
      throw Exception('Lỗi đăng nhập Google: ${e.toString()}');
    }
  }


  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Lỗi đăng xuất: ${e.toString()}');
    }
  }

  // Gửi email reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Đồng bộ user với backend
  Future<void> _syncUserWithBackend(User user) async {
    try {
      final idToken = await user.getIdToken();
      
      // Lưu token vào secure storage
      await _storage.write(key: 'firebase_token', value: idToken);
      await _storage.write(key: 'user_id', value: user.uid);
      
      // Gửi thông tin user lên backend travelpro
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
      print('Lỗi đồng bộ với backend: $e');
    }
  }

  // Lấy token để gọi API
  Future<String?> getIdToken() async {
    try {
      final user = currentUser;
      if (user == null) return null;
      
      return await user.getIdToken();
    } catch (e) {
      print('Lỗi lấy token: $e');
      return null;
    }
  }

  // Gọi API travel agent
  Future<Map<String, dynamic>> callTravelAgent(String input, List<Map<String, String>> history) async {
    try {
      final token = await getIdToken();
      
      final response = await _dio.post(
        '$_travelAgentUrl/invoke',
        data: {
          'input': input,
          'history': history,
        },
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

  // Xử lý lỗi Firebase Auth
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

  // Kiểm tra kết nối backend
  Future<bool> checkBackendConnection() async {
    try {
      final response = await _dio.get('$_baseUrl/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Kiểm tra kết nối travel agent
  Future<bool> checkTravelAgentConnection() async {
    try {
      final response = await _dio.get('$_travelAgentUrl/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}