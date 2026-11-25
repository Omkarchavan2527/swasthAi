part of 'doctor_session.dart';

class DoctorSessionAdapter extends TypeAdapter<DoctorSession> {
  @override
  final int typeId = 5;

  @override
  DoctorSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoctorSession()
      ..id = fields[0] as String
      ..patientName = fields[1] as String
      ..patientId = fields[2] as String
      ..otp = fields[3] as String
      ..durationMinutes = fields[4] as int
      ..createdAt = fields[5] as String
      ..isRevoked = fields[6] as bool;
  }

  @override
  void write(BinaryWriter writer, DoctorSession obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientName)
      ..writeByte(2)
      ..write(obj.patientId)
      ..writeByte(3)
      ..write(obj.otp)
      ..writeByte(4)
      ..write(obj.durationMinutes)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isRevoked);
  }
}
