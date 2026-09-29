class ImportValueCodec {
  static const maxAmountCent = 99999999999999;
  static int? amountCent(String input) {
    final text = input.trim();
    if (text.length > 20) return null;
    if (!RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d{1,2})?$').hasMatch(text)) {
      return null;
    }
    final parts = text.replaceAll(',', '').split('.');
    final whole = BigInt.tryParse(parts.first);
    if (whole == null) return null;
    final cents =
        whole * BigInt.from(100) +
        BigInt.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
    if (cents <= BigInt.zero || cents > BigInt.from(maxAmountCent)) return null;
    return cents.toInt();
  }

  static DateTime? date(String input) {
    final text = input.trim().replaceAll('/', '-');
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?(?:Z|[+-]\d{2}:?\d{2})?)?$',
    ).firstMatch(text);
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    if (year < 1 ||
        year > 9999 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > DateTime(year, month + 1, 0).day) {
      return null;
    }
    if (int.parse(match[4] ?? '0') > 23 ||
        int.parse(match[5] ?? '0') > 59 ||
        int.parse(match[6] ?? '0') > 59) {
      return null;
    }
    final zone = RegExp(r'[+-](\d{2}):?(\d{2})$').firstMatch(text);
    if (zone != null && (int.parse(zone[1]!) > 23 || int.parse(zone[2]!) > 59)) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}
