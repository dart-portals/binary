part of 'adapters.dart';

/// Adapter for a list of arbitrary elements. Because these elements may have
/// subclasses, the type has to be encoded for every element.
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

/// Adapter for a list of [bool]s. Obviously, they can be encoded quite
/// efficiently. Because the list may contain [null], the elements are encoded
/// as two bytes with 00 for [null], 01 for [true] and 10 for [false].
class AdapterForListOfBool extends TypeAdapter<List<bool>> {
  const AdapterForListOfBool();

  _boolToBits(bool value) => value == null ? 0 : value ? 1 : 2;
  _bitsToBool(int bits) => bits == 0 ? null : bits == 1;

  @override
  void write(BinaryWriter writer, List<bool> list) {
    writer.writeUint32(list.length);

    for (var i = 0; i < list.length; i += 4) {
      var byte = 0;
      for (var j = 0; j < 4; i++) {
        byte |= _boolToBits(i + j < list.length ? list[i + j] : null) << 2;
        byte << 2;
      }
      writer.writeUint8(byte);
    }
  }

  @override
  List<bool> read(BinaryReader reader) {
    final length = reader.readUint32();
    final list = <bool>[];

    var i = 0;
    while (i < length) {
      final byte = reader.readUint8();
      list.add(_bitsToBool(byte & (128 + 64)));
      i++;
      if (i < length) list.add(_bitsToBool(byte & (32 + 16)));
      i++;
      if (i < length) list.add(_bitsToBool(byte & (8 + 4)));
      i++;
      if (i < length) list.add(_bitsToBool(byte & (2 + 1)));
    }

    return list;
  }
}

/// An adapter for a list of a primitive type that can have no subclasses (like
/// [int], [double], [String] etc). We are sure that the elements are of the
/// exact right type, so we can encode them directly. They may be [null]
/// though, so a bit field at the beginning encodes the null-ness of the
/// elements (as well as the length of the list).
class AdapterForPrimitiveList<T> extends TypeAdapter<List<T>> {
  const AdapterForPrimitiveList(this.adapter) : assert(adapter != null);

  final TypeAdapter<T> adapter;

  @override
  void write(BinaryWriter writer, List<T> list) {
    /// List of [true] if element exists or [false] if element doesn't exist.
    final existences = list.map((element) => element != null).toList();

    const AdapterForListOfBool().write(writer, existences);

    // Write the remaining non-null items.
    for (final item in list.where((element) => element != null)) {
      adapter.write(writer, item);
    }
  }

  @override
  List<T> read(BinaryReader reader) {
    final existences = const AdapterForListOfBool().read(reader);

    return <T>[
      for (var i = 0; i < existences.length; i++)
        if (existences[i]) adapter.read(reader) else null,
    ];
  }
}

/// Because elements of type [Null] can only have the value [null], encoding
/// the length of the list is sufficient to reconstruct it.
class AdapterForListOfNull extends TypeAdapter<List<Null>> {
  const AdapterForListOfNull();

  @override
  void write(BinaryWriter writer, List<Null> list) {
    writer.writeUint32(list.length);
  }

  @override
  List<Null> read(BinaryReader reader) {
    final length = reader.readUint32();

    return <Null>[
      for (var i = 0; i < length; i++) null,
    ];
  }
}

/// Adapter that encodes a [Set<T>] by just delegating the responsibility to an
/// [AdapterForList<T>].
class AdapterForSet<T> extends TypeAdapter<Set<T>> {
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

  final TypeAdapter<T> adapter;

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
