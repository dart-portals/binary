part of 'binary.dart';

/// [AdapterFor]s use the [BinaryReader] when deserializing data.
class BinaryReader {
  BinaryReader(List<int> data) : _limitingData = _LimitingByteData(data) {
    _addLimit(_data.lengthInBytes);
  }

  final _LimitingByteData _limitingData;
  ByteData get _data => _limitingData._data;
  int _reserve(int bytes, int limit) => _limitingData._reserve(bytes, limit);

  final _limitOffsets = <int>[];
  int get _currentLimit => _limitOffsets.last;

  void _addLimit(int length) {
    if (_limitingData._offset + length > _data.lengthInBytes) {
      throw Exception("Limit of an additional $length bytes from current "
          "offset ${_limitingData._offset} would exceed the available buffer, "
          "which has a length of ${_data.lengthInBytes}.");
    }
    _limitOffsets.add(_limitingData._offset + length);
  }

  void _removeLimit() => _limitOffsets.removeLast();

  /// Finds a fitting adapter for the given [value] and then writes it.
  T read<T>() {
    final offsettedTypeId = readUint16();
    final typeId = offsettedTypeId - _reservedTypeIds;
    final adapter = TypeRegistry.findAdapterById(typeId);

    if (adapter == null) {
      // This is an unknown type id. Just assume it's not a primitive adapter
      // (because they cannot be deleted) and skip the number of bytes that
      // it encoded.
      final length = readUint32();
      skip(length);
      return null;
    } else if (adapter.isPrimitive) {
      // Trust the adapter to read exactly the right amount of bytes.
      final data = adapter.read(this);
      return data;
    } else {
      // Make sure the adapter doesn't read more or less bytes than promised.
      final length = readUint32();
      _addLimit(length);
      final data = adapter.read(this);
      if (hasAvailableBytes) {
        throw Exception('Adapter did not read everything that it wrote.');
      }
      _removeLimit();
      return data;
    }
  }

  int get availableBytes => _currentLimit - _limitingData._offset;
  bool get hasAvailableBytes => availableBytes > 0;
  void skip(int bytes) => _reserve(bytes, _currentLimit);

  int readUint8() => _data.getUint8(_reserve(1, _currentLimit));
  int readInt8() => _data.getInt8(_reserve(1, _currentLimit));
  int readUint16() => _data.getUint16(_reserve(2, _currentLimit));
  int readInt16() => _data.getInt16(_reserve(2, _currentLimit));
  int readUint32() => _data.getUint32(_reserve(4, _currentLimit));
  int readInt32() => _data.getInt32(_reserve(4, _currentLimit));
  int readUint64() => _data.getUint64(_reserve(8, _currentLimit));
  int readInt64() => _data.getInt64(_reserve(8, _currentLimit));
  double readFloat32() => _data.getFloat32(_reserve(4, _currentLimit));
  double readFloat64() => _data.getFloat64(_reserve(8, _currentLimit));
}

class _LimitingByteData {
  _LimitingByteData(List<int> data) {
    // Make a defensive copy of the data.
    _data = ByteData.view(Uint8List.fromList(data).buffer);
  }

  int _offset = 0;
  ByteData _data;

  int _reserve(int bytes, int limit) {
    if (_offset + bytes > limit) {
      throw Exception('Adapter tried to read more bytes than it wrote.');
    }

    final offsetBefore = _offset;
    _offset += bytes;
    return offsetBefore;
  }
}
