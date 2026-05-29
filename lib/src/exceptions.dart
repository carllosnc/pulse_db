class PulseDbException implements Exception {
  final String message;
  final Object? cause;

  PulseDbException(this.message, [this.cause]);

  @override
  String toString() => 'PulseDbException: $message';
}

class PulseDbClosedException extends PulseDbException {
  PulseDbClosedException(super.message, [super.cause]);

  @override
  String toString() => 'PulseDbClosedException: $message';
}

class PulseDbConstraintException extends PulseDbException {
  PulseDbConstraintException(super.message, [super.cause]);

  @override
  String toString() => 'PulseDbConstraintException: $message';
}

class PulseDbSchemaException extends PulseDbException {
  PulseDbSchemaException(super.message, [super.cause]);

  @override
  String toString() => 'PulseDbSchemaException: $message';
}

class PulseDbTransactionException extends PulseDbException {
  PulseDbTransactionException(super.message, [super.cause]);

  @override
  String toString() => 'PulseDbTransactionException: $message';
}
