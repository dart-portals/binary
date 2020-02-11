import 'package:meta/meta.dart';

import 'binary.dart';

@BinaryType(legacyFields: {2})
class MyClass<T> {
  MyClass({
    @required this.id,
    @required this.someNumbers,
    @required this.someOther,
  });

  @BinaryField(0)
  final String id;

  @BinaryField(1)
  final Set<T> someNumbers;

  @BinaryField(2)
  final Map<int, bool> someOther;

  String toString() => 'MyClass($id, $someNumbers, $someOther)';
}

class AdapterForMyClass<T> extends AdapterFor<MyClass<T>> {
  const AdapterForMyClass();

  @override
  void write(BinaryWriter writer, MyClass<T> obj) {
    writer
      ..writeFieldId(0)
      ..write(obj.id)
      ..writeFieldId(1)
      ..write(obj.someNumbers)
      ..writeFieldId(2)
      ..write(obj.someOther);
  }

  @override
  MyClass<T> read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (; reader.hasAvailableBytes;) reader.readFieldId(): reader.read(),
    };

    return MyClass<T>(
      id: fields[0],
      someNumbers: fields[1],
      someOther: fields[2],
    );
  }
}

void main() {
  TypeRegistry
    ..registerLegacyTypes({1})
    ..registerAdapters({
      0: AdapterForMyClass<int>(),
    });

  final data = binary.serialize(MyClass(
    id: 'foo',
    someNumbers: {1, 2, null},
    someOther: {1: true, 2: true, 3: null, 4: true, 5: false, 6: true, 7: true},
  ));
  print('Serialized to $data');
  print(binary.deserialize(data));
  print(data.map((byte) => byte.toRadixString(16)).join(' '));
}
