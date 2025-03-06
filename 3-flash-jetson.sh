#!/bin/bash

# Flash script for Jetson Nano backup
# This script flashes a compressed backup to a new SD card
# Author: mikel.diez@somorrostro.com

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Este script necesita permisos de root"
    echo "Ejecuta: sudo $0"
    exit 1
fi

# Check if backup file is provided
if [ "$#" -ne 1 ]; then
    echo "Uso: sudo $0 <archivo_backup.img.gz>"
    echo "Ejemplo: sudo $0 jetson_backup_20240315.img.gz"
    exit 1
fi

BACKUP_FILE=$1

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

# List available devices
echo "=== Dispositivos de almacenamiento disponibles ==="
lsblk -d -o NAME,SIZE,MODEL,VENDOR | grep -v "loop"
echo "================================================="

# Ask for target device
read -p "Introduce el dispositivo destino (ejemplo: sdb, mmcblk0): " TARGET_DEVICE

# Validate device exists
if [ ! -b "/dev/$TARGET_DEVICE" ]; then
    echo "Error: El dispositivo /dev/$TARGET_DEVICE no existe"
    exit 1
fi

# Safety check for system drives
if echo "$TARGET_DEVICE" | grep -q "nvme\|sda"; then
    echo "¡ADVERTENCIA! Has seleccionado un dispositivo que podría ser el disco del sistema."
    echo "Esto podría borrar tu sistema operativo."
    read -p "¿Estás ABSOLUTAMENTE seguro de continuar? (escribe 'SI' en mayúsculas): " CONFIRM
    if [ "$CONFIRM" != "SI" ]; then
        echo "Operación cancelada"
        exit 1
    fi
fi

# Final confirmation
echo "¡ADVERTENCIA! Esto borrará TODOS los datos en /dev/$TARGET_DEVICE"
echo "Tamaño del dispositivo: $(lsblk -d -o SIZE /dev/$TARGET_DEVICE | tail -n1)"
read -p "¿Estás seguro de continuar? (s/N): " CONFIRM
if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo "Operación cancelada"
    exit 1
fi

echo "=== Iniciando proceso de flasheo ==="
echo "Origen: $BACKUP_FILE"
echo "Destino: /dev/$TARGET_DEVICE"

# Unmount any partitions of the target device
echo "Desmontando particiones..."
for partition in $(lsblk -n -o NAME /dev/$TARGET_DEVICE | tail -n +2); do
    umount "/dev/$partition" 2>/dev/null || true
done

# Flash the image
echo "Flasheando imagen (esto puede tardar varios minutos)..."
gunzip -c "$BACKUP_FILE" | dd of="/dev/$TARGET_DEVICE" bs=64K status=progress
sync

echo "=== Expandiendo partición ==="
if [[ "$TARGET_DEVICE" == "mmcblk"* ]]; then
    PART_SUFFIX="p1"
else
    PART_SUFFIX="1"
fi

# Wait a moment for the kernel to recognize the new partition table
sleep 2

# Expand the filesystem
resize2fs "/dev/$TARGET_DEVICE$PART_SUFFIX"

echo "=== ¡Proceso completado! ==="
echo "La SD está lista para usar en tu Jetson Nano"
echo "Puedes extraer la tarjeta de forma segura" 