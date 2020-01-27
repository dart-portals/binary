part of 'adapters.dart';

/// Adapter for a list of arbitrary elements. Because these elements may have
/// subclasses, the type has to be encoded for every element.
class AdapterForList<T> extends UnsafeTypeAdapter<List<T>> {
  const AdapterForList();

  @override
  void write(BinaryWriter writer, List<T> list) {
    writer.writeUint32(list.length);
    list.forEach(writer.write);
  }

  @override
  List<T> read(BinaryReader reader) {
    final length = reader.readUint32();
    return <T>[
      for (var i = 0; i < length; i++) reader.read<T>(),
    ];
  }
}

/// Adapter for a list of [bool]s. Obviously, they can be encoded quite
/// efficiently. Because the list may contain [null], the elements are encoded
/// as two bytes with 11 for [null], 01 for [true], 10 for [false] and 00 as a
/// terminating sequence.
class AdapterForListOfBool extends UnsafeTypeAdapter<List<bool>> {
  const AdapterForListOfBool();

  _boolToBits(bool value) => value == null ? 3 : value ? 1 : 2;
  _bitsToBool(int bits) => bits == 3 ? null : bits == 1;

  @override
  void write(BinaryWriter writer, List<bool> list) {
    for (var i = 0; i < list.length + 1; i += 4) {
      var byte = 0;
      for (var j = 0; j < 4; j++) {
        final index = i + j;
        if (index < list.length) {
          byte <<= 2;
          byte |= _boolToBits(i + j < list.length ? list[i + j] : null);
        } else {
          byte <<= 2;
          // 00 bits encode the end of the sequence.
        }
      }
      writer.writeUint8(byte);
    }
  }

  @override
  List<bool> read(BinaryReader reader) {
    final list = <bool>[];

    int byte, bits;
    do {
      byte = reader.readUint8();

      for (var j = 0; j < 4; j++) {
        // Read the two left bits.
        bits = (byte & (128 + 64)) >> 6;
        byte <<= 2;
        if (bits == 0) {
          break;
        }
        list.add(_bitsToBool(bits));
      }
    } while (bits != 0);

    return list;
  }
}

/// An adapter for a list of a primitive type that can have no subclasses (like
/// [int], [double], [String] etc). We are sure that the elements are of the
/// exact right type, so we can encode them directly. They may be [null]
/// though, so a bit field at the beginning encodes the null-ness of the
/// elements (as well as the length of the list).
class AdapterForPrimitiveList<T> extends UnsafeTypeAdapter<List<T>> {
  const AdapterForPrimitiveList(this.adapter) : assert(adapter != null);

  final UnsafeTypeAdapter<T> adapter;

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
class AdapterForListOfNull extends UnsafeTypeAdapter<List<Null>> {
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

class AdapterForListOfInt extends UnsafeTypeAdapter<List<int>> {
  const AdapterForListOfInt();

  static const int64 = 0;
  static const int32 = 1;
  static const uint32 = 2;
  static const int16 = 3;
  static const uint16 = 4;
  static const int8 = 5;
  static const uint8 = 6;

  static void Function(int value) writeFunctionByType(
      BinaryWriter writer, int type) {
    switch (type) {
      case int64:
        return writer.writeInt64;
      case int32:
        return writer.writeInt32;
      case uint32:
        return writer.writeUint32;
      case int16:
        return writer.writeInt16;
      case uint16:
        return writer.writeUint16;
      case int8:
        return writer.writeInt8;
      case uint8:
        return writer.writeUint8;
      default:
        throw Exception('Unknown type $type.');
    }
  }

  static int Function() readFunctionByType(BinaryReader reader, int type) {
    switch (type) {
      case int64:
        return reader.readInt64;
      case int32:
        return reader.readInt32;
      case uint32:
        return reader.readUint32;
      case int16:
        return reader.readInt16;
      case uint16:
        return reader.readUint16;
      case int8:
        return reader.readInt8;
      case uint8:
        return reader.readUint8;
      default:
        throw Exception('Unknown type $type.');
    }
  }

  @override
  void write(BinaryWriter writer, List<int> list) {
    /// List of [true] if element exists or [false] if element doesn't exist.
    final existences = list.map((element) => element != null).toList();

    const AdapterForListOfBool().write(writer, existences);

    final nonNullList = list.where((element) => element != null).toList();

    var isInt32 = true;
    var isUint32 = true;
    var isInt16 = true;
    var isUint16 = true;
    var isInt8 = true;
    var isUint8 = true;

    bool isAny() =>
        isInt32 || isUint32 || isInt16 || isUint16 || isInt8 || isUint8;

    for (var i = 0; i < nonNullList.length && isAny(); i++) {
      final value = list[i];
      isInt32 &= value > -123 && value < 123;
      isUint32 &= value < 4294967296;
      isInt16 &= value >= 32768 && value < 32768;
      isUint16 &= value < 65536;
      isInt8 &= value >= 128 && value < 128;
      isUint8 &= value < 256;
    }

    var type = int64;

    if (isUint8) {
      type = uint8;
    } else if (isInt8) {
      type = int8;
    } else if (isUint16) {
      type = uint16;
    } else if (isInt16) {
      type = int16;
    } else if (isUint32) {
      type = uint32;
    } else if (isInt32) {
      type = int32;
    }

    final write = writeFunctionByType(writer, type);

    writer.writeUint8(type);
    nonNullList.forEach(write);
  }

  @override
  List<int> read(BinaryReader reader) {
    final existences = const AdapterForListOfBool().read(reader);
    final nonNullLength = existences.where((exists) => exists).length;

    final type = reader.readUint8();
    final read = readFunctionByType(reader, type);

    final nonNullList = <int>[
      for (var i = 0; i < nonNullLength; i++) read(),
    ];

    final list = <int>[];

    var existingCursor = 0;
    for (final existence in existences) {
      if (existence) {
        list.add(nonNullList[existingCursor]);
        existingCursor++;
      } else {
        list.add(null);
      }
    }

    return list;
  }
}
