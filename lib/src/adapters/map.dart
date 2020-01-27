part of 'adapters.dart';

class AdapterForMapEntry<K, V> extends UnsafeTypeAdapter<MapEntry<K, V>> {
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

class AdapterForMap<K, V> extends UnsafeTypeAdapter<Map<K, V>> {
  const AdapterForMap();

  @override
  void write(BinaryWriter writer, Map<K, V> map) {
    writer.writeUint32(map.length);
    map.entries.forEach((entry) => const AdapterForMapEntry().write);
  }

  @override
  Map<K, V> read(BinaryReader reader) {
    final length = reader.readUint32();
    return Map<K, V>.fromEntries({
      for (var i = 0; i < length; i++) const AdapterForMapEntry().read(reader),
    });
  }
}

class AdapterForMapWithPrimitiveKey<K, V> extends UnsafeTypeAdapter<Map<K, V>> {
  const AdapterForMapWithPrimitiveKey(this.keyAdapter)
      : assert(keyAdapter != null);

  final UnsafeTypeAdapter<K> keyAdapter;

  @override
  void write(BinaryWriter writer, Map<K, V> map) {
    writer.write(map.length);
    map.forEach((key, value) {
      keyAdapter.write(writer, key);
      writer.write(value);
    });
  }

  @override
  Map<K, V> read(BinaryReader reader) {
    final length = reader.readUint32();
    return <K, V>{
      for (var i = 0; i < length; i++)
        keyAdapter.read(reader): reader.read<V>(),
    };
  }
}
