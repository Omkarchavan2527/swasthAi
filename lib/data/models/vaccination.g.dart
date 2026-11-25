part of 'vaccination.dart';

class VaccinationAdapter extends TypeAdapter<Vaccination> {
  @override
  final int typeId = 4;

  @override
  Vaccination read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vaccination()
      ..id = fields[0] as String
      ..memberId = fields[1] as String
      ..memberName = fields[2] as String
      ..vaccineName = fields[3] as String
      ..diseaseProtected = fields[4] as String
      ..dueDate = fields[5] as String
      ..given = fields[6] as bool
      ..givenDate = fields[7] as String?
      ..ageMilestone = fields[8] as String;
  }

  @override
  void write(BinaryWriter writer, Vaccination obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.memberId)
      ..writeByte(2)
      ..write(obj.memberName)
      ..writeByte(3)
      ..write(obj.vaccineName)
      ..writeByte(4)
      ..write(obj.diseaseProtected)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.given)
      ..writeByte(7)
      ..write(obj.givenDate)
      ..writeByte(8)
      ..write(obj.ageMilestone);
  }
}
