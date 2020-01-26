part of 'adapters.dart';

// Adapters for types of the dart:typed_data library.

class AdapterForUint8List extends TypeAdapter<Uint8List> {
  const AdapterForUint8List();

  @override
  void write(BinaryWriter writer, Uint8List list) {
    list.forEach(writer.writeUint8);
  }

  @override
  Uint8List read(BinaryReader reader) {
    return Uint8List.fromList([
      for (; reader.hasAvailableBytes;) reader.readUint8(),
    ]);
  }
}
