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