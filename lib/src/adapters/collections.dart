part of 'adapters.dart';

class AdapterForList<T> extends TypeAdapter<List<T>> {
  const AdapterForList();

  @override
  void write(BinaryWriter writer, List<T> list) {
    writer.writeLength(list.length);
    list.forEach(writer.write);
  }

  @override
  List<T> read(BinaryReader reader) {
    final length = reader.readLength();
    return <T>[
      for (var i = 0; i < length; i++) reader.read<T>(),
    ];
  }
}

class AdapterForPrimitiveList<T> extends TypeAdapter<List<T>> {
  const AdapterForPrimitiveList(this.adapter) : assert(adapter != null);

  final TypeAdapter<T> adapter;

  @override
  void write(BinaryWriter writer, List<T> list) {
    writer.writeLength(list.length);
    for (final item in list) {
      adapter.write(writer, item);
    }
  }

  @override
  List<T> read(BinaryReader reader) {
    final length = reader.readLength();
    return <T>[
      for (var i = 0; i < length; i++) adapter.read(reader),
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
    writer.writeLength(map.length);
    map.entries.forEach((entry) => const AdapterForMapEntry().write);
  }

  @override
  Map<K, V> read(BinaryReader reader) {
    final length = reader.readLength();
    return Map<K, V>.fromEntries({
      for (var i = 0; i < length; i++) const AdapterForMapEntry().read(reader),
    });
  }
}

class AdapterForMapWithPrimitiveKey<K, V> extends TypeAdapter<Map<K, V>> {
  const AdapterForMapWithPrimitiveKey(this.keyAdapter)
      : assert(keyAdapter != null);

  final TypeAdapter<K> keyAdapter;

  @override
  void write(BinaryWriter writer, Map<K, V> map) {
    writer.writeLength(map.length);
    map.forEach((key, value) {
      keyAdapter.write(writer, key);
      writer.write(value);
    });
  }

  @override
  Map<K, V> read(BinaryReader reader) {
    final length = reader.readLength();
    return <K, V>{
      for (var i = 0; i < length; i++)
        keyAdapter.read(reader): reader.read<V>(),
    };
  }
}
