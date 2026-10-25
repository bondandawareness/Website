// Calendar dates, rather than UTC instants, define instrument changes.
int calendarDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

int soundIndexForDay(DateTime day, int seed, int rotationDays) {
  if (rotationDays < 1 || rotationDays > 5) {
    throw ArgumentError.value(rotationDays, 'rotationDays');
  }
  // A fixed shuffled cycle visits all six sounds without adjacent repeats.
  const cycle = [0, 4, 2, 5, 1, 3];
  final block = calendarDay(day) ~/ rotationDays;
  return cycle[(block + seed) % cycle.length];
}

class DailyRandom {
  DailyRandom(DateTime day, int seed)
      : _state = (calendarDay(day) ^ seed) & 0x7fffffff;
  int _state;

  int nextInt(int maximum) {
    if (maximum <= 0) throw ArgumentError.value(maximum, 'maximum');
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state % maximum;
  }
}
