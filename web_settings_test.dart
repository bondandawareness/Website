import 'package:flutter_test/flutter_test.dart';
import 'package:still/web_settings.dart';

void main() {
  test('all fixed instruments map to the same native sound as the HTML', () {
    for (var i = 0; i < WebSettings.instruments.length; i++) {
      final values = WebSettings.defaults().values;
      values['instrument'] = WebSettings.instruments[i];
      expect(WebSettings(values).fixedInstrument, i);
    }
    final values = WebSettings.defaults().values;
    values['instrument'] = 'auto';
    expect(WebSettings(values).fixedInstrument, isNull);
  });
  test('reject invalid times, unsupported choices and malformed toggles', () {
    for (final change in <Map<String, dynamic>>[
      {'start': '21:00', 'end': '09:00'},
      {'end': '25:00'},
      {'rhythm': 0},
      {'rotation': 6},
      {'instrument': 'unknown'},
      {'enabled': 'false'}
    ]) {
      expect(() => WebSettings({...WebSettings.defaults().values, ...change}),
          throwsFormatException);
    }
  });
  test('accept long rhythms and preserve off state', () {
    final settings = WebSettings({
      ...WebSettings.defaults().values,
      'enabled': false,
      'rhythm': 180,
      'start': '09:30',
      'end': '20:45'
    });
    expect(settings.startMinute, 570);
    expect(settings.endMinute, 1245);
    expect(settings.values['enabled'], false);
  });
}
