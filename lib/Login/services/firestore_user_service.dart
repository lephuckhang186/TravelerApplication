import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Login/services/user_profile.dart';

/// Service for interacting with the 'users' collection in Firestore.
///
/// Handles CRUD operations for [UserProfile] data in Firebase Firestore.
class FirestoreUserService {
  static final FirestoreUserService _instance =
      FirestoreUserService._internal();

  /// Factory constructor for singleton instance.
  factory FirestoreUserService() => _instance;

  FirestoreUserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  /// Creates or updates a user profile in Firestore.
  ///
  /// Merges data with existing documents to prevent overwriting unrelated fields.
  /// Throws Exception on failure.
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

  /// Retrieves a user profile by UID.
  ///
  /// Returns [UserProfile] if found, otherwise null.
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

  /// Checks if a user profile exists for the given UID.
  Future<bool> hasUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      return false;
    }
  }

  /// Creates a new profile for a user registering via Email.
  ///
  /// Initializes [createdAt] and [updatedAt] to the current time.
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

  /// Creates a new profile for a user registering via Google.
  ///
  /// Functionally similar to [createEmailUserProfile] but separated for clarity.
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

  /// Updates specific fields of a user's profile.
  ///
  /// Automatically updates the [updatedAt] timestamp.
  /// Only non-null arguments will be updated.
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

  /// Updates a single field in the user profile.
  ///
  /// Useful for quick updates like toggling settings.
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

  /// Deletes a user profile from Firestore.
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa thông tin người dùng: $e');
    }
  }

  /// Returns a stream of user profile updates.
  ///
  /// Useful for real-time UI updates when profile data changes.
  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firestore.collection(_collection).doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromDocument(doc);
      }
      return null;
    });
  }
}
