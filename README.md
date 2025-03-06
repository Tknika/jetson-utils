# Configuración de TensorRT para Jetson Nano - Control de Calidad

Este repositorio contiene tres scripts para configurar, respaldar y clonar Jetson Nanos para el proyecto de Control de Calidad.

## Scripts Disponibles

1. `1-setup-tensorrt.sh`: Configura TensorRT y Edge Impulse
2. `2-backup-jetson.sh`: Crea un backup comprimido del sistema
3. `3-flash-jetson.sh`: Flashea el backup a nuevas tarjetas SD

## Requisitos Previos

- Jetson Nano con JetPack instalado
- Conexión a internet
- Fuente de alimentación adecuada (recomendada para máximo rendimiento)
- Espacio en disco suficiente para backups
- Tarjeta SD de al menos 16GB para nuevas instalaciones

## 1. Script de Configuración (1-setup-tensorrt.sh)

### Qué hace
- Instala las herramientas de Edge Impulse
- Instala el compilador Clang
- Clona el repositorio de inferencia de Edge Impulse
- Instala OpenCV
- Configura las rutas de las bibliotecas CUDA
- Modifica el tipo de modelo FOMO en el código fuente

### Uso
```bash
chmod +x 1-setup-tensorrt.sh
./1-setup-tensorrt.sh
```

### Pasos Posteriores
1. Extrae tu modelo TensorRT desde Edge Impulse Studio
2. Compila el modelo:
```bash
APP_EIM=1 TARGET_JETSON_NANO=1 CC=clang CXX=clang++ CXXFLAGS="-std=c++17" make -j
```

Si hay errores, usa estos flags:
```bash
APP_EIM=1 TARGET_JETSON_NANO=1 CC=clang CXX=clang++ CXXFLAGS="-std=c++17 -Wno-deprecated-declarations" LDFLAGS="-L/usr/local/cuda-10.2/lib64 -lstdc++fs" make -j
```

3. Maximiza el rendimiento:
```bash
sudo /usr/bin/jetson_clocks
```

4. Prueba el modelo:
```bash
edge-impulse-linux-runner --model-file ./build/model.eim
```

### Opción Python
El script ofrece instalar el SDK de Python:
```bash
python3 topping.py ~/build/model.eim
```

## 2. Script de Backup (2-backup-jetson.sh)

### Características
- Backup comprimido (reduce significativamente el tamaño)
- Solo respalda el espacio usado (no espacio vacío)
- Incluye barra de progreso
- Añade 10% de margen de seguridad
- Nombra el archivo con la fecha actual

### Uso
```bash
sudo ./2-backup-jetson.sh
```

El backup se guardará como `jetson_backup_YYYYMMDD.img.gz`

## 3. Script de Flasheo (3-flash-jetson.sh)

### Características
- Comprobaciones de seguridad para evitar borrar discos del sistema
- Validación del archivo de backup
- Desmontaje automático de particiones
- Expansión automática de la partición
- Muestra progreso en tiempo real

### Uso
```bash
sudo ./3-flash-jetson.sh jetson_backup_YYYYMMDD.img.gz
```

### Proceso de Flasheo
1. El script mostrará los dispositivos disponibles
2. Selecciona el dispositivo destino (ejemplo: sdb, mmcblk0)
3. Confirma las advertencias de seguridad
4. Espera a que termine el proceso

## Solución de Problemas

### Problemas de CUDA
- Verifica que JetPack esté correctamente instalado
- Comprueba las rutas de CUDA en `/usr/local/cuda-10.2`

### Problemas de Compilación
- Verifica todas las dependencias instaladas
- Usa los flags alternativos proporcionados

### Problemas de Backup/Flasheo
- Si falla la expansión de partición:
```bash
sudo resize2fs /dev/mmcblk0p1  # Ajusta el dispositivo según sea necesario
```
- Si no se reconoce la tarjeta:
```bash
sudo lsblk  # Para ver dispositivos disponibles
```

## Notas Importantes

- Los scripts deben ejecutarse en el orden indicado
- Algunos scripts requieren permisos de administrador
- La instalación de OpenCV puede tardar varios minutos
- No desconectes la alimentación durante los procesos
- Usa una fuente de alimentación dedicada para mejor rendimiento
- Haz backups regulares de tus configuraciones importantes

# Jetson Utils

Herramientas para gestionar Jetson Nano.

## Requisitos

- NVIDIA SDK Manager instalado (https://developer.nvidia.com/sdk-manager)
- Jetson Nano
- Tarjeta SD
- Cable USB para modo Recovery

## Scripts Disponibles

### 1. Setup TensorRT
```bash
sudo ./1-setup-tensorrt.sh
```
Configura TensorRT en el Jetson Nano.

### 2. Backup Jetson
```bash
sudo ./2-backup-jetson.sh
```
Crea un backup del sistema usando NVIDIA SDK Manager.

### 3. Flash Jetson
```bash
sudo ./3-flash-jetson.sh <archivo_backup.img.gz>
```
Flashea un backup en una nueva SD usando NVIDIA SDK Manager.

## Uso de NVIDIA SDK Manager

### Backup
1. Ejecuta `sudo ./2-backup-jetson.sh`
2. Abre NVIDIA SDK Manager
3. Selecciona tu Jetson Nano
4. En la sección 'Flash OS Image':
   - Selecciona 'Backup'
   - Guarda el backup con el nombre sugerido
5. Sigue las instrucciones en pantalla

### Flash
1. Ejecuta `sudo ./3-flash-jetson.sh <archivo_backup.img.gz>`
2. Abre NVIDIA SDK Manager
3. Selecciona tu Jetson Nano
4. En la sección 'Flash OS Image':
   - Selecciona 'Restore'
   - Selecciona el archivo de backup
5. Sigue las instrucciones en pantalla

### Modo Recovery
Para entrar en modo Recovery:
1. Desconecta la alimentación
2. Mantén presionado el botón RECOVERY
3. Conecta la alimentación mientras mantienes RECOVERY
4. Suelta RECOVERY después de 2 segundos

## Notas

- Los archivos de backup (.img.gz) están en .gitignore
- Usa siempre NVIDIA SDK Manager para operaciones de backup y flash
- Asegúrate de tener suficiente espacio en disco para los backups
- Los backups se guardan por defecto en ~/nvidia/nvidia_sdk/backup/ 