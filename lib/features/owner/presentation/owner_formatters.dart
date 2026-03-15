String formatOwnerDate(DateTime? value) {
  if (value == null) {
    return '-';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month.${local.year}';
}

String formatOwnerDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} $hour:$minute';
}

String formatStorageGb(double value) {
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} GB';
}
