#!/bin/bash

# Backup script for Jetson Nano using NVIDIA SDK Manager
# Author: mikel.diez@somorrostro.com

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Este script necesita permisos de root"
    echo "Ejecuta: sudo $0"
    exit 1
fi

# Function to check SDK Manager installation
check_sdk_manager() {
    echo "Verificando instalación de NVIDIA SDK Manager..."
    
    # Check if sdkmanager command exists
    if ! command -v sdkmanager &> /dev/null; then
        echo "NVIDIA SDK Manager no está instalado"
        echo ""
        echo "Para instalar NVIDIA SDK Manager:"
        echo "1. Descarga el instalador desde: https://developer.nvidia.com/sdk-manager"
        echo "2. Abre una terminal y ejecuta:"
        echo "   sudo apt update"
        echo "   sudo apt install -y libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-liberation libasound2 libcurl3 lsb-release xdg-utils"
        echo "3. Navega a la carpeta de descarga y ejecuta:"
        echo "   sudo dpkg -i sdkmanager_*.deb"
        echo "4. Si hay errores de dependencias, ejecuta:"
        echo "   sudo apt --fix-broken install"
        echo ""
        echo "Después de instalar SDK Manager, ejecuta este script de nuevo"
        exit 1
    fi
    
    # Check if SDK Manager can be launched
    if ! sdkmanager --version &> /dev/null; then
        echo "Error al ejecutar SDK Manager"
        echo "Por favor, verifica la instalación o reinstala SDK Manager"
        exit 1
    fi
    
    echo "NVIDIA SDK Manager está instalado correctamente"
    echo ""
}

# Verify SDK Manager installation
check_sdk_manager

# Get current date for backup filename
BACKUP_DATE=$(date +%Y%m%d)
BACKUP_FILE="jetson_backup_${BACKUP_DATE}.img.gz"

echo "=== Iniciando backup con NVIDIA SDK Manager ==="
echo "1. Abre NVIDIA SDK Manager"
echo "2. Selecciona tu Jetson Nano"
echo "3. En la sección 'Flash OS Image':"
echo "   - Selecciona 'Backup'"
echo "   - Guarda el backup como: $BACKUP_FILE"
echo "4. Sigue las instrucciones en pantalla"
echo ""
echo "Nota: El backup se guardará en la ubicación que elijas en SDK Manager"
echo "      Por defecto, suele ser en ~/nvidia/nvidia_sdk/backup/"
echo ""
echo "¿Has completado el backup con SDK Manager? (s/N): "
read CONFIRM
if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo "Operación cancelada"
    exit 1
fi

echo "=== Backup completado ==="
echo "El archivo de backup se encuentra en la ubicación que especificaste en SDK Manager"
echo "Recuerda que los archivos .img.gz están en .gitignore para evitar subirlos al repositorio" 