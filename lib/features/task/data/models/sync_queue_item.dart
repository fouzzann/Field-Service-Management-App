import 'package:hive/hive.dart';

class SyncQueueItem {
  final String id;
  final String taskId;
  final String actionType; // 'updateStatus' | 'uploadPhoto'
  final String payload; // status value or local photo path
  final DateTime timestamp;

  const SyncQueueItem({
    required this.id,
    required this.taskId,
    required this.actionType,
    required this.payload,
    required this.timestamp,
  });

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      payload: json['payload'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'actionType': actionType,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  final int typeId = 2;

  @override
  SyncQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueueItem(
      id: fields[0] as String? ?? '',
      taskId: fields[1] as String? ?? '',
      actionType: fields[2] as String? ?? '',
      payload: fields[3] as String? ?? '',
      timestamp: fields[4] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.actionType)
      ..writeByte(3)
      ..write(obj.payload)
      ..writeByte(4)
      ..write(obj.timestamp);
  }
}
