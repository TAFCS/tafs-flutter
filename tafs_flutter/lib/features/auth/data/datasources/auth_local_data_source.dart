import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/parent_dto.dart';
import '../models/staff_user_dto.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheParent(ParentDto parent);
  Future<ParentDto?> getCachedParent();
  Future<void> clearParentCache();

  Future<void> cacheStaff(StaffUserDto staff);
  Future<StaffUserDto?> getCachedStaff();
  Future<void> clearStaffCache();

  Future<void> clearCache();
  Future<String?> getActiveAccessToken();
  Future<bool> hasStaffSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  static const String cachedParentKey = 'CACHED_PARENT';
  static const String cachedStaffKey = 'CACHED_STAFF';

  AuthLocalDataSourceImpl(this.secureStorage);

  @override
  Future<void> cacheParent(ParentDto parent) async {
    await secureStorage.write(
      key: cachedParentKey,
      value: json.encode(parent.toJson()),
    );
  }

  @override
  Future<ParentDto?> getCachedParent() async {
    final jsonString = await secureStorage.read(key: cachedParentKey);
    if (jsonString != null) {
      return ParentDto.fromJson(json.decode(jsonString));
    }
    return null;
  }

  @override
  Future<void> clearParentCache() async {
    await secureStorage.delete(key: cachedParentKey);
  }

  @override
  Future<void> cacheStaff(StaffUserDto staff) async {
    await secureStorage.write(
      key: cachedStaffKey,
      value: json.encode(staff.toJson()),
    );
  }

  @override
  Future<StaffUserDto?> getCachedStaff() async {
    final jsonString = await secureStorage.read(key: cachedStaffKey);
    if (jsonString != null) {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return StaffUserDto.fromJson(decoded);
    }
    return null;
  }

  @override
  Future<void> clearStaffCache() async {
    await secureStorage.delete(key: cachedStaffKey);
  }

  @override
  Future<void> clearCache() async {
    await clearParentCache();
    await clearStaffCache();
  }

  @override
  Future<String?> getActiveAccessToken() async {
    final staff = await getCachedStaff();
    if (staff != null && staff.accessToken.isNotEmpty) {
      return staff.accessToken;
    }
    final parent = await getCachedParent();
    return parent?.accessToken;
  }

  @override
  Future<bool> hasStaffSession() async {
    final staff = await getCachedStaff();
    return staff != null && staff.accessToken.isNotEmpty;
  }
}
