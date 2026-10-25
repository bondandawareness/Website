class WebSettings {
  WebSettings(Map<String, dynamic> input) : values = Map.of(input) {
    for (final key in ['enabled', 'sound', 'vibration']) {
      if (values[key] is! bool) throw FormatException('Invalid $key');
    }
    for (final key in ['start', 'end']) {
      if (values[key] is! String ||
          !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(values[key]))
        throw FormatException('Invalid $key');
    }
    if (startMinute >= endMinute)
      throw const FormatException('Check reminder times');
    if (![10, 25, 35, 45, 60, 120, 180].contains(values['rhythm']))
      throw const FormatException('Invalid rhythm');
    if (![1, 2, 3, 4, 5].contains(values['rotation']))
      throw const FormatException('Invalid rotation');
    if (!['auto', ...instruments].contains(values['instrument']))
      throw const FormatException('Invalid instrument');
  }
  static const instruments = [
    'bowl',
    'gong',
    'triangle',
    'temple_bell',
    'chimes',
    'crystal'
  ];
  static WebSettings defaults() => WebSettings({
        'enabled': true,
        'sound': true,
        'vibration': false,
        'start': '09:00',
        'end': '21:00',
        'rhythm': 35,
        'rotation': 3,
        'instrument': 'bowl'
      });
  final Map<String, dynamic> values;
  int minutes(String key) {
    final parts = (values[key] as String).split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get startMinute => minutes('start');
  int get endMinute => minutes('end');
  int? get fixedInstrument => values['instrument'] == 'auto'
      ? null
      : instruments.indexOf(values['instrument']);
}
