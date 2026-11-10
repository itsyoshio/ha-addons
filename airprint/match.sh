#!/usr/bin/env bash
# Treiber für einen Drucker, den discover.sh nicht per Bonjour (_pdl-datastream) gefunden hat.
#   match.sh <device-uri> <name> [driver-url]
# Reihenfolge: 1. PPD aus dem "driver"-Link  2. SNMP-Geräte-ID (IEEE 1284)  3. Name (Hersteller + Modell)
# Gibt den CUPS-Modellnamen für lpadmin -m aus, sonst nichts.
set -uo pipefail

DEVICE=${1:-}
NAME=${2:-}
URL=${3:-}

# Emoji o. Ä. vorne am Namen (Label) weg
NAME=$(printf '%s' "${NAME}" | sed 's/^[^A-Za-z0-9]*//')

# 1. "driver" zeigt auf eine einzelne PPD → die ist installiert (drivers.sh) → direkt nehmen
if [ -n "${URL}" ]; then
	file="${URL##*/}"
	file="${file%%\?*}"
	case "${file}" in
	*.ppd | *.ppd.gz)
		if [ -f "/usr/share/cups/model/${file}" ]; then
			printf '%s' "${file}"
			exit 0
		fi
		;;
	esac
fi

host_of() {
	local hp=${1#*://}
	hp=${hp%%/*}
	hp=${hp##*@}
	printf '%s' "${hp%%:*}"
}

# Modellteil des Namens (letztes Wort mit einer Ziffer, z. B. FS-1135MFP) zum Plausibilisieren
TOKEN=$(printf '%s' "${NAME}" | tr ' ' '\n' | grep '[0-9]' | tail -1)

plausible() {
	# $1 = Zeile aus lpinfo -m ("modell make-and-model"); ohne Modellteil im Namen nichts prüfen
	[ -z "${TOKEN}" ] && return 0
	printf '%s' "$1" | grep -qiF "${TOKEN}"
}

pick() {
	local line
	while read -r line; do
		[ -n "${line}" ] || continue
		if plausible "${line}"; then
			printf '%s' "${line%% *}"
			return 0
		fi
	done
	return 1
}

# 2. Geräte-ID per SNMP (Printer-MIB ppmPrinterIEEE1284DeviceId, sonst CUPS-snmp-Backend)
HOST=$(host_of "${DEVICE}")
if [ -n "${HOST}" ]; then
	ID=$(snmpget -v1 -c public -t 2 -r 1 -Oqv "${HOST}" 1.3.6.1.4.1.2699.1.2.1.2.1.1.3.1 2>/dev/null | tr -d '"')
	if [ -z "${ID}" ] && [ -x /usr/lib/cups/backend/snmp ]; then
		ID=$(/usr/lib/cups/backend/snmp "${HOST}" 2>/dev/null | grep -o '"[^"]*MFG:[^"]*"' | head -1 | tr -d '"')
	fi
	if [ -n "${ID}" ]; then
		D=$(lpinfo --device-id "${ID}" -m 2>/dev/null | head -5 | pick) && { printf '%s' "${D}"; exit 0; }
		MFG=$(printf '%s' "${ID}" | grep -o 'MFG:[^;]*' | head -1 | cut -d: -f2)
		MDL=$(printf '%s' "${ID}" | grep -o 'MDL:[^;]*' | head -1 | cut -d: -f2)
		[ -n "${TOKEN}" ] || TOKEN=$(printf '%s' "${MDL}" | tr ' ' '\n' | grep '[0-9]' | tail -1)
		if [ -n "${MDL}" ]; then
			D=$(lpinfo --make-and-model "${MFG} ${MDL}" -m 2>/dev/null | head -5 | pick) && { printf '%s' "${D}"; exit 0; }
		fi
	fi
fi

# 3. Name, wie in Home Assistant eingetragen (z. B. "Kyocera FS-1135MFP")
if [ -n "${NAME}" ]; then
	D=$(lpinfo --make-and-model "${NAME}" -m 2>/dev/null | head -5 | pick) && { printf '%s' "${D}"; exit 0; }
fi

exit 0
