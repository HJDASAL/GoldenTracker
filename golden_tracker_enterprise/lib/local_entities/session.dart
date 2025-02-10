import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class HiveSession extends HiveObject {
  HiveSession(
    this.username, {
    required this.password,
    required this.token,
    this.autoRefresh = false,
    this.expiresOn,
  });

  @HiveField(0)
  final String username;

  @HiveField(1)
  final String password;

  @HiveField(2)
  String token;

  @HiveField(3)
  DateTime? expiresOn;

  @HiveField(4)
  bool autoRefresh;

  bool get isExpired => expiresOn == null || DateTime.now().isAfter(expiresOn!);
}

class SessionAdapter extends TypeAdapter<HiveSession> {
  SessionAdapter(this.typeId);

  @override
  final int typeId;

  @override
  HiveSession read(BinaryReader reader) {
    final username = reader.read() as String;
    final password = reader.read() as String;
    final token = reader.read() as String;
    final expiresOn = reader.read() as DateTime?;
    final autoRefresh = reader.read() as bool;

    return HiveSession(
      username,
      password: password,
      token: token,
      expiresOn: expiresOn,
      autoRefresh: autoRefresh,
    );
  }

  @override
  void write(BinaryWriter writer, HiveSession obj) {
    writer
      ..write(obj.username)
      ..write(obj.password)
      ..write(obj.token)
      ..write(obj.expiresOn)
      ..write(obj.autoRefresh);
  }
}
