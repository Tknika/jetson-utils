#!/bin/bash

# Flash script for Jetson Nano using NVIDIA SDK Manager
# This script helps you flash a backup using NVIDIA SDK Manager
# Author: mikel.diez@somorrostro.com

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Este script necesita permisos de root"
    echo "Ejecuta: sudo $0 <archivo_backup.img.gz>"
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

# Get file size
FILE_SIZE=$(stat -c%s "$BACKUP_FILE")
echo "Tamaño del archivo de backup: $(numfmt --to=iec $FILE_SIZE)"

echo "=== Iniciando proceso de flasheo con NVIDIA SDK Manager ==="
echo "1. Abre NVIDIA SDK Manager"
echo "2. Selecciona tu Jetson Nano"
echo "3. En la sección 'Flash OS Image':"
echo "   - Selecciona 'Restore'"
echo "   - Selecciona el archivo: $BACKUP_FILE"
echo "4. Sigue las instrucciones en pantalla"
echo ""
echo "Nota: Asegúrate de que el Jetson Nano está en modo Recovery"
echo "      Para entrar en modo Recovery:"
echo "      1. Desconecta la alimentación"
echo "      2. Mantén presionado el botón RECOVERY"
echo "      3. Conecta la alimentación mientras mantienes RECOVERY"
echo "      4. Suelta RECOVERY después de 2 segundos"
echo ""
echo "¿Has completado el flasheo con SDK Manager? (s/N): "
read CONFIRM
if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo "Operación cancelada"
    exit 1
fi

echo "=== ¡Proceso completado! ==="
echo "La SD está lista para usar en tu Jetson Nano"
echo "Puedes extraer la tarjeta de forma segura" 