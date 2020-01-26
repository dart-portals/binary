part of 'adapters.dart';

// Custom types.

extension CustomTypeWriter on BinaryWriter {
  void writeFieldId(int fieldId) => writeUint16(fieldId);
}

extension CustomTypeReader on BinaryReader {
  int readFieldId() => readUint16();
}
