/// App-level localized names that live outside level JSON
/// (locations, characters). Level-specific strings come from the JSON.
library;

/// Five town locations (master prompt §3).
const Map<String, Map<String, String>> locationNames = {
  'workshop': {'en': 'Workshop', 'ur': 'ورکشاپ'},
  'toyCorner': {'en': 'Toy Corner', 'ur': 'کھلونوں کا کونا'},
  'bicycleStop': {'en': 'Bicycle Stop', 'ur': 'سائیکل اسٹاپ'},
  'playground': {'en': 'Playground', 'ur': 'کھیل کا میدان'},
  'sunnyPark': {'en': 'Sunny Park', 'ur': 'دھوپ والا پارک'},
};

/// Display order of the five locations on the town map.
const List<String> locationOrder = [
  'workshop',
  'toyCorner',
  'bicycleStop',
  'playground',
  'sunnyPark',
];

/// Friendly character names (master prompt §3).
const Map<String, Map<String, String>> characterNames = {
  'mira': {'en': 'Mira', 'ur': 'میرا'},
  'pip': {'en': 'Pip', 'ur': 'پِپ'},
  'nori': {'en': 'Nori', 'ur': 'نوری'},
};

String localizedName(Map<String, Map<String, String>> table, String id, String lang) {
  final entry = table[id];
  if (entry == null) return id;
  return entry[lang] ?? entry['en'] ?? id;
}
