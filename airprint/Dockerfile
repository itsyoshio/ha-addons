ARG BUILD_FROM
FROM ${BUILD_FROM}

# Gepatchte Skripte über die des Originals legen (Original: aaronfagan/ha-airprint 1.12.0, MIT)
COPY run.sh /run.sh
COPY monitor.sh /monitor.sh
COPY drivers.sh /drivers.sh
COPY match.sh /match.sh
RUN chmod +x /run.sh /monitor.sh /drivers.sh /match.sh

CMD ["/run.sh"]
