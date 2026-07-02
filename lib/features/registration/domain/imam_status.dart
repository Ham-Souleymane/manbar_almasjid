enum ImamStatus {
  pending('pending'),
  verified('verified'),
  rejected('rejected');

  const ImamStatus(this.value);

  final String value;

  static ImamStatus fromString(String value) {
    return ImamStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ImamStatus.pending,
    );
  }
}
