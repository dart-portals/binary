part of 'adapters.dart';

class AdapterForTrueBool extends AdapterForSpecificValueOfType<bool> {
  const AdapterForTrueBool() : super.primitive();

  @override
  bool matches(bool value) => value;

  @override
  void write(BinaryWriter writer, bool value) {}

  @override
  bool read(BinaryReader reader) => true;
}

class AdapterForFalseBool extends AdapterForSpecificValueOfType<bool> {
  const AdapterForFalseBool() : super.primitive();

  @override
  bool matches(bool value) => !value;

  @override
  void write(BinaryWriter writer, bool value) {}

  @override
  bool read(BinaryReader reader) => false;
}
