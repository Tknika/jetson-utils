# Guía de Configuración para Control de Calidad con Jetson Nano (TensorRT)

## Descripción General

Este proyecto utiliza una Nvidia Jetson Nano para implementar un sistema de control de calidad basado en visión por computadora con aceleración TensorRT. El sistema detecta y cuenta objetos (como ingredientes de pizza) para verificar que cumplan con los estándares de calidad predefinidos.

## Requisitos de Hardware

* Nvidia Jetson Nano con adaptador de energía dedicado
* Cámara USB/webcam (ej. Logitech C270)
* Sistema de cinta transportadora mini (10cm x 50cm o más grande)
* Soporte para cámara
* Objetos: Para este ejemplo, mini pizzas con ingredientes (masa o papel impreso)
* Cable Ethernet
* PC/Laptop para acceder a Jetson Nano vía SSH

## Requisitos de Software

* Edge Impulse Studio
* Edge Impulse Linux, Python, C++ SDK
* Ubuntu OS/Nvidia Jetpack (versión 4.6 o superior)
* Terminal

## Pasos de Configuración Manual

### 1. Instalación de Herramientas Edge Impulse

Abre una terminal en tu Jetson Nano y ejecuta:

```bash
wget -q -O - https://cdn.edgeimpulse.com/firmware/linux/jetson.sh | bash
```

### 2. Instalación del Compilador Clang

```bash
sudo apt update
sudo apt install -y clang
```

### 3. Clonación del Repositorio de Inferencia de Edge Impulse

```bash
git clone https://github.com/edgeimpulse/example-standalone-inferencing-linux
cd example-standalone-inferencing-linux
git submodule update --init --recursive
```

### 4. Instalación de OpenCV

```bash
sh build-opencv-linux.sh
```

### 5. Configuración de Enlaces Simbólicos para Bibliotecas CUDA

Verifica la instalación de CUDA (incluida con JetPack 4.6):

```bash
ls -la /usr/local/cuda-10.2/lib64/
```

Crea enlaces simbólicos para las bibliotecas CUDA:

```bash
sudo ln -sf /usr/local/cuda-10.2/lib64/libcudart.so /usr/lib/libcudart.so
sudo ldconfig
```

### 6. Configuración del Tipo de Modelo FOMO

Edita el archivo `source/eim.cpp` y busca o añade la siguiente línea:

```bash
nano source/eim.cpp
```

Asegúrate de que exista esta línea:

```cpp
const char *model_type = "constrained_object_detection";
```

### 7. Descarga del Modelo TensorRT desde Edge Impulse Studio

1. Accede a [Edge Impulse Studio](https://studio.edgeimpulse.com)
2. Navega a tu proyecto
3. Haz clic en la pestaña **Deployment**
4. Busca _TensorRT_ y selecciona _Float32_
5. Haz clic en **Build**
6. Descarga y extrae el archivo ZIP en tu directorio de trabajo en la Jetson Nano

### 8. Compilación del Modelo para Jetson Nano con Aceleración GPU

Ejecuta el siguiente comando para compilar:

```bash
APP_EIM=1 TARGET_JETSON_NANO=1 CC=clang CXX=clang++ CXXFLAGS="-std=c++17" make -j
```

Si encuentras errores, intenta con estas banderas adicionales:

```bash
APP_EIM=1 TARGET_JETSON_NANO=1 CC=clang CXX=clang++ CXXFLAGS="-std=c++17 -Wno-deprecated-declarations" LDFLAGS="-L/usr/local/cuda-10.2/lib64 -lstdc++fs" make -j
```

### 9. Maximización del Rendimiento de Jetson Nano

Si tu Jetson Nano funciona con una fuente de alimentación dedicada, puedes maximizar su rendimiento con:

```bash
sudo /usr/bin/jetson_clocks
```

### 10. Prueba del Modelo

Ejecuta el Edge Impulse Runner con la cámara configurada:

```bash
edge-impulse-linux-runner --model-file ./build/model.eim
```

Podrás ver lo que observa la cámara a través de tu navegador; la dirección IP local y el puerto se mostrarán cuando se inicie el Linux Runner.

### 11. Configuración de la Aplicación Python para Control de Calidad

Instala el SDK de Python de Edge Impulse:

```bash
pip3 install edge_impulse_linux
```

Clona el repositorio de ejemplos:

```bash
git clone https://github.com/edgeimpulse/linux-sdk-python
```

Descarga el script `topping.py`:

```bash
wget -O topping.py https://raw.githubusercontent.com/Jallson/PizzaQC_Conveyor_Belt/main/topping.py
```

### 12. Ejecución de la Aplicación de Control de Calidad

```bash
python3 topping.py ~/build/model.eim
```

## Solución de Problemas Comunes

### Error: "cannot find -lcudart"

Este error indica que el enlazador no puede encontrar la biblioteca CUDA Runtime. Soluciones:

1. Verifica que CUDA esté instalado correctamente:
   ```bash
   ls -la /usr/local/cuda-10.2/lib64/libcudart.so*
   ```

2. Crea enlaces simbólicos:
   ```bash
   sudo ln -sf /usr/local/cuda-10.2/lib64/libcudart.so /usr/lib/libcudart.so
   sudo ldconfig
   ```

### Error: "filesystem file not found"

Este error ocurre porque la característica `<filesystem>` requiere C++17. Soluciones:

1. Compila con la bandera C++17:
   ```bash
   APP_EIM=1 TARGET_JETSON_NANO=1 CC=clang CXX=clang++ CXXFLAGS="-std=c++17" make -j
   ```

2. Para versiones más antiguas de compiladores:
   ```bash
   APP_EIM=1 TARGET_JETSON_NANO=1 CC=clang CXX=clang++ CXXFLAGS="-std=c++17" LDFLAGS="-lstdc++fs" make -j
   ```
