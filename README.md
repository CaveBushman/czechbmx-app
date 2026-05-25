# Czech BMX App

Flutter aplikace pro Czech BMX. Aplikace načítá aktuality, závody, jezdce,
žebříčky a uživatelský profil z API na `https://czechbmx.cz`.

## Požadavky

- Flutter SDK 3.3 nebo novější
- Android SDK s `cmdline-tools`
- Pro Android build přijaté licence:

```bash
flutter doctor --android-licenses
```

## Spuštění

```bash
flutter pub get
flutter run
```

Pro spuštění proti jinému backendu:

```bash
flutter run --dart-define=API_BASE_URL=https://dev.example.cz
```

Backend `https://czechbmx.cz` nepovoluje CORS pro `localhost`, takže Flutter Web
v lokálním vývoji potřebuje proxy:

```bash
dart run tool/dev_proxy.dart
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

Pokud média běží na jiné doméně než API:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.example.cz \
  --dart-define=MEDIA_BASE_URL=https://media.example.cz
```

Pro kontrolu prostředí:

```bash
flutter doctor
```

## Testy a kontrola kódu

```bash
flutter analyze
flutter test
```

## Struktura

- `lib/main.dart` - start aplikace, theme a router
- `lib/core/network` - Dio klient, auth interceptor a ukládání tokenů
- `lib/core/router` - `go_router` konfigurace a hlavní shell
- `lib/core/theme` - light/dark palety a nastavení vzhledu
- `lib/features/news` - aktuality, detail článku a audio přehrávač
- `lib/features/events` - kalendář závodů
- `lib/features/riders` - seznam a detail jezdců
- `lib/features/rankings` - žebříčky 20" a 24"
- `lib/features/auth` - login, session restore a logout

## API

Základní URL a endpointy jsou v `lib/core/constants/api_constants.dart`.
Výchozí API i media URL jsou `https://czechbmx.cz`; při buildu je lze přepsat
přes `--dart-define=API_BASE_URL=...` a `--dart-define=MEDIA_BASE_URL=...`.
Síťová vrstva používá sdílené Dio providery:

- `dioProvider` pro požadavky s JWT auth interceptorem
- `publicDioProvider` pro login a veřejné požadavky bez auth intercept hooku

JWT tokeny se ukládají do secure storage na Android/iOS a do
`SharedPreferences` na desktopu/webu.

## Lokalizace

Aplikace je připravená na stejné jazyky jako backend `django-bmx`:

- `cs`
- `en`
- `de`
- `sk`
- `es`
- `it`
- `fr`

Locale se ukládá do `SharedPreferences` a síťová vrstva posílá zvolený jazyk v
HTTP hlavičce `Accept-Language`. Zatím jsou plně založené české a anglické UI
řetězce; ostatní jazyky jsou připravené v přepínači a můžou se doplňovat
postupně v `lib/core/l10n/app_localizations.dart`.

## CI

GitHub Actions workflow je v `.github/workflows/flutter.yml` a na push/pull
request spouští:

```bash
flutter pub get
flutter analyze
flutter test
```
