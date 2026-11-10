# AirPrint (gepatcht)

Fork von [aaronfagan/ha-airprint](https://github.com/aaronfagan/ha-airprint) 1.12.0 (MIT, siehe LICENSE).
Baut auf dem fertigen Original-Image auf und ersetzt nur `run.sh`, `monitor.sh`, `drivers.sh` (+ neues `match.sh`).
Die Integration (custom_components/airprint) bleibt die originale.

## Was der Patch behebt
1. **Per IP eingetragene Drucker bekamen nie einen Treiber.** Das Original nimmt den Treiber nur aus der
   Bonjour-Suche (`_pdl-datastream`). Drucker, die das nicht ankündigen (z. B. Kyocera FS-1135MFP, nur `_printer`),
   blieben ewig bei „no driver matched yet“. Jetzt (`match.sh`): PPD aus dem „driver“-Link → SNMP-Geräte-ID → Name.
   Ein Treffer muss den Modellteil des Namens enthalten (z. B. „FS-1135MFP“), damit nichts Falsches gewählt wird.
2. **Treiberpakete werden am Inhalt erkannt**, nicht an der Endung (Kyocera liefert `*_tar_gz.download.gz`).

## Update auf eine neue Original-Version
`build.yaml` (Image-Tag) und `version` in `config.yaml` anheben, die drei Skripte aus dem Original übernehmen
und die mit „Patch (ha1)“ markierten Stellen wieder einsetzen.
