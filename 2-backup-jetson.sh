#!/bin/bash

# Backup script for Jetson Nano
# This script creates a compressed backup of the system
# Author: mikel.diez@somorrostro.com

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Este script necesita permisos de root"
    echo "Ejecuta: sudo $0"
    exit 1
fi

# Get current date for backup name
DATE=$(date +%Y%m%d)
BACKUP_NAME="jetson_backup_${DATE}.img.gz"

# Ensure system is synced before backup
sync

echo "=== Iniciando backup de Jetson Nano ==="
echo "El backup se guardará como: $BACKUP_NAME"

# Get root partition device
ROOT_PART=$(findmnt / -n -o SOURCE)
ROOT_DEV=$(lsblk -no pkname $ROOT_PART | sed 's/^/\/dev\//')

# Get used space in bytes
USED_BYTES=$(df -B1 / | awk 'NR==2 {print $3}')
# Add 10% margin for safety
BACKUP_SIZE=$(echo "$USED_BYTES * 1.1" | bc | cut -d'.' -f1)

echo "Espacio usado: $(($USED_BYTES/1024/1024)) MB"
echo "Tamaño de backup (con margen): $(($BACKUP_SIZE/1024/1024)) MB"

# Create backup with progress
echo "Creando backup comprimido..."
dd if=$ROOT_DEV bs=64K count=$(($BACKUP_SIZE/65536)) status=progress | gzip -c > $BACKUP_NAME

echo "=== Backup completado ==="
echo "Para restaurar en otro Jetson Nano:"
echo "1. Arranca el Jetson Nano con una SD de rescate"
echo "2. Ejecuta: gunzip -c $BACKUP_NAME | sudo dd of=/dev/mmcblk0 bs=64K status=progress"
echo "3. Expande la partición con: sudo resize2fs /dev/mmcblk0p1"

# Calculate final size
FINAL_SIZE=$(ls -lh $BACKUP_NAME | awk '{print $5}')
echo "Tamaño final del backup: $FINAL_SIZE" 