import 'package:meta/meta.dart';

/// Can be used as an annotate on a class to mark that a [TypeAdapter] should
/// get generated for it.
class BinaryType {
  const BinaryType({@required this.legacyFields});

  /// Field ids that were used in the past and should not be used anymore.
  final Set<int> legacyFields;
}

/// Can be used to annotate a field in a class annotated with [BinaryType] to
/// mark that it should be serialized or deserialized when an object of the
/// class gets serialized or deserialized.
class BinaryField {
  const BinaryField(this.id, {@required this.defaultValue});

  /// An id that uniquely identifies this field among other fields of this
  /// class that currently exist, existed in the past or will exist in the
  /// future.
  final int id;

  /// The default value of this field.
  ///
  /// If an object gets serialized, then a field gets added to an object, and
  /// then the object gets deserialized again, fields may be missing.
  /// This value indicates the value these fields should get in that case.
  final dynamic defaultValue;
}
