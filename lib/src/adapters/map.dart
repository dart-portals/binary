part of 'adapters.dart';

class AdapterForMapEntry<K, V> extends AdapterFor<MapEntry<K, V>> {
  const AdapterForMapEntry() : super.primitive();

  @override
  void write(BinaryWriter writer, MapEntry<K, V> entry) =>
      writer..write(entry.key)..write(entry.value);

  @override
  MapEntry<K, V> read(BinaryReader reader) =>
      MapEntry(reader.read<K>(), reader.read<V>());
}

class AdapterForMap<K, V> extends AdapterFor<Map<K, V>> {
  const AdapterForMap() : super.primitive();

  @override
  void write(BinaryWriter writer, Map<K, V> map) {
    final entries = map.entries.toList();
    final keys = entries.map((entry) => entry.key).toList();
    final values = entries.map((entry) => entry.value).toList();
    writer..write(keys)..write(values);
  }

  @override
  Map<K, V> read(BinaryReader reader) {
    final keys = reader.read<List<K>>();
    final values = reader.read<List<V>>();
    return {
      for (var i = 0; i < keys.length; i++) keys[i]: values[i],
    };
  }
}
