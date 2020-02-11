part of 'adapters.dart';

class AdapterForNullTerminatedString
    extends AdapterForSpecificValueOfType<String> {
  const AdapterForNullTerminatedString() : super.primitive();

  @override
  bool matches(String value) => !value.contains('\0');

  @override
  void write(BinaryWriter writer, String value) {
    final bytes = utf8.encode(value);
    bytes.forEach(writer.writeUint8);
    writer.writeUint8(0);
  }

  @override
  String read(BinaryReader reader) {
    final bytes = <int>[];
    while (true) {
      final byte = reader.readUint8();

      if (byte == 0) {
        return utf8.decode(bytes);
      } else {
        bytes.add(byte);
      }
    }
  }
}

class AdapterForArbitraryString extends AdapterForSpecificValueOfType<String> {
  const AdapterForArbitraryString() : super.primitive();

  @override
  bool matches(String value) => true;

  @override
  void write(BinaryWriter writer, String value) {
    final bytes = utf8.encode(value);
    writer.writeUint32(bytes.length);
    for (final byte in bytes) {
      writer.writeUint8(byte);
    }
  }

  @override
  String read(BinaryReader reader) {
    final numBytes = reader.readUint32();
    final bytes = <int>[
      for (int i = 0; i < numBytes; i++) reader.readUint8(),
    ];
    return utf8.decode(bytes);
  }
}
