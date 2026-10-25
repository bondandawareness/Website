# STILL — versione finale Android

Questa versione usa il file approvato STILL_spirale_finale_preview_fluida.html dentro una WebView locale. Grafica e animazione restano quelle del file finale. Non serve una connessione per aprire la grafica o ascoltare i suoni.

## Creare l'APK con GitHub

1. Estrai lo ZIP sul computer.
2. Apri https://github.com/stillnessfromdarkness/still e scegli Add file > Upload files.
3. Carica il contenuto della cartella estratta (android, assets, lib, test, pubspec.yaml, pubspec.lock, analysis_options.yaml e README.md) nella radice del repository. Non caricare lo ZIP o una cartella esterna che racchiuda tutto. Conferma con Commit changes.
4. La cartella nascosta .github contiene il workflow aggiornato. Puoi caricarla con Git oppure aprire su GitHub il workflow esistente e sostituirne il contenuto con quello del file .github/workflows incluso. Il workflow precedente compila comunque il progetto; quello aggiornato verifica anche il collegamento HTML–Android.
5. Actions > Build STILL APK > Run workflow > main > Run workflow.
6. Quando diventa verde, apri Summary > Artifacts > STILL-Android-test. Estrai STILL-test.apk e trasferiscilo al telefono.

Non occorre un nuovo workflow: puoi riutilizzare Build STILL APK.

## Cosa cambia

- HTML finale incluso nell'app e adattato allo schermo senza cornice della preview.
- Orari, ritmo, suono, vibrazione, strumento fisso o rotazione salvati sul dispositivo.
- I sei suoni delle notifiche provengono dallo stesso HTML finale.
- Promemoria Android programmati anche quando la schermata dell'app non è aperta.
- Animazione e ascolto si fermano quando l'app passa in secondo piano.
- Indietro Android torna dalle impostazioni alla home.
- Renew reminders nelle impostazioni rinnova la programmazione e ne mostra la scadenza.

## Limiti da conoscere

È una versione da provare sul telefono, non ancora una release verificata su dispositivo fisico. La coda attuale copre al massimo 64 promemoria entro 5 giorni; con intervalli brevi può durare meno. Riaprire STILL prima della scadenza visualizzata la rinnova. Android può ritardare le notifiche per risparmio energetico e modificarne il comportamento sonoro in base al volume e alle impostazioni del telefono. La modalità Forza arresto impedisce i promemoria fino alla riapertura.

Gli APK di test sono firmati con una chiave di debug generata dal runner GitHub. Se Android rifiuta l'aggiornamento per firma diversa, occorre disinstallare la vecchia versione (perdendo le impostazioni) prima di installare questa. Per aggiornamenti stabili serve una chiave di firma permanente.

Requisito: Android 7.0 (API 24) o successivo con Android System WebView funzionante.

Il progetto conserva i vecchi componenti Flutter e i loro test come riferimento; la home attiva è lib/web_home.dart. Il disegno approvato è in assets/web/index.html; assets/web/native_bridge.js collega i controlli al codice Android. Nessun server remoto è necessario.
