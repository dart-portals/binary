## Binary serializer

The binary serializer is used for serializing Dart objects from and to binary data.
It's inspired by Protobuf.

There are three typical use cases for this package.

To make custom classes serializable, create `TypeAdapter`s for them and register them at the `TypeRegistry`.
`TypeAdapter`s should be able to serialize and deserialize data given a `BinaryWriter` or `BinaryReader`.

To actually serialize and deserialize objects, just call `binary.serialize(…)` or `binary.deserialize(…)`.

### Features

* Can encode any class, including generic classes. Classes need to be registered before though.
* Serialization is safe. No single adapter can corrupt the binary format. Misbehaving adapters will be called out during runtime, making the serialization process easily debuggable.
* Future- and backwards-compatible. Unknown types will just be decoded to null.

### Behind the scenes: How is data encoded

When encoding a value with a fitting adapter, two steps happen:

* The id that the adapter was registered with gets encoded.
* The adapter is used to encode the value.

Type adapters encode data. Here's an example of an adapter:

```dart
@BinaryType(legacyFields: {2})
class MyClass<T> {
  MyClass({@required this.id, @required this.someNumbers});

  @BinaryField(0)
  final String id;

  @BinaryField(1)
  final Set<T> someNumbers
}

class AdapterForMyClass<T> extends TypeAdapter<MyClass<T>> {
  const AdapterForMyClass();

  @override
  void write(BinaryWriter writer, MyClass<T> obj) {
    writer
      ..writeNumberOfFields(2)
      ..writeFieldId(0)
      ..write(obj.id)
      ..writeFieldId(1)
      ..write(obj.someNumbers);
  }

  @override
  MyClass<T> read(BinaryReader reader) {
    final numberOfFields = reader.readNumberOfFields();
    final fields = <int, dynamic>{
      for (var i = 0; i < numberOfFields; i++)
        reader.readFieldId(): reader.read(),
    };

    return MyClass<T>(
      id: fields[0],
      someNumbers: fields[1],
    );
  }
}

AdapterForMyClass().registerForId(0);
```

The encoded form of `MyClass(id: 'hey', numbers: [1,2])` would look like this:

(All ids are offsetted)

```
 8  0 .............. id of AdapterForMyClass
 0  2 ..............   number of fields
 0  0 ..............   field #0
 7 f9 ..............     id of AdapterForString
 0  0 0 3 ..........       length of String
68 .................       h
65 .................       e
79 .................       y
 0  1 ..............   field #1
 7 e7 ..............     id of AdapterForSet<int>
 7 eb ..............       id of AdapterForPrimitiveList<int>
 0  0 0 2 ..........         length of List
3f f0 0 0 0 0 0 0 ..           1
40  0 0 0 0 0 0 0 ..           2

Encoded:
8 0 0 2 0 0 7 f9 0 0 0 3 68 65 79 0 1 7 e7 7 eb 0 0 0 2 3f f0 0 0 0 0 0 0 40 0 0 0 0 0 0 0
```
