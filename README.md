# Latente

Latente è una app Flutter locale per camera oscura e sviluppo analogico.
Funziona come quaderno tecnico digitale per archiviare pellicole, chimici,
ricette di sviluppo, calcolare tempi corretti e guidare una lavorazione con
timer operativo.

## Funzioni MVP

- Home in italiano con accesso rapido alle sezioni principali.
- Archivio pellicole modificabile.
- Archivio chimici con diluizioni, one-shot, utilizzi massimi e regole usura.
- Ricette sviluppo con pellicola, ISO, rivelatore, diluizione, temperatura,
  tempo base, agitazione, fonte e note.
- Nuovo sviluppo con calcolo trasparente:
  - tempo base
  - correzione temperatura
  - correzione usura chimica
  - correzione push/pull
  - tempo finale
- Timer con fasi: sviluppo, arresto, fissaggio, lavaggio, imbibente.
- Promemoria agitazione: 30 secondi iniziali, poi 10 secondi ogni minuto.
- Storico lavorazioni con note, valutazione risultato e riuso dei dati salvati.
- Impostazioni con backup JSON, import file tecnico e anteprima prima del salvataggio.

## Dati locali

L'app non usa backend, login, autenticazione o servizi cloud. I dati vengono
salvati localmente sul dispositivo.

I dati iniziali sono esempi fittizi modificabili e devono essere verificati
dall'operatore prima di ogni lavorazione:

- Ilford HP5 Plus 400
- Kodak Tri-X 400
- Kentmere 400
- Ilford ID-11
- Kodak D-76
- Rodinal

## Avvio Android

```bash
flutter pub get
flutter run -d android
```

## Build iOS

Per creare un IPA o distribuire con TestFlight serve un Mac con Xcode.
Segui la guida dedicata:

```text
GUIDA_IOS_IPA_TESTFLIGHT.md
```

## Note tecniche

La correzione temperatura MVP usa una regola semplice:

- 20°C: nessuna correzione
- ogni grado sopra la temperatura di riferimento: -10%
- ogni grado sotto la temperatura di riferimento: +10%

La correzione push/pull MVP è una base modificabile nel codice:

- push: +20% per stop
- pull: -10% per stop

Queste regole sono volutamente semplici e vanno affinate con dati tecnici
verificati.
