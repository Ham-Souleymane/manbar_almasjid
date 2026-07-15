enum ImamStatus {
  pending('pending'),
  verified('verified'),
  rejected('rejected'),
  blocked('blocked');

  const ImamStatus(this.value);

  final String value;

  static ImamStatus fromString(String value) {
    return ImamStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ImamStatus.pending,
    );
  }
}
