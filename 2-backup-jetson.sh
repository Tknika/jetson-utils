#!/bin/bash

# Backup script for Jetson Nano using dd command
# Author: mikel.diez@somorrostro.com

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Este script necesita permisos de root"
    echo "Ejecuta: sudo $0"
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

# Get backup filename
BACKUP_DATE=$(date +%Y%m%d)
BACKUP_FILE="jetson_backup_${BACKUP_DATE}.img"

# Find SD card
find_sd_card

echo "=== Iniciando backup de la tarjeta SD ==="
echo "Dispositivo origen: /dev/$DEVICE"
echo "Archivo destino: $BACKUP_FILE"
echo ""
echo "ADVERTENCIA: Este proceso puede tardar varios minutos"
echo "            No extraigas la tarjeta SD durante el proceso"
echo ""
read -p "¿Continuar con el backup? (s/N): " CONFIRM
if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo "Operación cancelada"
    exit 1
fi

# Create backup using dd with progress
echo "Creando backup..."
dd if=/dev/$DEVICE of=$BACKUP_FILE bs=1M status=progress

# Compress the image
echo "Comprimiendo backup..."
gzip -f $BACKUP_FILE

echo "=== Backup completado ==="
echo "Archivo: ${BACKUP_FILE}.gz"
echo "Tamaño: $(du -h ${BACKUP_FILE}.gz | cut -f1)"
echo ""
echo "Puedes usar este archivo con el script 3-flash-jetson.sh para restaurar la imagen"
echo "Recuerda que los archivos .img.gz están en .gitignore para evitar subirlos al repositorio" 