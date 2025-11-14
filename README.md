# ILove2Cook

## CI: Android APK build (GitHub Actions)

Er is een GitHub Actions workflow toegevoegd die automatisch een Android APK (en AAB) bouwt bij push/PR naar `main`.

- Trigger: push naar `main`, pull_request naar `main`, of handmatig via `workflow_dispatch`.
- Artefacten: de gegenereerde APK(s) en AAB worden geüpload als artifact `android-builds`.

Automatisch scaffolden
- Als er geen `pubspec.yaml` in de repository aanwezig is, zal de workflow eerst `flutter create .` uitvoeren op de runner om een minimale Flutter-projectstructuur te genereren. Hierdoor kun je de workflow gebruiken zonder dat de volledige Flutter-projectbestanden al in de repo staan.

Hoe te gebruiken:

1. Push je Flutter-project (zorg dat `android/` en `pubspec.yaml` aanwezig zijn).
2. Ga naar de Actions-tab in GitHub en start de workflow of bekijk een recente run.
3. Download de artifact `android-builds` uit de succesvolle workflow run.

Opmerking over release-signing:
- De workflow bouwt release APK/AAB maar signeert deze niet met een privé-keystore. Als je een gesigneerde release wilt, voeg je je keystore als GitHub Secret en pas je `android/app/build.gradle` aan om die te gebruiken (ik kan helpen met die configuratie).

Release signing via GitHub Actions
- De workflow kan automatisch een keystore decoderen en gebruiken wanneer je de volgende GitHub Secrets toevoegt:
	- `ANDROID_KEYSTORE` (base64 van je `.jks` bestand)
	- `KEYSTORE_PASSWORD`
	- `KEY_ALIAS`
	- `KEY_PASSWORD`

Voorbeeld om een keystore lokaal te maken en te encoderen:
```bash
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -w0 upload-keystore.jks > upload-keystore.jks.base64
```
Upload de inhoud van `upload-keystore.jks.base64` als de waarde van de secret `ANDROID_KEYSTORE`.

De workflow zal, wanneer die secret aanwezig is, de keystore decoderen naar `android/app/upload-keystore.jks`, een `android/key.properties` aanmaken en het `build.gradle` patchen zodat de release build automatisch met die keystore gesigneerd wordt.

Als je wilt dat ik ook een minimale Flutter scaffolding toevoeg (zodat de repo direct buildbaar is), zeg het dan en ik maak die aan.
voeg flutter scaffolding toe

Assets & app icon
- Er is een simple SVG-logo toegevoegd in `assets/logo.svg`.
- Je kunt de launcher icons genereren met `flutter_launcher_icons`:

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

Het `pubspec.yaml` bevat al een `flutter_icons` configuratie die `assets/logo.svg` gebruikt.

CI veranderingen
- De GitHub Actions workflow draait nu `flutter doctor -v` en zal proberen `flutter_launcher_icons` uit te voeren (als `assets/logo.svg` aanwezig is) vóór het bouwen. Dit helpt met debuggen en genereert launcher icons automatisch in CI als gewenst.

Receptsuggesties & filters
- Er is een `Receptsuggesties`-scherm toegevoegd (`lib/recipes.dart`) dat mock-recepten bevat en suggesties geeft op basis van de ingrediënten die je in `Ingredients` bewaart. Gebruik de filterchips (Halal, Vegan, Snel, Gezond) om resultaten te verfijnen.

Hoe te gebruiken
1. Voeg ingrediënten toe in de app (floating +).  
2. Open `Receptsuggesties` via het bord-icoon rechtsboven in de `Ingrediënten`-pagina.  
3. Schakel filters aan/uit en bekijk welke recepten matchen met jouw voorraad.
  
Demo screenshots / GIF
--
Je kunt eenvoudig een korte demo GIF maken van de app (lokale emulator of verbonden Android-apparaat). Er is een helper-script toegevoegd: `scripts/capture_demo.sh`.

Vereisten (lokaal): `adb` (Android platform-tools) en `ffmpeg`.

Voorbeeld:
```bash
# start je emulator of verbind een apparaat en zorg dat de app draait
flutter pub get
flutter run -d <emulator-or-device>  # start de app
# in een ander terminal venster run:
./scripts/capture_demo.sh --frames 6 --delay 1 --out ilove2cook-demo.gif
```

Het script maakt meerdere screenshots via `adb`, genereert een palet en produceert `ilove2cook-demo.gif` in de repository root.

Als alternatief kun je individuele screenshots maken met:
```bash
flutter screenshot --out=shot.png
```
en die met `ffmpeg` of `convert` samenvoegen tot een GIF.
