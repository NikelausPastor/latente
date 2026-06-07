class TimeFormatter {
  static int parseMinutesSeconds(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Tempo vuoto');
    }

    final parts = trimmed.split(':');
    if (parts.length == 1) {
      final minutes = int.parse(parts.first);
      return minutes * 60;
    }
    if (parts.length != 2) {
      throw FormatException('Formato tempo non valido: $value');
    }

    final minutes = int.parse(parts[0]);
    final seconds = int.parse(parts[1]);
    if (minutes < 0 || seconds < 0 || seconds > 59) {
      throw FormatException('Formato tempo non valido: $value');
    }
    return (minutes * 60) + seconds;
  }

  static int roundToNearest15Seconds(num totalSeconds) {
    return ((totalSeconds / 15).round() * 15).toInt();
  }

  static String minutesSeconds(int totalSeconds) {
    final sign = totalSeconds < 0 ? '-' : '';
    final absolute = totalSeconds.abs();
    final minutes = absolute ~/ 60;
    final seconds = absolute % 60;
    return '$sign$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String signedMinutesSeconds(int totalSeconds) {
    if (totalSeconds == 0) {
      return '0:00';
    }
    final sign = totalSeconds > 0 ? '+' : '-';
    final absolute = totalSeconds.abs();
    final minutes = absolute ~/ 60;
    final seconds = absolute % 60;
    return '$sign$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
