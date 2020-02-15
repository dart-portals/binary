# Table of reserved type ids

If you are creating a Dart package that needs to register custom type adapters and that's intended to be published on [pub.dev](https://pub.dev), don't hesitate to file a pull request adding type ids to this table.

> Consider adding something like the following to your package to allow users to call `binary.initializeMyPackage()`:
>
> ```dart
> extension MyPackageBinary on BinaryApi {
>   void initializeMyPackage() {
>     TypeRegistry.registerAdapters({
>       ...
>     });
>   }
> }
> ```

Type id reservations are done in batches of 10. The x stands for any digit.

| type ids | reserved for      |
| -------- | ----------------- |
| -1 – -9  | `dart:core`       |
| -1x      | `dart:core`       |
| -2x      | `dart:core`       |
| -3x      | `dart:core`       |
| -4x      | `dart:core`       |
| -5x      | `dart:core`       |
| -6x      | `dart:core`       |
| -7x      | `dart:core`       |
| -8x      | `dart:core`       |
| -9x      | `dart:core`       |
| -10x     | `dart:core`       |
| -11x     | `dart:typed_data` |
