part of 'adapters.dart';

class AdapterForList<T> extends TypeAdapter<List<T>> {
  const AdapterForList();

  @override
  void write(BinaryWriter writer, List<T> list) {
    list.forEach(writer.write);
  }

  @override
  List<T> read(BinaryReader reader) {
    return <T>[
      for (; reader.hasAvailableBytes;) reader.read<T>(),
    ];
  }
}

class AdapterForPrimitiveList<T> extends TypeAdapter<List<T>> {
  const AdapterForPrimitiveList(this.adapter) : assert(adapter != null);

  final TypeAdapter<T> adapter;

  @override
  void write(BinaryWriter writer, List<T> list) {
    for (final item in list) {
      adapter.write(writer, item);
    }
  }

  @override
  List<T> read(BinaryReader reader) {
    return <T>[
      for (; reader.hasAvailableBytes;) adapter.read(reader),
    ];
  }
}

class AdapterForSet<T> extends TypeAdapter<Set<T>> {
  const AdapterForSet();

  @override
  void write(BinaryWriter writer, Set<T> theSet) =>
      writer.write(theSet.toList());

  @override
  Set<T> read(BinaryReader reader) => reader.read<List<T>>().toSet();
}

class AdapterForMapEntry<K, V> extends TypeAdapter<MapEntry<K, V>> {
  const AdapterForMapEntry();

  @override
  void write(BinaryWriter writer, MapEntry<K, V> entry) {
    writer..write(entry.key)..write(entry.value);
  }

  @override
  MapEntry<K, V> read(BinaryReader reader) {
    return MapEntry(reader.read<K>(), reader.read<V>());
  }
}

class AdapterForMap<K, V> extends TypeAdapter<Map<K, V>> {
  const AdapterForMap();

  @override
  void write(BinaryWriter writer, Map<K, V> map) {
    map.entries.forEach((entry) => const AdapterForMapEntry().write);
  }

  @override
  Map<K, V> read(BinaryReader reader) {
    return Map<K, V>.fromEntries({
      for (; reader.hasAvailableBytes;) const AdapterForMapEntry().read(reader),
    });
  }
}

class AdapterForMapWithPrimitiveKey<K, V> extends TypeAdapter<Map<K, V>> {
  const AdapterForMapWithPrimitiveKey(this.keyAdapter)
      : assert(keyAdapter != null);

  final TypeAdapter<K> keyAdapter;

  @override
  void write(BinaryWriter writer, Map<K, V> map) {
    map.forEach((key, value) {
      keyAdapter.write(writer, key);
      writer.write(value);
    });
  }

  @override
  Map<K, V> read(BinaryReader reader) {
    return <K, V>{
      for (; reader.hasAvailableBytes;)
        keyAdapter.read(reader): reader.read<V>(),
    };
  }
}
