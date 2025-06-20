String formatNumber(int n) {
  if (n >= 1000000) {
    final base = n / 1000000.0;
    final truncated = (base * 10).floor() / 10;
    return '${truncated.toStringAsFixed(1)} M';
  } else if (n >= 10000) {
    final base = n / 1000.0;
    final truncated = (base * 10).floor() / 10;
    return '${truncated.toStringAsFixed(1)} k';
  } else {
    return n.toString();
  }
}

String getDecimalSeparator(String locale) {
  return locale.startsWith('fr') ? ',' : '.';
}