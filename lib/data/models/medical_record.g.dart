part of 'medical_record.dart';

class MedicalRecordAdapter extends TypeAdapter<MedicalRecord> {
  @override
  final int typeId = 2;

  @override
  MedicalRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicalRecord()
      ..id = fields[0] as String
      ..memberId = fields[1] as String
      ..memberName = fields[2] as String
      ..type = fields[3] as String
      ..title = fields[4] as String
      ..date = fields[5] as String
      ..details = fields[6] as String
      ..doctorName = fields[7] as String?
      ..hospitalName = fields[8] as String?
      ..diagnosis = fields[9] as String?
      ..tags = (fields[10] as List).cast<String>()
      ..attachedFilePaths = (fields[11] as List).cast<String>();
  }

  @override
  void write(BinaryWriter writer, MedicalRecord obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.memberId)
      ..writeByte(2)
      ..write(obj.memberName)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.details)
      ..writeByte(7)
      ..write(obj.doctorName)
      ..writeByte(8)
      ..write(obj.hospitalName)
      ..writeByte(9)
      ..write(obj.diagnosis)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.attachedFilePaths);
  }
}
