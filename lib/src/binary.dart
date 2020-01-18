import 'dart:typed_data';

import 'source.dart';

class BytesWriter extends BinaryWriter {
  BytesWriter();

  Uint8List _buffer = Uint8List(256);
  ByteData _byteDataInstance;
  int _offset = 0;

  ByteData get _data {
    _byteDataInstance ??= ByteData.view(_buffer.buffer);
    return _byteDataInstance;
  }

  Uint8List get data => Uint8List.view(_buffer.buffer, 0, _offset);

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

  @override
  void writeUint8(int value) => _data.setUint8(_reserve(1), value);

  @override
  void writeInt8(int value) => _data.setInt8(_reserve(1), value);

  @override
  void writeUint16(int value) => _data.setUint16(_reserve(2), value);

  @override
  void writeInt16(int value) => _data.setInt16(_reserve(2), value);

  @override
  void writeUint32(int value) => _data.setUint32(_reserve(4), value);

  @override
  void writeInt32(int value) => _data.setInt32(_reserve(4), value);

  @override
  void writeUint64(int value) => _data.setUint64(_reserve(8), value);

  @override
  void writeInt64(int value) => _data.setInt64(_reserve(8), value);

  @override
  void writeFloat32(double value) => _data.setFloat32(_reserve(4), value);

  @override
  void writeFloat64(double value) => _data.setFloat64(_reserve(8), value);
}

class BytesReader extends BinaryReader {
  BytesReader(List<int> data) {
    _data = ByteData.view(Uint8List.fromList(data).buffer);
  }

  int _offset = 0;
  ByteData _data;

  @override
  int get availableBytes => _data.lengthInBytes - _offset;

  @override
  int get usedBytes => _data.lengthInBytes;

  @override
  void skip(int bytes) => _reserve(bytes);

  int _reserve(int bytes) {
    final offsetBefore = _offset;
    _offset += bytes;
    return offsetBefore;
  }

  @override
  int readUint8() => _data.getUint8(_reserve(1));

  @override
  int readInt8() => _data.getInt8(_reserve(1));

  @override
  int readUint16() => _data.getUint16(_reserve(2));

  @override
  int readInt16() => _data.getInt16(_reserve(2));

  @override
  int readUint32() => _data.getUint32(_reserve(4));

  @override
  int readInt32() => _data.getInt32(_reserve(4));

  @override
  int readUint64() => _data.getUint64(_reserve(8));

  @override
  int readInt64() => _data.getInt64(_reserve(8));

  @override
  double readFloat32() => _data.getFloat32(_reserve(4));

  @override
  double readFloat64() => _data.getFloat64(_reserve(8));
}

Uint8List serialize(dynamic object) => (BytesWriter()..write(object)).data;
dynamic deserialize(Uint8List data) => BytesReader(data).read();
