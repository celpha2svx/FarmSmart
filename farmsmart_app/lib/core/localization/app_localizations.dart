import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': _enStrings,
    'ha': _haStrings,
    'yo': _yoStrings,
    'ig': _igStrings,
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedStrings[langCode]?[key] ?? _enStrings[key] ?? key;
  }

  static final Map<String, String> _enStrings = {
    'app_name': 'FarmSmart',
    'app_tagline': 'Your farm, smarter.',
    // Onboarding
    'welcome_title': 'Welcome to FarmSmart',
    'welcome_subtitle': 'Get personalized weather, soil, and pest advice for your farm.',
    'get_started': 'Get Started',
    'select_language': 'Select Language',
    'select_crop': 'What crop do you grow?',
    'select_location': 'Where is your farm?',
    'select_size': 'How big is your farm?',
    // Home
    'today_advisory': "Today's Advisory",
    'weather': 'Weather',
    'soil_moisture': 'Soil Moisture',
    'pest_risk': 'Pest Risk',
    'farming_calendar': 'Farming Calendar',
    'market_prices': 'Market Prices',
    'scan_crop': 'Scan Crop',
    // Weather
    'forecast_3day': '3-Day Forecast',
    'temperature': 'Temperature',
    'humidity': 'Humidity',
    'rainfall': 'Rainfall',
    'wind': 'Wind',
    // Soil
    'soil_status': 'Soil Status',
    'critical': 'CRITICAL',
    'low': 'LOW',
    'adequate': 'ADEQUATE',
    'optimal': 'OPTIMAL',
    // Pest
    'no_pest_risk': 'No pest risk detected',
    'pest_alert': 'PEST ALERT',
    'pest_advisory': 'Pest Advisory',
    'scouting_tip': 'Scouting Tip',
    // Calendar
    'today_task': "Today's Task",
    'no_tasks': 'No tasks for today',
    'mark_done': 'Mark Done',
    // Market
    'current_prices': 'Current Market Prices',
    'nearest_market': 'Nearest Market',
    // Settings
    'settings': 'Settings',
    'language': 'Language',
    'language_hint': 'Change app language',
    'notifications': 'Notifications',
    'about': 'About',
    'logout': 'Log Out',
    // Common
    'loading': 'Loading...',
    'error': 'Something went wrong',
    'retry': 'Retry',
    'offline': 'You are offline',
    'offline_hint': 'Advisories are cached. Sync when connected.',
    'save': 'Save',
    'cancel': 'Cancel',
    'done': 'Done',
    'next': 'Next',
    'back': 'Back',
    // Farm sizes
    'small': 'Less than 1 hectare',
    'medium': '1–5 hectares',
    'large': 'More than 5 hectares',
    // Risk levels
    'high_risk': 'High Risk',
    'medium_risk': 'Medium Risk',
    'low_risk': 'Low Risk',
  };

  static final Map<String, String> _haStrings = {
    'app_name': 'FarmSmart',
    'app_tagline': 'Gonar ku, mafi wayo.',
    'welcome_title': 'Barka da zuwa FarmSmart',
    'welcome_subtitle': 'Sami shawara na musamman game da yanayi, ƙasa, da kwari don gonar ku.',
    'get_started': 'Fara',
    'select_language': 'Zaɓi Harshe',
    'select_crop': 'Wanne amfanin gona kuke nomawa?',
    'select_location': 'Ina gonar ku take?',
    'select_size': 'Girman gonar ku nawa ne?',
    'today_advisory': 'Shawarwarin Yau',
    'weather': 'Yanayi',
    'soil_moisture': 'Danshin Ƙasa',
    'pest_risk': 'Hadarin Kwari',
    'farming_calendar': 'Kalandar Noma',
    'market_prices': 'Farashin Kasuwa',
    'scan_crop': 'Duba Amfanin Gona',
    'forecast_3day': 'Hasashen Kwanaki 3',
    'temperature': 'Zazzabi',
    'humidity': 'Danshi',
    'rainfall': 'Ruwan Sama',
    'wind': 'Iska',
    'soil_status': 'Halin Ƙasa',
    'critical': 'MATSALA',
    'low': 'KANKANTE',
    'adequate': 'ISA',
    'optimal': 'MAFI KYAU',
    'no_pest_risk': 'Babu hadarin kwari',
    'pest_alert': 'FAɗAKAR KWARI',
    'pest_advisory': 'Shawarwarin Kwari',
    'scouting_tip': 'Tukuna Bincike',
    "today_task": 'Aikin Yau',
    'no_tasks': 'Babu aiki a yau',
    'mark_done': 'Kammala',
    'current_prices': 'Farashin Kasuwa na Yanzu',
    'nearest_market': 'Kasuwa Mafi Kusa',
    'settings': 'Saituna',
    'language': 'Harshe',
    'language_hint': 'Canza harshen app',
    'notifications': 'Sanarwa',
    'about': 'Game da',
    'logout': 'Fita',
    'loading': 'Ana lodawa...',
    'error': 'Wani abu ya yi kuskure',
    'retry': 'Sake gwadawa',
    'offline': 'Ba a haɗa da intanet',
    'offline_hint': 'An adana shawarwarin. Da haɗin intanet zai aika.',
    'save': 'Ajiye',
    'cancel': 'Soke',
    'done': 'An gama',
    'next': 'Gaba',
    'back': 'Baya',
    'small': 'Kasa da hekta 1',
    'medium': 'Hekta 1-5',
    'large': 'Fiye da hekta 5',
    'high_risk': 'Hadari Mai Girma',
    'medium_risk': 'Hadari Matsakaici',
    'low_risk': 'Hadari Kaɗan',
  };

  static final Map<String, String> _yoStrings = {
    'app_name': 'FarmSmart',
    'app_tagline': 'Oko rẹ, lọ́gbọ́n.',
    'welcome_title': 'Kaabọ̀ sí FarmSmart',
    'welcome_subtitle': 'Gba ìmọ̀ràn oju-ọjọ́, ilẹ̀, àti àrùn fún oko rẹ.',
    'get_started': 'Bẹ̀rẹ̀',
    'select_language': 'Yan Ede',
    'select_crop': 'Irú ohun ọ̀gbìn wo lo ń gbin?',
    'select_location': 'Nibo ni oko rẹ wà?',
    'select_size': 'Bawo ni oko rẹ ṣe tóbi?',
    'today_advisory': 'Ìmọ̀ràn Òní',
    'weather': 'Oju-ọjọ́',
    'soil_moisture': 'Ọ̀rinrin Ilẹ̀',
    'pest_risk': 'Ewu Kòkòrò',
    'farming_calendar': 'Kàlẹ́ńdà Àgbẹ̀',
    'market_prices': 'Iye Owó Ọjà',
    'scan_crop': 'Yàwòran Ohun Ọ̀gbìn',
    'forecast_3day': 'Àsọtẹ́lẹ̀ Ọjọ́ Mẹ́ta',
    'temperature': 'Ìwọ̀n Ooru',
    'humidity': 'Ọ̀rinrin',
    'rainfall': 'Òjò',
    'wind': 'Afẹ́fẹ́',
    'soil_status': 'Ipò Ilẹ̀',
    'critical': 'PÀTÀKÌ',
    'low': 'KÉRÉ',
    'adequate': 'TÓ',
    'optimal': 'DÁRA JÙLỌ',
    'no_pest_risk': 'Ko si ewu kòkòrò',
    'pest_alert': 'ÌKÌLỌ̀ KÒKÒRÒ',
    'pest_advisory': 'Ìmọ̀ràn Kòkòrò',
    'scouting_tip': 'Ìdámọ̀ràn Ìṣàwárí',
    "today_task": 'Iṣẹ́ Òní',
    'no_tasks': 'Ko si iṣẹ́ fún òní',
    'mark_done': 'Sàmì sí Ṣe',
    'current_prices': 'Iye Owó Ọjà Lọ́wọ́',
    'nearest_market': 'Ọjà Tó Súnmọ́',
    'settings': 'Àwọn Ètò',
    'language': 'Èdè',
    'language_hint': 'Yí èdè app padà',
    'notifications': 'Àwọn Ìfìlọ́lẹ̀',
    'about': 'Nípa',
    'logout': 'Jáde',
    'loading': 'Ń gbéwọ̀n...',
    'error': 'Ohun kan ṣìṣe',
    'retry': 'Tún gbìyànjú',
    'offline': 'O kò ní ìsopọ̀',
    'offline_hint': 'Àwọn ìmọ̀ràn ti fipamọ́. Máa ṣe àmúgbàlẹ̀gbẹ̀ tó bá ní ìsopọ̀.',
    'save': 'Fipamọ́',
    'cancel': 'Fàgídí',
    'done': 'Ṣe',
    'next': 'Tẹ̀síwájú',
    'back': 'Pàdà',
    'small': 'Kérè ju hekta 1',
    'medium': 'Hekta 1-5',
    'large': 'Tóbi ju hekta 5',
    'high_risk': 'Ewu Nla',
    'medium_risk': 'Ewu Àrìnwó',
    'low_risk': 'Ewu Kékeré',
  };

  static final Map<String, String> _igStrings = {
    'app_name': 'FarmSmart',
    'app_tagline': 'Ugbo gị, nke nwere uche.',
    'welcome_title': 'Nnọọ na FarmSmart',
    'welcome_subtitle': 'Nweta ndụmọdụ ihu igwe, ala, na ahụhụ maka ugbo gị.',
    'get_started': 'Bido',
    'select_language': 'Họrọ Asụsụ',
    'select_crop': 'Kedu ihe ị na-akụ?',
    'select_location': 'Ebee ka ugbo gị dị?',
    'select_size': 'Ole ka ugbo gị buru?',
    'today_advisory': 'Ndụmọdụ Taa',
    'weather': 'Ihu Igwe',
    'soil_moisture': 'Mmiri Ala',
    'pest_risk': 'Ihe Egwu Ahụhụ',
    'farming_calendar': 'Kalenda Ọrụ Ugbo',
    'market_prices': 'Ọnụ Ahịa',
    'scan_crop': 'Nyochaa Ihe Ọkụkụ',
    'forecast_3day': 'Amụma Ụbọchị Atọ',
    'temperature': 'Okpomọkụ',
    'humidity': 'Iri mmiri',
    'rainfall': 'Mmiri ozuzo',
    'wind': 'Ikuku',
    'soil_status': 'Ọnọdụ Ala',
    'critical': 'MKPA',
    'low': 'ONUMA',
    'adequate': 'EZU',
    'optimal': 'KACHASỊ MMA',
    'no_pest_risk': 'Enweghị ihe egwu ahụhụ',
    'pest_alert': 'NKWUTA AHỤHỤ',
    'pest_advisory': 'Ndụmọdụ Ahụhụ',
    'scouting_tip': 'Ndụmọdụ Nyocha',
    "today_task": 'Ọrụ Taa',
    'no_tasks': 'Enweghị ọrụ taa',
    'mark_done': 'Kaa Mere',
    'current_prices': 'Ọnụ Ahịa Ugbu a',
    'nearest_market': 'Ahịa Kacha Nso',
    'settings': 'Ntọala',
    'language': 'Asụsụ',
    'language_hint': 'Gbanwee asụsụ ngwa',
    'notifications': 'Ngosi',
    'about': 'Gbasara',
    'logout': 'Wepụ',
    'loading': 'Na-ebu...',
    'error': 'Ihe mere njehie',
    'retry': 'Nwaa ọzọ',
    'offline': 'Ị nọ naanị gị',
    'offline_hint': 'Edobela ndụmọdụ. Mee ka ọ dakọtara mgbe ejikọrọ.',
    'save': 'Chekwa',
    'cancel': 'Kagbuo',
    'done': 'Mere',
    'next': 'ọzọ',
    'back': 'Azụ',
    'small': 'Ihe na-erughị hekta 1',
    'medium': 'Hekta 1-5',
    'large': 'Karịa hekta 5',
    'high_risk': 'Ihe Egwu Ukwu',
    'medium_risk': 'Ihe Egwu Ọkara',
    'low_risk': 'Ihe Egwu Nta',
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ha', 'yo', 'ig'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
