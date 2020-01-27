part of 'adapters.dart';

/// Adapter that encodes a [Set<T>] by just delegating the responsibility to an
/// [AdapterForList<T>].
class AdapterForSet<T> extends UnsafeTypeAdapter<Set<T>> {
  const AdapterForSet();

  @override
  void write(BinaryWriter writer, Set<T> theSet) {
    AdapterForList<T>().write(writer, theSet.toList());
  }

  @override
  Set<T> read(BinaryReader reader) {
    return AdapterForList<T>().read(reader).toSet();
  }
}

/// Adapter that encodes a [Set] of primitive elements that cannot have
/// subclasses (which means we can determine their adapter). Because a [Set]
/// may either contain [null] or not, a single boolean is also saved to
/// indicate that.
class AdapterForPrimitiveSet<T> extends TypeAdapter<Set<T>> {
  const AdapterForPrimitiveSet(this.adapter) : assert(adapter != null);

  final UnsafeTypeAdapter<T> adapter;

  @override
  void write(BinaryWriter writer, Set<T> theSet) {
    writer.writeBool(theSet.contains(null));

    for (final item in theSet.difference({null})) {
      adapter.write(writer, item);
    }
  }

  @override
  Set<T> read(BinaryReader reader) {
    final includeNull = reader.readBool();
    return <T>{
      if (includeNull) null,
      for (; reader.hasAvailableBytes;) adapter.read(reader),
    };
  }
}

class AdapterForSetOfInt extends UnsafeTypeAdapter<Set<int>> {
  const AdapterForSetOfInt();

  @override
  void write(BinaryWriter writer, Set<int> theSet) {
    const AdapterForListOfInt().write(writer, theSet.toList());
  }

  @override
  Set<int> read(BinaryReader reader) {
    return const AdapterForListOfInt().read(reader).toSet();
  }
}
