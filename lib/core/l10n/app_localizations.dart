import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('cs'),
    Locale('en'),
    Locale('de'),
    Locale('sk'),
    Locale('es'),
    Locale('it'),
    Locale('fr'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get languageCode {
    final code = locale.languageCode;
    return _localizedValues.containsKey(code) ? code : 'en';
  }

  String t(String key) {
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        _localizedValues['cs']![key] ??
        key;
  }

  String get appTitle => t('appTitle');
  String get news => t('news');
  String get events => t('events');
  String get riders => t('riders');
  String get rankings => t('rankings');
  String get profile => t('profile');
  String get login => t('login');
  String get logout => t('logout');
  String get retry => t('retry');
  String get continueWithoutLogin => t('continueWithoutLogin');
  String get email => t('email');
  String get password => t('password');
  String get fillEmailPassword => t('fillEmailPassword');
  String get loginPrompt => t('loginPrompt');
  String get notLoggedIn => t('notLoggedIn');
  String get loginRequired => t('loginRequired');
  String get ridersLoginRequired => t('ridersLoginRequired');
  String get rankingsLoginRequired => t('rankingsLoginRequired');
  String get loadingFailed => t('loadingFailed');
  String get newsLoadFailed => t('newsLoadFailed');
  String get eventsLoadFailed => t('eventsLoadFailed');
  String get rankingsLoadFailed => t('rankingsLoadFailed');
  String get noNews => t('noNews');
  String get noEvents => t('noEvents');
  String get noRiders => t('noRiders');
  String get searchRiders => t('searchRiders');
  String get men => t('men');
  String get women => t('women');
  String get themeSettings => t('themeSettings');
  String get languageSettings => t('languageSettings');
  String get systemTheme => t('systemTheme');
  String get lightTheme => t('lightTheme');
  String get darkTheme => t('darkTheme');
  String get audioArticle => t('audioArticle');
  String get gallery => t('gallery');
  String get minutesReadSuffix => t('minutesReadSuffix');
  String get viewsSuffix => t('viewsSuffix');
  String get selectYear => t('selectYear');
  String get canceled => t('canceled');
  String get twoDays => t('twoDays');
  String get registrationOpen => t('registrationOpen');
  String get international => t('international');
  String get category => t('category');
  String get dateOfBirth => t('dateOfBirth');
  String get gender => t('gender');
  String get plateNumber => t('plateNumber');
  String get inactive => t('inactive');
  String get yearsSuffix => t('yearsSuffix');
  String get noData => t('noData');
  String get noRidersInCategory => t('noRidersInCategory');
  String get points => t('points');
  String get featuredArticle => t('featuredArticle');
  String get minutesShort => t('minutesShort');
  String get category20 => t('category20');
  String get category24 => t('category24');
  String get doesNotRide => t('doesNotRide');
  String get ranking20 => t('ranking20');
  String get ranking24 => t('ranking24');
  String get transponder20 => t('transponder20');
  String get transponder24 => t('transponder24');
  String get eventInfo => t('eventInfo');
  String get eventDate => t('eventDate');
  String get eventType => t('eventType');
  String get raceSystem => t('raceSystem');
  String get raceDirector => t('raceDirector');
  String get format => t('format');
  String get yes => t('yes');
  String get registrationClosed => t('registrationClosed');
  String get registrationFrom => t('registrationFrom');
  String get registrationTo => t('registrationTo');
  String get unregisterTo => t('unregisterTo');
  String get register => t('register');
  String get registeredRiders => t('registeredRiders');
  String get proposition => t('proposition');
  String get results => t('results');
  String get documents => t('documents');
  String get openOnWeb => t('openOnWeb');
  String get navigateToTrack => t('navigateToTrack');
  String get eshopPickup => t('eshopPickup');
  String get place => t('place');
  String get time => t('time');
  String get note => t('note');

  // Registration
  String get registerTitle => t('registerTitle');
  String get registerPrompt => t('registerPrompt');
  String get registerSuccess => t('registerSuccess');
  String get registerSuccessDetail => t('registerSuccessDetail');
  String get firstName => t('firstName');
  String get lastName => t('lastName');
  String get fillAllFields => t('fillAllFields');
  String get passwordTooShort => t('passwordTooShort');
  String get passwordHint => t('passwordHint');
  String get alreadyHaveAccount => t('alreadyHaveAccount');
  String get noAccount => t('noAccount');

  // My entries
  String get myEntries => t('myEntries');
  String get noEntries => t('noEntries');
  String get cancelEntry => t('cancelEntry');
  String get cancelEntryConfirm => t('cancelEntryConfirm');
  String get cancel => t('cancel');
  String get fee => t('fee');
  String get czk => t('czk');
  String get shop => t('shop');
  String get addToCart => t('addToCart');
  String get cart => t('cart');
  String get cartEmpty => t('cartEmpty');
  String get outOfStock => t('outOfStock');
  String get inStock => t('inStock');
  String get pieces => t('pieces');
  String get total => t('total');
  String get checkout => t('checkout');
  String get orderSuccess => t('orderSuccess');
  String get orderSuccessDetail => t('orderSuccessDetail');
  String get selectVariant => t('selectVariant');
  String get shopLoadFailed => t('shopLoadFailed');
  String get phone => t('phone');
  String get allCategories => t('allCategories');
  String get credit => t('credit');
  String get topUpCredit => t('topUpCredit');
  String get selectAmount => t('selectAmount');
  String get creditBalance => t('creditBalance');
  String get continueToPayment => t('continueToPayment');
  String get customAmount => t('customAmount');
  String get minimumAmount => t('minimumAmount');
  String get searchArticles => t('searchArticles');
  String get changePhoto => t('changePhoto');
  String get fromCamera => t('fromCamera');
  String get fromGallery => t('fromGallery');
  String get photoChanged => t('photoChanged');
  String get myRiderProfile => t('myRiderProfile');
  String get creditRefunded => t('creditRefunded');
  String get clubAffiliation => t('clubAffiliation');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

const _localizedValues = {
  'cs': {
    'appTitle': 'Czech BMX',
    'news': 'Aktuality',
    'events': 'Závody',
    'riders': 'Jezdci',
    'rankings': 'Žebříček',
    'profile': 'Profil',
    'login': 'Přihlásit se',
    'logout': 'Odhlásit se',
    'retry': 'Zkusit znovu',
    'continueWithoutLogin': 'Pokračovat bez přihlášení',
    'email': 'E-mail',
    'password': 'Heslo',
    'fillEmailPassword': 'Vyplňte e-mail a heslo.',
    'loginPrompt': 'Přihlaste se ke svému účtu',
    'notLoggedIn': 'Nejste přihlášeni',
    'loginRequired': 'Přihlášení vyžadováno',
    'ridersLoginRequired': 'Pro zobrazení jezdců se musíte přihlásit.',
    'rankingsLoginRequired': 'Pro zobrazení žebříčku se musíte přihlásit.',
    'loadingFailed': 'Chyba načítání',
    'newsLoadFailed': 'Nepodařilo se načíst aktuality',
    'eventsLoadFailed': 'Nepodařilo se načíst závody',
    'rankingsLoadFailed': 'Nepodařilo se načíst žebříček',
    'noNews': 'Žádné aktuality',
    'noEvents': 'Žádné závody',
    'noRiders': 'Žádní jezdci nenalezeni',
    'searchRiders': 'Hledat jezdce...',
    'men': 'Muži',
    'women': 'Ženy',
    'themeSettings': 'Vzhled aplikace',
    'languageSettings': 'Jazyk aplikace',
    'systemTheme': 'Dle systému',
    'lightTheme': 'Světlý',
    'darkTheme': 'Tmavý',
    'audioArticle': 'Audio verze článku',
    'gallery': 'Fotogalerie',
    'minutesReadSuffix': 'min čtení',
    'viewsSuffix': 'zhlédnutí',
    'selectYear': 'Vybrat rok',
    'canceled': 'ZRUŠENO',
    'twoDays': '2 dny',
    'registrationOpen': 'Registrace otevřena',
    'international': 'Mezinárodní',
    'category': 'Kategorie',
    'dateOfBirth': 'Datum narození',
    'gender': 'Pohlaví',
    'plateNumber': 'Startovní číslo',
    'inactive': 'Neaktivní',
    'yearsSuffix': 'let',
    'noData': 'Žádná data',
    'noRidersInCategory': 'Žádní jezdci v kategorii',
    'points': 'bodů',
    'featuredArticle': 'Hlavní článek',
    'minutesShort': 'min',
    'category20': 'Kategorie 20"',
    'category24': 'Kategorie 24"',
    'doesNotRide': 'Nejezdí',
    'ranking20': 'Ranking 20"',
    'ranking24': 'Ranking 24"',
    'transponder20': 'Transpondér 20"',
    'transponder24': 'Transpondér 24"',
    'eventInfo': 'Informace o závodu',
    'eventDate': 'Datum',
    'eventType': 'Typ závodu',
    'raceSystem': 'Systém závodu',
    'raceDirector': 'Ředitel závodu',
    'format': 'Formát',
    'yes': 'Ano',
    'registrationClosed': 'Registrace uzavřena',
    'registrationFrom': 'Registrace od',
    'registrationTo': 'Registrace do',
    'unregisterTo': 'Odhlášení do',
    'register': 'Přihlásit',
    'registeredRiders': 'Přihlášení jezdci',
    'proposition': 'Propozice',
    'results': 'Výsledky',
    'documents': 'Dokumenty',
    'openOnWeb': 'Otevřít na webu',
    'navigateToTrack': 'Naviguj na trať',
    'eshopPickup': 'Výdej e-shopu',
    'place': 'Místo',
    'time': 'Čas',
    'note': 'Poznámka',
    'series': 'Rozpis jízd',
    'ridersList': 'Startovní listina',
    'fullResults': 'Kompletní výsledky',
    'xlsResults': 'Výsledky XLS',
    'fastRiders': 'Nejrychlejší jezdci',
    'registerTitle': 'Registrace',
    'registerPrompt': 'Vytvořit nový účet',
    'registerSuccess': 'Registrace proběhla',
    'registerSuccessDetail':
        'Zkontroluj e-mail a aktivuj účet kliknutím na odkaz v e-mailu.',
    'firstName': 'Jméno',
    'lastName': 'Příjmení',
    'fillAllFields': 'Vyplňte všechna pole.',
    'passwordTooShort': 'Heslo musí mít alespoň 8 znaků.',
    'passwordHint': 'Minimálně 8 znaků',
    'alreadyHaveAccount': 'Již máte účet? Přihlásit se',
    'noAccount': 'Nemáte účet? Registrovat se',
    'myEntries': 'Moje přihlášky',
    'noEntries': 'Nemáte žádné nadcházející přihlášky',
    'cancelEntry': 'Odhlásit',
    'cancelEntryConfirm':
        'Opravdu se chcete odhlásit? Poplatek bude vrácen do kreditu.',
    'cancel': 'Zrušit',
    'fee': 'Poplatek',
    'czk': 'Kč',
    'shop': 'E-shop',
    'addToCart': 'Přidat do košíku',
    'cart': 'Košík',
    'cartEmpty': 'Košík je prázdný',
    'outOfStock': 'Vyprodáno',
    'inStock': 'Skladem',
    'pieces': 'ks',
    'total': 'Celkem',
    'checkout': 'Objednat',
    'orderSuccess': 'Objednávka odeslána',
    'orderSuccessDetail': 'Děkujeme za objednávku. Brzy se vám ozveme.',
    'selectVariant': 'Vyberte variantu',
    'shopLoadFailed': 'Nepodařilo se načíst produkty',
    'phone': 'Telefon',
    'allCategories': 'Vše',
    'credit': 'Kredit',
    'topUpCredit': 'Nabít kredit',
    'selectAmount': 'Vyberte částku',
    'creditBalance': 'Zůstatek kreditu',
    'continueToPayment': 'Přejít na platbu',
    'customAmount': 'Vlastní částka',
    'minimumAmount': '100 až 10 000 Kč',
    'searchArticles': 'Hledat v článcích...',
    'changePhoto': 'Změnit fotku',
    'fromCamera': 'Fotoaparát',
    'fromGallery': 'Galerie',
    'photoChanged': 'Fotka aktualizována',
    'myRiderProfile': 'Profil jezdce',
    'creditRefunded': 'Kredit vrácen',
    'clubAffiliation': 'Tým',
  },
  'en': {
    'appTitle': 'Czech BMX',
    'news': 'News',
    'events': 'Events',
    'riders': 'Riders',
    'rankings': 'Rankings',
    'profile': 'Profile',
    'login': 'Sign in',
    'logout': 'Sign out',
    'retry': 'Try again',
    'continueWithoutLogin': 'Continue without signing in',
    'email': 'E-mail',
    'password': 'Password',
    'fillEmailPassword': 'Enter e-mail and password.',
    'loginPrompt': 'Sign in to your account',
    'notLoggedIn': 'You are not signed in',
    'loginRequired': 'Sign-in required',
    'ridersLoginRequired': 'Sign in to view riders.',
    'rankingsLoginRequired': 'Sign in to view rankings.',
    'loadingFailed': 'Loading failed',
    'newsLoadFailed': 'Could not load news',
    'eventsLoadFailed': 'Could not load events',
    'rankingsLoadFailed': 'Could not load rankings',
    'noNews': 'No news',
    'noEvents': 'No events',
    'noRiders': 'No riders found',
    'searchRiders': 'Search riders...',
    'men': 'Men',
    'women': 'Women',
    'themeSettings': 'App appearance',
    'languageSettings': 'App language',
    'systemTheme': 'System',
    'lightTheme': 'Light',
    'darkTheme': 'Dark',
    'audioArticle': 'Audio version',
    'gallery': 'Gallery',
    'minutesReadSuffix': 'min read',
    'viewsSuffix': 'views',
    'selectYear': 'Select year',
    'canceled': 'CANCELED',
    'twoDays': '2 days',
    'registrationOpen': 'Registration open',
    'international': 'International',
    'category': 'Category',
    'dateOfBirth': 'Date of birth',
    'gender': 'Gender',
    'plateNumber': 'Plate number',
    'inactive': 'Inactive',
    'yearsSuffix': 'years',
    'noData': 'No data',
    'noRidersInCategory': 'No riders in this category',
    'points': 'points',
    'featuredArticle': 'Featured',
    'minutesShort': 'min',
    'category20': '20" category',
    'category24': '24" category',
    'doesNotRide': 'Does not ride',
    'ranking20': '20" ranking',
    'ranking24': '24" ranking',
    'transponder20': '20" transponder',
    'transponder24': '24" transponder',
    'eventInfo': 'Event information',
    'eventDate': 'Date',
    'eventType': 'Event type',
    'raceSystem': 'Race system',
    'raceDirector': 'Race director',
    'format': 'Format',
    'yes': 'Yes',
    'registrationClosed': 'Registration closed',
    'registrationFrom': 'Registration from',
    'registrationTo': 'Registration to',
    'unregisterTo': 'Unregister until',
    'register': 'Register',
    'registeredRiders': 'Registered riders',
    'proposition': 'Proposition',
    'results': 'Results',
    'documents': 'Documents',
    'openOnWeb': 'Open on web',
    'navigateToTrack': 'Navigate to track',
    'eshopPickup': 'E-shop pickup',
    'place': 'Place',
    'time': 'Time',
    'note': 'Note',
    'series': 'Race schedule',
    'ridersList': 'Riders list',
    'fullResults': 'Full results',
    'xlsResults': 'XLS results',
    'fastRiders': 'Fast riders',
    'registerTitle': 'Register',
    'registerPrompt': 'Create a new account',
    'registerSuccess': 'Registration complete',
    'registerSuccessDetail':
        'Check your e-mail and activate your account by clicking the link.',
    'firstName': 'First name',
    'lastName': 'Last name',
    'fillAllFields': 'Please fill in all fields.',
    'passwordTooShort': 'Password must be at least 8 characters.',
    'passwordHint': 'Minimum 8 characters',
    'alreadyHaveAccount': 'Already have an account? Sign in',
    'noAccount': 'No account? Register',
    'myEntries': 'My registrations',
    'noEntries': 'No upcoming registrations',
    'cancelEntry': 'Unregister',
    'cancelEntryConfirm':
        'Are you sure you want to unregister? The fee will be refunded to your credit.',
    'cancel': 'Cancel',
    'fee': 'Fee',
    'czk': 'CZK',
    'shop': 'E-shop',
    'addToCart': 'Add to cart',
    'cart': 'Cart',
    'cartEmpty': 'Your cart is empty',
    'outOfStock': 'Out of stock',
    'inStock': 'In stock',
    'pieces': 'pcs',
    'total': 'Total',
    'checkout': 'Place order',
    'orderSuccess': 'Order placed',
    'orderSuccessDetail':
        'Thank you for your order. We will contact you shortly.',
    'selectVariant': 'Select a variant',
    'shopLoadFailed': 'Could not load products',
    'phone': 'Phone',
    'allCategories': 'All',
    'credit': 'Credit',
    'topUpCredit': 'Top up credit',
    'selectAmount': 'Select amount',
    'creditBalance': 'Credit balance',
    'continueToPayment': 'Continue to payment',
    'customAmount': 'Custom amount',
    'minimumAmount': '100 to 10,000 CZK',
    'searchArticles': 'Search articles...',
    'changePhoto': 'Change photo',
    'fromCamera': 'Camera',
    'fromGallery': 'Gallery',
    'photoChanged': 'Photo updated',
    'myRiderProfile': 'Rider profile',
    'creditRefunded': 'Credit refunded',
    'clubAffiliation': 'Club',
  },
};
