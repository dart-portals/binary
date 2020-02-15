import 'binary.dart';

@BinaryType(legacyFields: {3})
class MyClass<T> {
  MyClass({
    this.someItems,
    this.someMappedInts,
    this.pointer,
  });

  @BinaryField(0)
  final Set<T> someItems;

  @BinaryField(1)
  final Map<int, bool> someMappedInts;

  @BinaryField(2)
  final MyClass<String> pointer;

  String toString() => 'MyClass($someItems, $someMappedInts, $pointer)';
}

class AdapterForMyClass<T> extends AdapterFor<MyClass<T>> {
  const AdapterForMyClass();

  @override
  void write(BinaryWriter writer, MyClass<T> obj) {
    writer
      ..writeFieldId(0)
      ..write(obj.someItems)
      ..writeFieldId(1)
      ..write(obj.someMappedInts)
      ..writeFieldId(2)
      ..write(obj.pointer);
  }

  @override
  MyClass<T> read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (; reader.hasAvailableBytes;) reader.readFieldId(): reader.read(),
    };

    return MyClass<T>(
      someItems: fields[0],
      someMappedInts: fields[1],
      pointer: fields[2],
    );
  }
}

void main() {
  TypeRegistry
    ..registerLegacyTypes({1})
    ..registerAdapters({
      0: AdapterForMyClass<int>(),
      2: AdapterForMyClass<String>(),
    });

  final data = binary.serialize(MyClass(
    someItems: {1, null, 2},
    pointer: MyClass(
      someMappedInts: {1: true, 2: true, 3: null, 4: true, 5: false, 6: true},
    ),
  ));
  print('Serialized to $data');
  print(binary.deserialize(data));
}
