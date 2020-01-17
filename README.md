Binary serializer

The binary serializer is used for serializing Dart objects from and to binary data.
It's inspired by Protobuf.

There are the typical three purposes for users of this package.

* Clients that want the Binary serializer to be able to **serialize custom classes** create `TypeAdapter`s for them and register them at the `TypeRegistry`.
* Clients trying to **read and write serialized binary data** create a `BinaryReader` and a `BinaryWriter` by implementing some low-level methods like `writeUint8`, `writeUint16`.
* Clients that actively want to **serialize and deserialize data**, can accept any `BinaryReader` and `BinaryWriter` and call `read`/`write` on them to serialize and deserialize arbitrary objects.  
There's a higher-level `serialize`/`deserialize` API for converting to/from `Uint8List`.
