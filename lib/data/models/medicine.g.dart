part of 'medicine.dart';

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 1;

  @override
  Medicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final med = Medicine()
      ..id = fields[0] as String? ?? ''
      ..memberId = fields[1] as String? ?? ''
      ..memberName = fields[2] as String? ?? ''
      ..name = fields[3] as String? ?? ''
      ..dosage = fields[4] as String? ?? ''
      ..timing = fields[5] as String? ?? '08:00'
      ..frequency = fields[6] as String? ?? 'Daily'
      ..startDate = fields[7] as String? ?? ''
      ..endDate = fields[8] as String? ?? ''
      ..instructions = fields[9] as String? ?? ''
      ..takenToday = fields[10] as bool? ?? false;

    // New optional fields - only set if present (avoids crash on old records)
    med.scheduledTimes = fields[11] != null
        ? (fields[11] as List).cast<String>()
        : ['08:00'];
    med.reminderBeforeMinutes = fields[12] as int? ?? 15;
    med.gracePeriodMinutes = fields[13] as int? ?? 15;
    med.reminderEnabled = fields[14] as bool? ?? true;
    if (fields.containsKey(15)) {
      med.prescribedBy = fields[15] as String?;
    }

    return med;
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.memberId)
      ..writeByte(2)
      ..write(obj.memberName)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.dosage)
      ..writeByte(5)
      ..write(obj.timing)
      ..writeByte(6)
      ..write(obj.frequency)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.instructions)
      ..writeByte(10)
      ..write(obj.takenToday)
      ..writeByte(11)
      ..write(obj.scheduledTimes)
      ..writeByte(12)
      ..write(obj.reminderBeforeMinutes)
      ..writeByte(13)
      ..write(obj.gracePeriodMinutes)
      ..writeByte(14)
      ..write(obj.reminderEnabled)
      ..writeByte(15)
      ..write(obj.prescribedBy);
  }
}
