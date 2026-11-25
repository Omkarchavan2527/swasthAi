part of 'family_member.dart';

class FamilyMemberAdapter extends TypeAdapter<FamilyMember> {
  @override
  final int typeId = 0;

  @override
  FamilyMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final member = FamilyMember()
      ..id = fields[0] as String? ?? ''
      ..name = fields[1] as String? ?? ''
      ..age = fields[2] as int? ?? 0
      ..gender = fields[3] as String? ?? 'Male'
      ..relationship = fields[4] as String? ?? 'Self'
      ..bloodGroup = fields[5] as String? ?? 'O+'
      ..chronicConditions = fields[6] != null
          ? (fields[6] as List).cast<String>()
          : <String>[]
      ..phone = fields[7] as String? ?? ''
      ..photoUrl = fields[8] as String?;
    // Only set caretakerId if the field exists in stored data (old records won't have it)
    if (fields.containsKey(9)) {
      member.caretakerId = fields[9] as String?;
    }
    return member;
  }

  @override
  void write(BinaryWriter writer, FamilyMember obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.gender)
      ..writeByte(4)
      ..write(obj.relationship)
      ..writeByte(5)
      ..write(obj.bloodGroup)
      ..writeByte(6)
      ..write(obj.chronicConditions)
      ..writeByte(7)
      ..write(obj.phone)
      ..writeByte(8)
      ..write(obj.photoUrl)
      ..writeByte(9)
      ..write(obj.caretakerId);
  }
}
