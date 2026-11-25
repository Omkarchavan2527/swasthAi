part of 'health_measurement.dart';

class HealthMeasurementAdapter extends TypeAdapter<HealthMeasurement> {
  @override
  final int typeId = 3;

  @override
  HealthMeasurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthMeasurement()
      ..id = fields[0] as String
      ..memberId = fields[1] as String
      ..memberName = fields[2] as String
      ..date = fields[3] as String
      ..systolicBP = fields[4] as int
      ..diastolicBP = fields[5] as int
      ..bloodSugar = fields[6] as double
      ..weight = fields[7] as double
      ..heartRate = fields[8] as int;
  }

  @override
  void write(BinaryWriter writer, HealthMeasurement obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.memberId)
      ..writeByte(2)
      ..write(obj.memberName)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.systolicBP)
      ..writeByte(5)
      ..write(obj.diastolicBP)
      ..writeByte(6)
      ..write(obj.bloodSugar)
      ..writeByte(7)
      ..write(obj.weight)
      ..writeByte(8)
      ..write(obj.heartRate);
  }
}
