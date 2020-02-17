part of 'binary.dart';

/// [AdapterFor]s use the [BinaryWriter] when serializing data.
class BinaryWriter {
  /// We make use of the [_ResizingByteData] defined below to get a [ByteData]
  /// where we don't have to care about increasing the length anymore.
  final _resizingData = _ResizingByteData();
  ByteData get _data => _resizingData._data;
  Uint8List get _dataAsUint8List => Uint8List.view(_data.buffer, 0, _offset);
  int get _offset => _resizingData._offset;
  int _reserve(int bytes) => _resizingData._reserve(bytes);

  /// Finds a fitting adapter for the given [value] and then writes it.
  void write<T>(T value) {
    final adapter = TypeRegistry.findAdapterByValue<T>(value);
    final typeId = TypeRegistry.findIdOfAdapter(adapter);

    // We're not sure that the deserializer knows all the types – deserializing
    // might happen on another device, the user might downgrade the app or
    // developers might remove types in the future.
    // Either way, we need to tell the deserializer how many bytes to skip when
    // encountering an unknown type id. That's why we save the length of the
    // serialized content parts in the binary format.
    // That also means we can prevent a single adapter gone rogue from
    // corrupting our binary format – errors are contained locally!
    // So, how do we save the number of bytes that an adapter wrote in front of
    // the actual bytes? We just leave a little space for the length to be
    // written into and then continue serializing. When the adapter finishes,
    // we calculate the length and fill it in at the position we left free.
    //
    // 1. Writing type id: 12
    // 2. Leaving space:   12 ....
    // 3. Running adapter: 12 .... 3174543458
    // 4. Saving length:   12 0010 3174543458
    //
    // This is how the format looks like when finished:
    // type id | content length | content
    // 2 bytes | 4 bytes        | n bytes

    // Note: The above does not apply to some primitive adapters which extend
    // [UnsafeTypeAdapter]. They exist purely for efficiency reason.

    writeUint16(typeId + _reservedTypeIds);

    if (adapter.isPrimitive) {
      adapter.write(this, value);
    } else {
      _reserve(4); // Reserve bytes for the length.
      final start = _offset;

      adapter.write(this, value);

      final end = _offset;
      final length = end - start;
      _data.setUint32(start - 4, length);
    }
  }

  void writeUint8(int value) {
    final offset = _reserve(1);
    _data.setUint8(offset, value);
  }

  void writeInt8(int value) {
    final offset = _reserve(1);
    _data.setInt8(offset, value);
  }

  void writeUint16(int value) {
    final offset = _reserve(2);
    _data.setUint16(offset, value);
  }

  void writeInt16(int value) {
    final offset = _reserve(2);
    _data.setInt16(offset, value);
  }

  void writeUint32(int value) {
    final offset = _reserve(4);
    _data.setUint32(offset, value);
  }

  void writeInt32(int value) {
    final offset = _reserve(4);
    _data.setInt32(offset, value);
  }

  void writeUint64(int value) {
    final offset = _reserve(8);
    _data.setUint64(offset, value);
  }

  void writeInt64(int value) {
    final offset = _reserve(8);
    _data.setInt64(offset, value);
  }

  void writeFloat32(double value) {
    final offset = _reserve(4);
    _data.setFloat32(offset, value);
  }

  void writeFloat64(double value) {
    final offset = _reserve(8);
    _data.setFloat64(offset, value);
  }

  void debugDump() => print(_dataAsUint8List);
}

class _ResizingByteData {
  Uint8List _buffer = Uint8List(256);
  ByteData _byteDataInstance;
  int _offset = 0;

  ByteData get _data {
    _byteDataInstance ??= ByteData.view(_buffer.buffer);
    return _byteDataInstance;
  }

  /// Makes sure that [bytes] bytes can be written to the buffer and returns an
  /// offset where to write those bytes.
  int _reserve(int bytes) {
    if (_buffer.length - _offset < bytes) {
      // We will create a list in the range of 2-4 times larger than required.
      var newSize = _pow2roundup((_offset + bytes) * 2);
      var newBuffer = Uint8List(newSize);
      newBuffer.setRange(0, _offset, _buffer);
      _buffer = newBuffer;
      _byteDataInstance = null;
    }

    final offsetBefore = _offset;
    _offset += bytes;
    return offsetBefore;
  }

  static int _pow2roundup(int x) {
    assert(x > 0);
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }
}
