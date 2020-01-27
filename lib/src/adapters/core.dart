part of 'adapters.dart';

// Adapters for types of the dart:core library minus collection types.

extension PrimitiveTypesWriter on BinaryWriter {
  void writeBool(bool value) => writeUint8(value ? 1 : 0);
  void writeDouble(double value) => writeFloat64(value);
  void writeInt(int value) => writeInt64(value);

  void writeString(String value) {
    // Because utf8 bytes cannot be 0, we can encode null-terminated strings.
    final bytes = utf8.encode(value);
    bytes.forEach(writeUint8);
    writeUint8(0);
  }
}

extension PrimitiveTypesReader on BinaryReader {
  bool readBool() => readUint8() != 0;
  double readDouble() => readFloat64();
  int readInt() => readInt64();

  String readString() {
    final bytes = <int>[];
    while (true) {
      final byte = readUint8();

      if (byte == 0) {
        return utf8.decode(bytes);
      } else {
        bytes.add(byte);
      }
    }
  }
}

class AdapterForNull extends UnsafeTypeAdapter<Null> {
  const AdapterForNull();
  void write(_, __) {}
  Null read(_) => null;
}

class AdapterForBool extends UnsafeTypeAdapter<bool> {
  const AdapterForBool();
  void write(BinaryWriter writer, bool value) => writer.writeBool(value);
  bool read(BinaryReader reader) => reader.readBool();
}

class AdapterForDouble extends UnsafeTypeAdapter<double> {
  const AdapterForDouble();
  void write(BinaryWriter writer, double value) => writer.writeDouble(value);
  double read(BinaryReader reader) => reader.readDouble();
}

class AdapterForInt extends UnsafeTypeAdapter<int> {
  const AdapterForInt();
  void write(BinaryWriter writer, int value) => writer.writeInt(value);
  int read(BinaryReader reader) => reader.readInt();
}

class AdapterForString extends UnsafeTypeAdapter<String> {
  const AdapterForString();
  void write(BinaryWriter writer, String value) => writer.writeString(value);
  String read(BinaryReader reader) => reader.readString();
}

class AdapterForBigInt extends UnsafeTypeAdapter<BigInt> {
  const AdapterForBigInt();

  @override
  void write(BinaryWriter writer, BigInt value) =>
      writer.writeString(value.toRadixString(36));

  @override
  BigInt read(BinaryReader reader) =>
      BigInt.parse(reader.readString(), radix: 36);
}

class AdapterForDateTime extends UnsafeTypeAdapter<DateTime> {
  const AdapterForDateTime();

  @override
  void write(BinaryWriter writer, DateTime value) =>
      writer.writeInt(value.microsecondsSinceEpoch);

  @override
  DateTime read(BinaryReader reader) =>
      DateTime.fromMicrosecondsSinceEpoch(reader.readInt());
}

class AdapterForDuration extends UnsafeTypeAdapter<Duration> {
  const AdapterForDuration();

  @override
  void write(BinaryWriter writer, Duration value) =>
      writer.writeInt(value.inMicroseconds);

  @override
  Duration read(BinaryReader reader) =>
      Duration(microseconds: reader.readInt());
}

class AdapterForRegExp extends TypeAdapter<RegExp> {
  const AdapterForRegExp();

  @override
  void write(BinaryWriter writer, RegExp regExp) {
    writer
      ..writeString(regExp.pattern)
      ..writeBool(regExp.isCaseSensitive)
      ..writeBool(regExp.isMultiLine)
      ..writeBool(regExp.isUnicode)
      ..writeBool(regExp.isDotAll);
  }

  @override
  RegExp read(BinaryReader reader) {
    return RegExp(
      reader.readString(),
      caseSensitive: reader.readBool(),
      multiLine: reader.readBool(),
      unicode: reader.readBool(),
      dotAll: reader.readBool(),
    );
  }
}

class AdapterForRunes extends UnsafeTypeAdapter<Runes> {
  const AdapterForRunes();

  @override
  void write(BinaryWriter writer, Runes runes) =>
      writer.writeString(runes.string);

  @override
  Runes read(BinaryReader reader) => reader.readString().runes;
}

class AdapterForStackTrace extends UnsafeTypeAdapter<StackTrace> {
  const AdapterForStackTrace();

  @override
  void write(BinaryWriter writer, StackTrace stackTrace) =>
      writer.writeString(stackTrace.toString());

  @override
  StackTrace read(BinaryReader reader) =>
      StackTrace.fromString(reader.readString());
}
