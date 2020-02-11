part of 'adapters.dart';

class AdapterForNull extends AdapterFor<Null> {
  const AdapterForNull() : super.primitive();
  void write(_, __) {}
  Null read(_) => null;
}

class AdapterForDouble extends AdapterFor<double> {
  const AdapterForDouble() : super.primitive();
  void write(BinaryWriter writer, double value) => writer.writeFloat64(value);
  double read(BinaryReader reader) => reader.readFloat64();
}

class AdapterForDateTime extends AdapterFor<DateTime> {
  const AdapterForDateTime() : super.primitive();

  @override
  void write(BinaryWriter writer, DateTime value) =>
      const AdapterForInt64().write(writer, value.microsecondsSinceEpoch);

  @override
  DateTime read(BinaryReader reader) =>
      DateTime.fromMicrosecondsSinceEpoch(const AdapterForInt64().read(reader));
}

class AdapterForDuration extends AdapterFor<Duration> {
  const AdapterForDuration() : super.primitive();

  @override
  void write(BinaryWriter writer, Duration value) =>
      const AdapterForInt64().write(writer, value.inMicroseconds);

  @override
  Duration read(BinaryReader reader) =>
      Duration(microseconds: const AdapterForInt64().read(reader));
}

class AdapterForRegExp extends AdapterFor<RegExp> {
  const AdapterForRegExp();

  @override
  void write(BinaryWriter writer, RegExp regExp) {
    assert(!regExp.pattern.contains('\0'));
    const AdapterForNullTerminatedString().write(writer, regExp.pattern);
    const AdapterForListOfBool().write(writer, <bool>[
      regExp.isCaseSensitive,
      regExp.isMultiLine,
      regExp.isUnicode,
      regExp.isDotAll,
    ]);
  }

  @override
  RegExp read(BinaryReader reader) {
    final pattern = const AdapterForArbitraryString().read(reader);
    final bools = const AdapterForListOfBool().read(reader);

    return RegExp(
      pattern,
      caseSensitive: bools[0],
      multiLine: bools[1],
      unicode: bools[2],
      dotAll: bools[3],
    );
  }
}

class AdapterForRunes extends AdapterFor<Runes> {
  const AdapterForRunes() : super.primitive();

  @override
  void write(BinaryWriter writer, Runes runes) =>
      const AdapterForNullTerminatedString().write(writer, runes.string);

  @override
  Runes read(BinaryReader reader) =>
      const AdapterForNullTerminatedString().read(reader).runes;
}

class AdapterForStackTrace extends AdapterFor<StackTrace> {
  const AdapterForStackTrace() : super.primitive();

  @override
  void write(BinaryWriter writer, StackTrace stackTrace) =>
      const AdapterForArbitraryString().write(writer, stackTrace.toString());

  @override
  StackTrace read(BinaryReader reader) =>
      StackTrace.fromString(const AdapterForArbitraryString().read(reader));
}
