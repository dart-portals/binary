part of 'adapters.dart';

// Adapters for types of the dart:typed_data library.

class AdapterForUint8List extends AdapterFor<Uint8List> {
  const AdapterForUint8List();

  @override
  void write(BinaryWriter writer, Uint8List list) {
    writer.writeUint32(list.length);
    list.forEach(writer.writeUint8);
  }

  @override
  Uint8List read(BinaryReader reader) {
    final length = reader.readUint32();
    return Uint8List.fromList([
      for (var i = 0; i < length; i++) reader.readUint8(),
    ]);
  }
}
