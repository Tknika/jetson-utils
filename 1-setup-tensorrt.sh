#!/bin/bash

# Quality Control Jetson Nano TensorRT Setup Script
# This script automates the setup process of tensorRT and edge impulse and loads sample model
# mikel.diez (mikel.diez@somorrostro.com) - Arraiz

set -e # Exit on error

echo "========================================================"
echo "Setting up Quality Control TensorRT project for Jetson Nano"
echo "========================================================"

# Step 1: Install Edge Impulse tooling
echo "[1/6] Installing Edge Impulse tooling..."
wget -q -O - https://cdn.edgeimpulse.com/firmware/linux/jetson.sh | bash

# Step 2: Install Clang compiler
echo "[2/6] Installing Clang compiler..."
sudo apt update
sudo apt install -y clang

# Step 3: Clone the Edge Impulse inferencing repository
echo "[3/6] Cloning Edge Impulse inferencing repository..."
git clone https://github.com/edgeimpulse/example-standalone-inferencing-linux
cd example-standalone-inferencing-linux && git submodule update --init --recursive

# Step 4: Install OpenCV
echo "[4/6] Installing OpenCV (this may take some time)..."
sh build-opencv-linux.sh

# Step 5: Create symbolic links for CUDA libraries
echo "[5/6] Setting up CUDA library paths..."
if [ -d "/usr/local/cuda-10.2" ]; then
  echo "Found CUDA 10.2, creating symbolic links..."
  sudo ln -sf /usr/local/cuda-10.2/lib64/libcudart.so /usr/lib/libcudart.so
  sudo ldconfig
else
  echo "Warning: CUDA 10.2 directory not found. Check your JetPack installation."
  echo "Looking for alternative CUDA installations..."
  find /usr/local -name "cuda*" -type d
  find /usr -name "libcudart.so*" 2>/dev/null
  echo "You may need to manually create symbolic links to your CUDA libraries."
fi

# Step 6: Modify the FOMO model type in eim.cpp
echo "[6/6] Setting up FOMO model type..."
if [ -f "source/eim.cpp" ]; then
  # Check if line already exists
  if grep -q "const char \*model_type = \"constrained_object_detection\";" source/eim.cpp; then
    echo "FOMO model type already set in eim.cpp"
  else
    # Try to replace existing model_type line
    sed -i 's/const char \*model_type = ".*";/const char *model_type = "constrained_object_detection";/g' source/eim.cpp
    
    # Check if replacement worked, if not, append the line
    if ! grep -q "const char \*model_type = \"constrained_object_detection\";" source/eim.cpp; then
      echo "Adding model_type line to eim.cpp"
      echo 'const char *model_type = "constrained_object_detection";' >> source/eim.cpp
    fi
  fi
else
  echo "Warning: source/eim.cpp not found. Make sure you're in the right directory."
fi

echo "========================================================"
echo "Setup completed! Follow these next steps:"
echo "========================================================"
echo ""
echo "1. Extract your TensorRT model from Edge Impulse Studio and place it in this directory"
echo ""
echo "2. Build the model for Jetson Nano with GPU acceleration:"
echo "   APP_EIM=1 TARGET_JETSON_NANO=1 CC=clang CXX=clang++ CXXFLAGS=\"-std=c++17\" make -j"
echo ""
echo "3. If you encounter any errors, try with these additional flags:"
echo "   APP_EIM=1 TARGET_JETSON_NANO=1 CC=clang CXX=clang++ CXXFLAGS=\"-std=c++17 -Wno-deprecated-declarations\" LDFLAGS=\"-L/usr/local/cuda-10.2/lib64 -lstdc++fs\" make -j"
echo ""
echo "4. Maximize Jetson Nano performance with (requires dedicated power supply):"
echo "   sudo /usr/bin/jetson_clocks"
echo ""
echo "5. Test your model with:"
echo "   edge-impulse-linux-runner --model-file ./build/model.eim"
echo ""
echo "6. For the Python quality control application:"
echo "   - Install Edge Impulse Python SDK"
echo "   - Clone the Linux Python SDK repository"
echo "   - Download the topping.py script from: https://github.com/Jallson/PizzaQC_Conveyor_Belt/blob/main/topping.py"
echo "   - Run with: python3 topping.py ~/build/model.eim"
echo ""
echo "Happy Quality Control!"

# Offer to install Python SDK if user wants
read -p "Do you want to install the Edge Impulse Python SDK as well? (y/n) " install_python

if [ "$install_python" = "y" ] || [ "$install_python" = "Y" ]; then
  echo "Installing Edge Impulse Python SDK..."
  pip3 install edge_impulse_linux
  
  echo "Cloning Python SDK examples..."
  git clone https://github.com/edgeimpulse/linux-sdk-python
  
  echo "Downloading topping.py script..."
  wget -O topping.py https://raw.githubusercontent.com/Jallson/PizzaQC_Conveyor_Belt/main/topping.py
  
  echo "Python SDK setup complete!"
fi