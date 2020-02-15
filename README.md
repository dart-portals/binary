## Binary serializer

The binary serializer is used for serializing Dart objects from and to binary data.
It's inspired by Protobuf.

There are two typical use cases for this package:

- To make custom classes serializable, create `TypeAdapter`s for them (or let a code generator create them) and register them at the `TypeRegistry`. `TypeAdapter`s should be able to serialize and deserialize data given a `BinaryWriter` or `BinaryReader`.
- To actually serialize and deserialize objects, just call `binary.serialize(…)` or `binary.deserialize(…)`.

### Features

* Can encode objects of any type, including generics. Types need to be registered before though.
* Serialization is safe. No single adapter can corrupt the binary format. Misbehaving adapters will be called out during runtime, making the serialization process easily debuggable.
* Future- and backwards-compatible. Unknown types will just be decoded to `null`.

### I'm writing a custom `TypeAdapter`. Any guidance?

You should be extending `TypeAdapter`. Then, register it:

```dart
AdapterForMyClass().register(someId); // some id >= 0
```

If you created an adapter that can encode any subclass of a class (which means you know all subclasses), you can tell the registry that:

```dart
AdapterForMyClass().registerAdapter(someId, suppressWarningsForSubtype: true);
```

No warning is shown to the developer in debug mode.

You'll most certainly need to register multiple adapters. It's recommended to do that in a map, like this:

```dart
TypeRegistry.registerAdapters({
  0: AdapterForSomeType(),
  1: AdapterForOtherType(),
  2: AdapterForList<SomeType>(),
});
```

If you want to encode data differently not based on the type but on the value, you can implement multiple `AdapterForSpecificValueOfType<MyType>`.
In contrast to normal `TypeAdapter`s, they should also implement `bool matches(MyType obj)`.
You can then register them like this:

```dart
TypeRegistry.registerVirtualNode(AdapterNode<MyType>.virtual());
TypeRegistry.registerAdapters({
  0: AdapterForSpecificValuesOfMyType(),
  1: AdapterForOtherValuesOfMyType(),
  2: FallbackAdapterForMyType(),
});
```

If you remove an adapter, you shouldn't reuse the type id in the future.
Data that was serialized with the removed adapter deserializes to `null`.
To make sure that the type id doesn't get reused, you can also tell the type registry to throw an error if an adapter with the same id is registered:

```dart
TypeRegistry.registerLegacyTypes({4, 9, 10});
```

#### If you're writing an adapter for a package (library):

If you're using code generation to create the adapter, make sure to include the generated file in the package. You don't want to force users to run `pub run build_runner build`.

You should give your adapter a negative type id to not interfere with the adapters created by the end-user. File a PR for reserving a type id in the [table of reserved type ids](table_of_type_ids.md).

### Behind the scenes: Searching for the right adapter

Adapters are stored in a tree, like the following:

```
root node for objects to serialize
├─ virtual node for Iterable<Object>
│  ├─ AdapterForRunes
│  │  └─ AdapterForNull
│  └─ ...
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
└─ ...
```

Additionally, the `TypeRegistry` contains a map of shortcuts from types to nodes in the tree.

### Behind the scenes: How is data encoded

When encoding a value with a fitting adapter, three steps happen:

* The id that the adapter was registered for gets encoded.
* The adapter is used to encode the value.
* For non-primitive adapters, the length of the encoding is saved.

Let's look at an example!

Here's an interesting class:

```dart
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
```

The `AdapterForMyClass<T>` class could get automatically generated.
The registration code looks like the following:

```dart
TypeRegistry
  ..registerLegacyTypes({1})
  ..registerAdapters({
    0: AdapterForMyClass<int>(),
    2: AdapterForMyClass<String>(),
  });
```

This is a sample instance of our class:

```dart
final sample = MyClass(
  someItems: {1, null, 2},
  pointer: MyClass(
    someMappedInts: {1: true, 2: true, 3: null, 4: true, 5: false, 6: true},
  ),
);
```

If we call `binary.serialize(sample)`, we get `[128, 0, 0, 0, 0, 46, 0, 0, 127, 196, 127, 226, 100, 1, 2, 0, 1, 127, 231, 0, 2, 128, 2, 0, 0, 0, 25, 0, 0, 127, 231, 0, 1, 127, 170, 127, 228, 6, 1, 2, 3, 4, 5, 6, 127, 235, 93, 144, 0, 2, 127, 231]`.

Here's what these bytes mean:

```
.................. data
128   0 .......... ├─ id of AdapterForMyClass<int>()
  0   0   0  46 .. ├─ number of bytes written by adapter
.................. └─ actual bytes
  0   0 ............. ├─ field #0: someItems
127 196 ............. │  ├─ id of AdapterForSet<int>()
..................... │  ├─ actual bytes
127 226 ............. │  │  ├─ id of AdapterForPrimitiveList.nullable(AdapterForUint8())
..................... │  │  └─ actual bytes
100 ................. │  │ ... ├─ List<bool> of which elements are non-null:
..................... │  │ ... │  [true, false, true]
  1 ................. │  │ ... ├─ list item: 1
  2 ................. │  │ ... └─ list item: 2
  0   1 ............. ├─ field #1: someMappedInts
127 231 ............. │  ├─ id of AdapterForNull()
..................... │  └─ (no bytes written)
  0   2 ............. └─ field #2: pointer
128   2 ................ ├─ id of AdapterForMyClass<String>()
  0   0   0  25 ........ ├─ number of bytes written by adapter
........................ └─ actual bytes
  0   0 ................... ├─ field #0: someItems
127 231 ................... │  ├─ id of AdapterForNull()
........................... │  └─ (no bytes written)
  0   1 ................... ├─ field #1: someMappedInts
127 170 ................... │  ├─ id of AdapterForMap<int, bool>()
........................... │  └─ actual bytes
127 228 ................... │ ... ├─ id of AdapterForPrimitiveList.short(AdapterForUint8())
........................... │ ... ├─ actual bytes
  6 ....................... │ ... │  ├─ length of list
  1 ....................... │ ... │  ├─ list item: 1
  2 ....................... │ ... │  ├─ list item: 2
  3 ....................... │ ... │  ├─ list item: 3
  4 ....................... │ ... │  ├─ list item: 4
  5 ....................... │ ... │  ├─ list item: 5
  6 ....................... │ ... │  └─ list item: 6
127 235 ................... │ ... ├─ id of AdapterForListOfBool()
........................... │ ... └─ actual bytes
 93 144 ................... │ ...... └─ List<bool> of elements:
........................... │ ......    [true, true, null, true, false, true]
  0   2 ................... └─ field #2: pointer
127 231 ...................... ├─ id of AdapterForNull()
.............................. └─ (no bytes written)
```
