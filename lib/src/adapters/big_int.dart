part of 'adapters.dart';

class AdapterForBigInt extends AdapterFor<BigInt> {
  const AdapterForBigInt() : super.primitive();

  @override
  void write(BinaryWriter writer, BigInt value) {
    final bits = <bool>[value.isNegative];
    value = value.abs();

    while (value > BigInt.zero) {
      bits.add(value % BigInt.two == BigInt.one);
      value ~/= BigInt.two;
    }

    const AdapterForListOfBool().write(writer, bits);
  }

  @override
  BigInt read(BinaryReader reader) {
    final bits = const AdapterForListOfBool().read(reader);
    final isNegative = bits.removeAt(0);

    var value = BigInt.zero;
    while (bits.isNotEmpty) {
      value *= BigInt.two;
      value += bits.removeAt(0) ? BigInt.one : BigInt.zero;
    }

    return value * (isNegative ? BigInt.from(-1) : BigInt.one);
  }
}
