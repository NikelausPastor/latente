# Latente - Guida iOS, IPA e TestFlight

Questa guida e pensata per una persona Apple che non ha mai creato un'app.
Latente e una app Flutter: il codice e gia pronto, ma la creazione di un file
IPA iOS richiede obbligatoriamente un Mac con Xcode e una firma Apple valida.

## Punto importante

Su iPhone non esiste un equivalente libero dell'APK Android.
Un file `.ipa` non si installa su qualunque iPhone se non e firmato nel modo
giusto. Le strade realistiche sono:

- Test diretto su un proprio iPhone collegato al Mac: possibile anche con
  account Apple gratuito, ma non e una distribuzione comoda.
- IPA Ad Hoc: condivisibile solo con i dispositivi registrati nel profilo di
  provisioning Apple.
- TestFlight: soluzione consigliata per mandare l'app a tester senza gestire
  manualmente ogni installazione.
- App Store: distribuzione pubblica finale.

Per condividere Latente con altre persone, usa TestFlight.

## Cosa installare sul Mac

1. macOS aggiornato.
2. Xcode, installato dal Mac App Store.
3. Command Line Tools di Xcode.
4. Flutter SDK stabile.
5. CocoaPods.
6. Un editor, per esempio Visual Studio Code.
7. Un Apple Account.
8. Apple Developer Program, se vuoi TestFlight, Ad Hoc o App Store.
9. App TestFlight sugli iPhone dei tester.
10. App Transporter su Mac, opzionale ma comoda per caricare l'IPA.

Comandi utili dopo aver installato Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

Controllo Flutter:

```bash
flutter doctor
```

Se Flutter segnala CocoaPods mancante:

```bash
sudo gem install cocoapods
```

oppure, se usi Homebrew:

```bash
brew install cocoapods
```

## Importare Latente sul Mac

1. Copia lo ZIP del progetto Latente sul Mac.
2. Estrai lo ZIP, per esempio sulla Scrivania.
3. Apri Terminale.
4. Entra nella cartella:

```bash
cd ~/Desktop/Latente_iOS_source
```

5. Scarica le dipendenze:

```bash
flutter pub get
```

6. Genera la cartella iOS, se non e presente:

```bash
flutter create --platforms=ios --org it.tuonome --project-name latente .
```

Sostituisci `it.tuonome` con un identificatore tuo. Per esempio:
`it.mariorossi.latente`. Il Bundle Identifier finale diventera
`it.mariorossi.latente`.

7. Apri il progetto iOS:

```bash
open ios/Runner.xcworkspace
```

## Configurare Xcode

In Xcode:

1. A sinistra seleziona `Runner`.
2. Seleziona il target `Runner`.
3. Vai su `Signing & Capabilities`.
4. Attiva `Automatically manage signing`.
5. In `Team`, scegli il tuo account Apple Developer.
6. Controlla il `Bundle Identifier`.
7. Vai su `General`.
8. Imposta `Display Name` su `Latente`.
9. Controlla `Version` e `Build`.

Esempio:

- Version: `0.1.0`
- Build: `1`

Ogni upload a TestFlight deve avere un numero Build nuovo: 1, 2, 3, ecc.

## Provare su iPhone collegato

1. Collega l'iPhone al Mac.
2. Sblocca l'iPhone e autorizza il Mac.
3. In Xcode scegli il dispositivo fisico in alto.
4. Premi Run.

Oppure da Terminale:

```bash
flutter devices
flutter run -d ID_DEL_DISPOSITIVO
```

## Creare un IPA

Dal Terminale nella cartella del progetto:

```bash
flutter clean
flutter pub get
flutter build ipa --release --build-name 0.1.0 --build-number 1
```

Risultato atteso:

```text
build/ios/ipa/*.ipa
```

Se la firma non e configurata, Flutter/Xcode chiedera di sistemare Team,
Bundle Identifier e provisioning profile.

## IPA Ad Hoc

Usa Ad Hoc solo se vuoi installare l'app su pochi dispositivi specifici.
Serve:

1. Apple Developer Program.
2. App ID.
3. Certificato di distribuzione.
4. UDID degli iPhone da autorizzare.
5. Profilo di provisioning Ad Hoc.

Poi puoi creare:

```bash
flutter build ipa --release --export-method ad-hoc
```

Il file IPA funzionera solo sui dispositivi registrati nel provisioning profile.

## TestFlight consigliato

TestFlight e il metodo migliore per condividere Latente con tester.

Procedura:

1. Vai su App Store Connect.
2. Crea una nuova app iOS chiamata `Latente`.
3. Usa lo stesso Bundle Identifier configurato in Xcode.
4. Crea l'IPA:

```bash
flutter build ipa --release --build-name 0.1.0 --build-number 1
```

5. Carica l'IPA con Transporter oppure da Xcode Organizer.
6. In App Store Connect vai su TestFlight.
7. Aggiungi tester interni o esterni.
8. I tester installano l'app TestFlight e accettano l'invito.

Per tester esterni, il primo build puo richiedere una revisione beta Apple.

## Cosa mandare a chi compila su Mac

Manda lo ZIP del progetto sorgente, non la cartella `build`.
Nel pacchetto servono:

- `lib/`
- `assets/`
- `pubspec.yaml`
- `pubspec.lock`
- `README.md`
- `GUIDA_IOS_IPA_TESTFLIGHT.md`
- `analysis_options.yaml`
- `.metadata`
- `.gitignore`
- `android/` opzionale, utile se vuoi tenere anche la build Android

La cartella `ios/` puo essere generata sul Mac con il comando:

```bash
flutter create --platforms=ios --org it.tuonome --project-name latente .
```

## Fonti ufficiali

- Flutter iOS deployment: https://docs.flutter.dev/deployment/ios
- Apple Developer Program: https://developer.apple.com/programs/
- TestFlight: https://developer.apple.com/testflight/
- TestFlight overview: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- Ad Hoc provisioning: https://developer.apple.com/help/account/provisioning-profiles/create-an-ad-hoc-provisioning-profile/
