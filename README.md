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
* Future- and backwards-compatible. Unknown types will just be decoded to `null`.

### I'm writing a custom `TypeAdapter`. Any guidance?

You should (almost certainly) be extending `TypeAdapter`, not `UnsafeTypeAdapter`.  
If you extend `UnsafeTypeAdapter`, the adapter should be finalized (as in future and backwards compatible and no bugs) – otherwise whole blocks of data could get corrupted. Also, you can never delete the type anymore.

If you created an adapter that can encode any subclass of a class (which either means, it's a class with a private constructor that no one can extend directly or you know all subclasses), you may register it with `TypeRegistry.registerAdapter(id, adapter, suppressWarningsForSubtype: true)` to ensure that no warning is shown to the developer in debug mode.

If you're writing an adapter for a package (library):

- If you're using code generation to create the adapter, make sure to include the generated file in the package.
- You should give your adapter a negative type id to not interfere with the adapters created by the end-user. File a PR for reserving a type id in the [table of reserved type ids](table_of_type_ids.md).

### Behind the scenes: Searching for the right adapter

Adapters are stored in a tree, like the following:

```
root node for objects to serialize
├─ virtual node for Iterable<Object>
│  ├─ AdapterForRunes
│  │  └─ AdapterForNull
│  ├─ AdapterForList<Object>
│  │  ├─ AdapterForListOfBool
│  │  │  └─ AdapterForListOfNull
│  │  ├─ AdapterForListOfInt
│  │  │  └─ AdapterForUint8List
│  │  ├─ AdapterForPrimitiveList<double>
│  │  └─ AdapterForPrimitiveList<String>
│  └─ AdapterForSet<Object>
│     ├─ AdapterForSetOfInt
│     │  └─ AdapterForPrimitiveSet<Null>
│     ├─ AdapterForSet<bool>
│     │  └─ AdapterForPrimitiveSet<Null>
│     ├─ AdapterForPrimitiveSet<double>
│     └─ AdapterForPrimitiveSet<String>
├─ virtual node for int
│  ├─ AdapterForUint8
│  ├─ AdapterForInt8
│  ├─ AdapterForUint16
│  ├─ AdapterForInt16
│  ├─ AdapterForUint32
│  ├─ AdapterForInt32
│  └─ AdapterForInt64
├─ virtual node for bool
│  ├─ AdapterForTrueBool
│  └─ AdapterForFalseBool
├─ virtual node for String
│  ├─ AdapterForStringWithoutNullByte
│  └─ AdapterForArbitraryString
├─ AdapterForDouble
├─ AdapterForBigInt
├─ AdapterForDateTime
├─ AdapterForDuration
├─ AdapterForRegExp
├─ AdapterForStackTrace
├─ AdapterForMapEntry<Object, Object>
└─ AdapterForMap<Object, Object>
   ├─ AdapterForMapWithPrimitiveKey<double, Object>
   ├─ AdapterForMapWithPrimitiveKey<int, Object>
   └─ AdapterForMapWithPrimitiveKey<String, Object>
```

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

The encoded form of `MyClass(id: 'foo', numbers: [1,2])` would look like this:

(All ids are offsetted)

```
128   0 ............. id of AdapterForMyClass
  0   0   0  23 ..... number of bytes written by adapter
  0   0 .............   field #0
127 228 .............     id of AdapterForNullTerminatedString
102 .................       f
111 .................       o
111 .................       o
  0 .................       \0
  0   1 .............   field #1
127 241 .............     id of AdapterForListOfInt
 88   6 .............       data of AdapterForListOfBool containing
                            [true, true, false] (whether elements are non-null)
  1 .................         1
  2 .................         2

Encoded:
80 0 0 0 0 17 0 0 7f e4 66 6f 6f 0 0 1 7f f1 58 6 1 2 0 2 7f f6 5d 99 40
```
