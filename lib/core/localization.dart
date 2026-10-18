/// Localised UI strings (English + Urdu) for Tiny Repair Town.
///
/// Pure Dart — no Flutter. Look up with [tr]; Urdu is right-to-left
/// (see [isRtl]).
library;

/// Localised string table: key -> {'en': ..., 'ur': ...}.
class AppStrings {
  static const Map<String, Map<String, String>> values = {
    'appTitle': {
      'en': 'Tiny Repair Town',
      'ur': 'ٹائنی ریپیئر ٹاؤن',
    },
    'letsPlay': {
      'en': "Let's play",
      'ur': 'آؤ کھیلیں',
    },
    'choosePiece': {
      'en': 'Choose a piece',
      'ur': 'ایک ٹکڑا چنیں',
    },
    'tryAgain': {
      'en': 'Try again',
      'ur': 'دوبارہ کوشش کریں',
    },
    'wellDone': {
      'en': 'Well done!',
      'ur': 'شاباش!',
    },
    'needHint': {
      'en': 'Need a hint?',
      'ur': 'اشارہ چاہیے؟',
    },
    'forParents': {
      'en': 'For parents',
      'ur': 'والدین کے لیے',
    },
    'backToTown': {
      'en': 'Back to town',
      'ur': 'شہر میں واپس جائیں',
    },
    'play': {
      'en': 'Play',
      'ur': 'کھیلیں',
    },
    'resume': {
      'en': 'Resume',
      'ur': 'جاری رکھیں',
    },
    'replay': {
      'en': 'Replay',
      'ur': 'دوبارہ کھیلیں',
    },
    'hint': {
      'en': 'Hint',
      'ur': 'اشارہ',
    },
    'close': {
      'en': 'Close',
      'ur': 'بند کریں',
    },
    'settings': {
      'en': 'Settings',
      'ur': 'ترتیبات',
    },
    'language': {
      'en': 'Language',
      'ur': 'زبان',
    },
    'music': {
      'en': 'Music',
      'ur': 'موسیقی',
    },
    'effects': {
      'en': 'Sound effects',
      'ur': 'اثرات',
    },
    'narration': {
      'en': 'Narration',
      'ur': 'بیان',
    },
    'reducedMotion': {
      'en': 'Reduced motion',
      'ur': 'کم حرکت',
    },
    'extraGuidance': {
      'en': 'Extra guidance',
      'ur': 'اضافی رہنمائی',
    },
    'stickerBook': {
      'en': 'Sticker book',
      'ur': 'اسٹیکر کتاب',
    },
    'levelComplete': {
      'en': 'Level complete!',
      'ur': 'لیول مکمل!',
    },
    'thatFits': {
      'en': 'That fits!',
      'ur': 'یہ فٹ ہو گیا!',
    },
    'tryAnotherPiece': {
      'en': "Let's try another piece.",
      'ur': 'آئیے ایک اور ٹکڑا آزمائیں۔',
    },
    'moreInParents': {
      'en': 'More activities in Parents',
      'ur': 'مزید سرگرمیاں والدین کے حصے میں ہیں',
    },
    'dragOrTap': {
      'en': 'Drag a piece, or tap the piece then tap its spot.',
      'ur': 'ایک ٹکڑے کو اس کی خالی جگہ پر گھسیٹیں — یا ٹکڑے کو تھپتھپائیں، پھر جگہ کو تھپتھپائیں۔',
    },
    'cancel': {
      'en': 'Cancel',
      'ur': 'منسوخ کریں',
    },
    'sound': {
      'en': 'Sound',
      'ur': 'آواز',
    },
    'accessibility': {
      'en': 'Accessibility',
      'ur': 'رسائی',
    },
    'largeText': {
      'en': 'Larger text',
      'ur': 'بڑا متن',
    },
    'progressSummary': {
      'en': 'Progress',
      'ur': 'پیش رفت',
    },
    'activitiesComplete': {
      'en': 'Activities complete',
      'ur': 'مکمل شدہ سرگرمیاں',
    },
    'stickersEarned': {
      'en': 'Stickers earned',
      'ur': 'حاصل کردہ اسٹیکرز',
    },
    'resetProgress': {
      'en': 'Reset progress',
      'ur': 'پیش رفت صاف کریں',
    },
    'resetConfirmTitle': {
      'en': 'Reset all progress?',
      'ur': 'کیا تمام پیش رفت صاف کر دیں؟',
    },
    'resetConfirmBody': {
      'en':
          'Completed levels and stickers will be cleared. Settings and the full-game unlock stay as they are.',
      'ur':
          'مکمل شدہ لیولز اور اسٹیکرز صاف ہو جائیں گے۔ ترتیبات اور مکمل گیم کا انلاک ویسے ہی رہے گا۔',
    },
    'resetDone': {
      'en': 'Progress cleared.',
      'ur': 'پیش رفت صاف ہو گئی۔',
    },
    'parentGateTitle': {
      'en': 'For parents',
      'ur': 'والدین کے لیے',
    },
    'parentGateNote': {
      'en':
          'This gate discourages accidental access by children. It is not identity verification or parental consent.',
      'ur':
          'یہ گیٹ بچوں کے حادثاتی داخلے کو روکتا ہے۔ یہ شناختی تصدیق یا والدین کی رضامندی نہیں ہے۔',
    },
    'parentGateHold': {
      'en': 'Grown-ups: press and hold the button for {n} seconds.',
      'ur': 'بڑوں کے لیے: بٹن کو {n} سیکنڈ تک دبائے رکھیں۔',
    },
    'fullGameTitle': {
      'en': 'More activities',
      'ur': 'مزید سرگرمیاں',
    },
    'fullGameBody': {
      'en':
          'Levels 11–20 come with the full game. Buying is not available in this build, so nothing here will charge you.',
      'ur':
          'لیول 11 سے 20 مکمل گیم کے ساتھ آئیں گے۔ اس ورژن میں خریداری دستیاب نہیں، اس لیے یہاں کوئی چارج نہیں ہوگا۔',
    },
    'privacyNote': {
      'en':
          'Progress is stored only on this device. No accounts, no ads, no analytics.',
      'ur':
          'پیش رفت صرف اسی ڈیوائس پر محفوظ ہوتی ہے۔ کوئی اکاؤنٹ، اشتہار یا تجزیات نہیں۔',
    },
    'privacyTitle': {
      'en': 'Privacy',
      'ur': 'رازداری',
    },
    'slotSemantic': {
      'en': 'Empty spot',
      'ur': 'خالی جگہ',
    },
    'panelSemantic': {
      'en': 'Pattern panel',
      'ur': 'نمونے کا خانہ',
    },
  };
}

/// Returns the localised string for [key] in [lang].
///
/// Falls back to English when the language is missing, and to the key itself
/// when the key is unknown.
String tr(String key, String lang) {
  final entry = AppStrings.values[key];
  if (entry == null) return key;
  return entry[lang] ?? entry['en'] ?? key;
}

/// True for right-to-left languages (Urdu).
bool isRtl(String lang) => lang == 'ur';
