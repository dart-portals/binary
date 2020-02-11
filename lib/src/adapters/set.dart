part of 'adapters.dart';

/// Adapter that encodes a [Set<T>] by just delegating the responsibility to an
/// [AdapterForList<T>].
class AdapterForSet<T> extends AdapterFor<Set<T>> {
  const AdapterForSet() : super.primitive();

  @override
  void write(BinaryWriter writer, Set<T> theSet) =>
      writer.write(theSet.toList());

  @override
  Set<T> read(BinaryReader reader) => reader.read<List<T>>().toSet();
}
