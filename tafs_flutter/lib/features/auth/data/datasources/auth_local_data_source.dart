import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/parent_dto.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheParent(ParentDto parent);
  Future<ParentDto?> getCachedParent();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  static const String cachedParentKey = 'CACHED_PARENT';

  AuthLocalDataSourceImpl(this.secureStorage);

  @override
  Future<void> cacheParent(ParentDto parent) async {
    // We store the whole DTO as JSON for simplicity, or just the token.
    // Storing full object enables offline ledger viewing capabilities!
    await secureStorage.write(key: cachedParentKey, value: json.encode(parent.toJson()));
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
  Future<void> clearCache() async {
    await secureStorage.delete(key: cachedParentKey);
  }
}
