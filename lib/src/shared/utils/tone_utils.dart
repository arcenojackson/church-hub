const _numericToTone = {
  '0': 'A',
  '1': 'A#',
  '2': 'B',
  '3': 'C',
  '4': 'C#',
  '5': 'D',
  '6': 'D#',
  '7': 'E',
  '8': 'F',
  '9': 'F#',
  '10': 'G',
  '11': 'G#',
};

/// Converts a tone value to its letter label.
/// Handles both numeric (e.g. '5') and letter (e.g. 'D') formats.
String toneLabel(String tone) => _numericToTone[tone] ?? tone;
