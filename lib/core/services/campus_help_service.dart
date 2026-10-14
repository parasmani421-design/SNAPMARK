import 'campus_info_store.dart';

class CampusHelpService {
  const CampusHelpService._();

  static String? replyTo(String question) {
    final query = question.toLowerCase().trim();
    if (query.isEmpty) return null;
    final language = _language(query);

    if (_containsAny(query, [
      'stationery',
      'stationary',
      'bookshop',
      'stationery shop',
      'stationary shop',
    ])) {
      return _locationReply(language, 'stationery');
    }
    if (_containsAny(query, [
      'medical',
      'clinic',
      'first aid',
      'doctor room',
      'medical room',
    ])) {
      return _locationReply(language, 'medical');
    }
    if (_containsAny(query, [
      'erp office',
      'accounts office',
      'erp kaha',
      'erp where',
    ])) {
      return _locationReply(language, 'erp');
    }

    if (_containsAny(query, ['neft', 'fee payment', 'fees payment']) ||
        _containsAny(query, ['fees', 'fee']) &&
            _containsAny(query, ['kaise', 'how', 'pay', 'bhar', 'jama'])) {
      return _feeReply(language);
    }
    if (_containsAny(query, ['attendance', 'present']) &&
        _containsAny(query, [
          'kaise',
          'how',
          'mark',
          'lag',
          'fill',
          'submit',
        ])) {
      return _attendanceReply(language);
    }
    return null;
  }

  static String _locationReply(_ReplyLanguage language, String key) {
    final place = CampusInfoStore.location(key);
    return switch ((language, key)) {
      (_ReplyLanguage.hindi, 'stationery') =>
        'स्टेशनरी की दुकान $place में है।',
      (_ReplyLanguage.hindi, 'medical') =>
        'मेडिकल / फर्स्ट-एड रूम $place में है।',
      (_ReplyLanguage.hindi, 'erp') => 'ERP ऑफिस $place में है।',
      (_ReplyLanguage.romanHindi, 'stationery') =>
        'Stationery ki dukaan $place mein hai.',
      (_ReplyLanguage.romanHindi, 'medical') =>
        'Medical / first-aid room $place mein hai.',
      (_ReplyLanguage.romanHindi, 'erp') => 'ERP office $place mein hai.',
      (_, 'stationery') => 'The stationery shop is at $place.',
      (_, 'medical') => 'The medical / first-aid room is at $place.',
      _ => 'The ERP office is at $place.',
    };
  }

  static String _feeReply(_ReplyLanguage language) => switch (language) {
    _ReplyLanguage.hindi =>
      'Fees/NEFT के लिए college के official ERP में Fees section खोलें और वहीं दिए गए bank details व exact amount का उपयोग करें। Payment remarks में enrollment/fee reference डालें और UTR व receipt संभालकर रखें। इस app में live bank details या fee account connected नहीं है।',
    _ReplyLanguage.romanHindi =>
      'Fees/NEFT ke liye college ke official ERP ka Fees section kholo aur wahin diye bank details aur exact amount use karo. Payment remarks mein enrollment/fee reference dalo; UTR aur receipt sambhal kar rakho. Is app mein live bank details ya fee account connected nahi hai.',
    _ReplyLanguage.english =>
      'For fees by NEFT, open the Fees section in your official college ERP and use the bank details and exact amount shown there. Add your enrollment or fee reference in the payment remarks, then keep the UTR and receipt. Live bank details and fee accounts are not connected to this app.',
  };

  static String _attendanceReply(_ReplyLanguage language) => switch (language) {
    _ReplyLanguage.hindi =>
      'क्लास के समय SnapMark में Attendance खोलें, सही subject/class चुनें और उस session के लिए दिख रहा approved तरीका पूरा करें। Attendance log जाँचें; गलती हो तो अपने faculty या admin से correction माँगें।',
    _ReplyLanguage.romanHindi =>
      'Class ke time SnapMark mein Attendance kholo, sahi subject/class chuno aur session par dikhaya approved method complete karo. Attendance log check karo; galti ho toh faculty ya admin se correction maango.',
    _ReplyLanguage.english =>
      'During class, open Attendance in SnapMark, choose the correct subject/class, and complete the approved method shown for that session. Check your attendance log; contact your faculty or admin if it needs correction.',
  };

  static _ReplyLanguage _language(String query) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(query)) {
      return _ReplyLanguage.hindi;
    }
    if (_containsAny(query, [
      'kaha',
      'kahan',
      'kidhar',
      'kaise',
      'hai',
      'hain',
      'mein',
      'me ',
      'ka ',
      'ki ',
      'ke ',
      'batao',
      'kro',
      'karu',
      'krna',
    ])) {
      return _ReplyLanguage.romanHindi;
    }
    return _ReplyLanguage.english;
  }

  static bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);
}

enum _ReplyLanguage { english, hindi, romanHindi }
