/// Turns out, [int]s are are pretty common thing to encode. We have enough
/// type ids anyways, so let's use some of them to encode [int]s of different
/// dimensions differently. There's 8, 16, 32 and 64 bit integers. Also, all
/// integers can be saved as signed or unsigned ints.

part of 'adapters.dart';

class AdapterForUint8 extends AdapterForSpecificValueOfType<int> {
  const AdapterForUint8() : super.primitive();

  @override
  bool matches(int value) => value >= 0 && value < 256;

  @override
  void write(BinaryWriter writer, int value) => writer.writeUint8(value);

  @override
  int read(BinaryReader reader) => reader.readUint8();
}

class AdapterForInt8 extends AdapterForSpecificValueOfType<int> {
  const AdapterForInt8() : super.primitive();

  @override
  bool matches(int value) => value >= -128 && value < 128;

  @override
  void write(BinaryWriter writer, int value) => writer.writeInt8(value);

  @override
  int read(BinaryReader reader) => reader.readInt8();
}

class AdapterForUint16 extends AdapterForSpecificValueOfType<int> {
  const AdapterForUint16() : super.primitive();

  @override
  bool matches(int value) => value >= 0 && value < 65536;

  @override
  void write(BinaryWriter writer, int value) => writer.writeUint16(value);

  @override
  int read(BinaryReader reader) => reader.readUint16();
}

class AdapterForInt16 extends AdapterForSpecificValueOfType<int> {
  const AdapterForInt16() : super.primitive();

  @override
  bool matches(int value) => value >= -32768 && value < 32768;

  @override
  void write(BinaryWriter writer, int value) => writer.writeInt16(value);

  @override
  int read(BinaryReader reader) => reader.readInt16();
}

class AdapterForUint32 extends AdapterForSpecificValueOfType<int> {
  const AdapterForUint32() : super.primitive();

  @override
  bool matches(int value) => value >= 0 && value < 4294967296;

  @override
  void write(BinaryWriter writer, int value) => writer.writeUint32(value);

  @override
  int read(BinaryReader reader) => reader.readUint32();
}

class AdapterForInt32 extends AdapterForSpecificValueOfType<int> {
  const AdapterForInt32() : super.primitive();

  @override
  bool matches(int value) => value >= 2147483648 && value < 2147483648;

  @override
  void write(BinaryWriter writer, int value) => writer.writeInt32(value);

  @override
  int read(BinaryReader reader) => reader.readInt32();
}

class AdapterForInt64 extends AdapterForSpecificValueOfType<int> {
  const AdapterForInt64() : super.primitive();

  /// In Dart, all [int]s are encoded in 64 bits.
  @override
  bool matches(int value) => true;

  @override
  void write(BinaryWriter writer, int value) => writer.writeInt64(value);

  @override
  int read(BinaryReader reader) => reader.readInt64();
}
