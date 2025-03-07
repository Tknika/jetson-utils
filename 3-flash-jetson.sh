#!/bin/bash

# Flash script for Jetson Nano using dd command
# Author: mikel.diez@somorrostro.com

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Este script necesita permisos de root"
    echo "Ejecuta: sudo $0 <archivo_backup.img.gz>"
    exit 1
fi

# Check if backup file is provided
if [ "$#" -ne 1 ]; then
    echo "Uso: sudo $0 <archivo_backup.img.gz>"
    echo "Ejemplo: sudo $0 jetson_backup_20240315.img.gz"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: No se encuentra el archivo $BACKUP_FILE"
    exit 1
fi

# Check if it's a gzip file
if ! file "$BACKUP_FILE" | grep -q "gzip"; then
    echo "Error: El archivo debe ser un backup comprimido con gzip (.img.gz)"
    exit 1
fi

# Function to find SD card device
find_sd_card() {
    echo "Buscando tarjeta SD..."
    
    # List all block devices that could be SD cards
    echo "Dispositivos disponibles:"
    lsblk -d -o NAME,SIZE,MODEL,TRAN | grep "mmc\|sd"
    echo ""
    
    # Ask user to specify device
    read -p "Introduce el nombre del dispositivo (ejemplo: mmcblk0 o sdb): " DEVICE
    
    if [ ! -b "/dev/$DEVICE" ]; then
        echo "Error: /dev/$DEVICE no es un dispositivo válido"
        exit 1
    fi
    
    echo "Usando dispositivo: /dev/$DEVICE"
    return 0
}

# Get file size
FILE_SIZE=$(stat -c%s "$BACKUP_FILE")
echo "Tamaño del archivo de backup: $(numfmt --to=iec $FILE_SIZE)"

# Find SD card
find_sd_card

echo "=== Iniciando proceso de flasheo ==="
echo "Archivo origen: $BACKUP_FILE"
echo "Dispositivo destino: /dev/$DEVICE"
echo ""
echo "ADVERTENCIA: ¡Este proceso borrará TODOS los datos en /dev/$DEVICE!"
echo "            Asegúrate de que es el dispositivo correcto"
echo "            No extraigas la tarjeta SD durante el proceso"
echo ""
read -p "¿Continuar con el flasheo? (s/N): " CONFIRM
if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo "Operación cancelada"
    exit 1
fi

# Flash the image using dd with progress
echo "Descomprimiendo y flasheando imagen..."
gunzip -c "$BACKUP_FILE" | dd of=/dev/$DEVICE bs=1M status=progress

# Sync to ensure all data is written
echo "Sincronizando..."
sync

echo "=== ¡Proceso completado! ==="
echo "La SD está lista para usar en tu Jetson Nano"
echo "Puedes extraer la tarjeta de forma segura" 