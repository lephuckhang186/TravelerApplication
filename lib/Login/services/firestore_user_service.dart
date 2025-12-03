import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Login/services/user_profile.dart';

class FirestoreUserService {
  static final FirestoreUserService _instance =
      FirestoreUserService._internal();
  factory FirestoreUserService() => _instance;
  FirestoreUserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Tạo hoặc cập nhật thông tin người dùng
  Future<void> createOrUpdateUser(UserProfile userProfile) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userProfile.uid)
          .set(userProfile.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Lỗi khi lưu thông tin người dùng: $e');
    }
  }

  // Lấy thông tin người dùng theo UID
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin người dùng: $e');
    }
  }

  // Kiểm tra người dùng đã có thông tin profile chưa
  Future<bool> hasUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      return false;
    }
  }

  // Tạo profile mới cho người dùng đăng ký email
  Future<void> createEmailUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required DateTime dateOfBirth,
  }) async {
    final now = DateTime.now();
    final userProfile = UserProfile(
      uid: uid,
      email: email,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      createdAt: now,
      updatedAt: now,
    );

    await createOrUpdateUser(userProfile);
  }

  // Tạo profile mới cho người dùng đăng ký Google
  Future<void> createGoogleUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required DateTime dateOfBirth,
  }) async {
    final now = DateTime.now();
    final userProfile = UserProfile(
      uid: uid,
      email: email,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      createdAt: now,
      updatedAt: now,
    );

    await createOrUpdateUser(userProfile);
  }

  // Cập nhật thông tin người dùng
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    DateTime? dateOfBirth,
    String? phone,
    String? address,
    String? gender,
    String? profilePicture,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (fullName != null) updates['fullName'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (gender != null) updates['gender'] = gender;
      if (profilePicture != null) updates['profilePicture'] = profilePicture;

      if (dateOfBirth != null) {
        updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      }

      await _firestore.collection(_collection).doc(uid).update(updates);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật thông tin người dùng: $e');
    }
  }

  // Cập nhật một trường cụ thể
  Future<void> updateUserField({
    required String uid,
    required String field,
    required dynamic value,
  }) async {
    try {
      final updates = <String, dynamic>{
        field: value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore.collection(_collection).doc(uid).update(updates);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trường $field: $e');
    }
  }

  // Xóa thông tin người dùng
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa thông tin người dùng: $e');
    }
  }

  // Stream để theo dõi thay đổi thông tin người dùng
  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firestore.collection(_collection).doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromDocument(doc);
      }
      return null;
    });
  }
}
