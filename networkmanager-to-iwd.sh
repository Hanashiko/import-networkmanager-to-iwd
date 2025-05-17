#!/bin/bash

NM_DIR="/etc/NetworkManager/system-connections"
IWD_DIR="/var/lib/iwd"

if [[ $EUID -ne 0 ]]; then
  echo "Запусти скрипт через sudo або як root."
  exit 1
fi

if [ ! -d "$NM_DIR" ]; then
  echo "Не знайдено папки $NM_DIR"
  exit 1
fi

echo "Починаємо перенесення мереж з NetworkManager в iwd..."

for FILE in "$NM_DIR"/*.nmconnection; do
    [ -e "$FILE" ] || continue

    SSID=$(grep '^ssid=' "$FILE" | head -n1 | cut -d'=' -f2 | tr -d '"')
    PSK=$(grep '^psk=' "$FILE" | head -n1 | cut -d'=' -f2)

    if [[ -z "$SSID" ]]; then
        echo "Пропущено $FILE (немає SSID)"
        continue
    fi

    PROFILE="$IWD_DIR/${SSID}.psk"

    echo "Створюємо профіль для SSID: $SSID"

    {
      if [[ -n "$PSK" ]]; then
        echo "[Security]"
        echo "PreSharedKey=$PSK"
      else
        echo "[Security]"
        echo "KeyManagement=none"
      fi

      echo
      echo "[Settings]"
      echo "AutoConnect=true"
      echo
      echo "[IPv4]"
      echo "Method=auto"
      echo
      echo "[IPv6]"
      echo "Method=auto"
    } > "$PROFILE"

    chmod 600 "$PROFILE"
done

echo "Готово! Перевір профілі в $IWD_DIR."

read -p "Перезапустити iwd зараз? (y/n) " yn
case $yn in
    [Yy]* ) systemctl restart iwd; echo "iwd перезапущено.";;
    * ) echo "Окей, не перезапускаю.";;
esac
