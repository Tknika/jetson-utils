#!/bin/bash
# Jetson Nano Flash Backup to New SD Card
# This script flashes a backup image to another Jetson Nano SD card

# Set variables (modify these as needed)
BACKUP_DIR="$HOME/jetson_backups"
BACKUP_IMAGE="" # Will be set interactively
DOCKER_IMAGE="nvcr.io/nvidia/sdk-manager:latest"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Docker daemon is not running. Please start Docker service."
    exit 1
fi

# Find available backup images
echo "Looking for backup images in $BACKUP_DIR..."
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory not found. Please run the backup script first."
    exit 1
fi

# List available backup images
echo "Available backup images:"
IMAGES=()
count=1
for img in "$BACKUP_DIR"/*.img "$BACKUP_DIR"/*.img.gz; do
    if [ -f "$img" ]; then
        echo "$count) $(basename "$img")"
        IMAGES+=("$img")
        count=$((count+1))
    fi
done

if [ ${#IMAGES[@]} -eq 0 ]; then
    echo "No backup images found in $BACKUP_DIR."
    exit 1
fi

# Let user select an image
read -p "Enter the number of the image you want to flash: " selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#IMAGES[@]} ]; then
    echo "Invalid selection."
    exit 1
fi

BACKUP_IMAGE="${IMAGES[$((selection-1))]}"
echo "Selected: $BACKUP_IMAGE"

# Check if the image is compressed
if [[ "$BACKUP_IMAGE" == *.gz ]]; then
    echo "Decompressing image..."
    gunzip -c "$BACKUP_IMAGE" > "${BACKUP_IMAGE%.gz}.tmp"
    BACKUP_IMAGE="${BACKUP_IMAGE%.gz}.tmp"
    echo "Decompressed to $BACKUP_IMAGE"
fi

# Ensure the Docker image is available locally
echo "Pulling the NVIDIA SDK Manager Docker image..."
docker pull $DOCKER_IMAGE

# Connect target Jetson to recovery mode
echo "Please put your target Jetson Nano into recovery mode:"
echo "1. Power off the Jetson Nano"
echo "2. Connect the micro-USB cable to your computer"
echo "3. Hold down the RECOVERY button (labeled 'REC' on the board)"
echo "4. While holding the RECOVERY button, press the POWER button"
echo "5. Release the POWER button"
echo "6. Wait 2 seconds, then release the RECOVERY button"
read -p "Press Enter once your target Jetson Nano is in recovery mode..."

# Check if the device is in recovery mode
lsusb | grep -q "0955:7f21" 
if [ $? -ne 0 ]; then
    echo "Jetson Nano not detected in recovery mode. Please try again."
    exit 1
fi
echo "Jetson Nano detected in recovery mode."

# Run the SDK Manager in Docker to flash the backup
echo "Starting flash process with SDK Manager..."
docker run --privileged -it --rm \
    -v /dev/bus/usb:/dev/bus/usb \
    -v "$(dirname "$BACKUP_IMAGE"):/home/nvidia/nvidia/nvidia_sdk/restore" \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    $DOCKER_IMAGE \
    --cli --op restore --login-type devzone \
    --product Jetson --target-os Linux \
    --host-arch $(uname -m) \
    --target P3448-0020 \
    --storage sdcard \
    --target-overlay "Nano (4GB Developer Kit Version)" \
    --ota-upgrade false \
    --select-project always \
    --restore-path "/home/nvidia/nvidia/nvidia_sdk/restore/$(basename "$BACKUP_IMAGE")"

# Check if the flashing was successful
if [ $? -eq 0 ]; then
    echo "Flash completed successfully!"
else
    echo "Flash process failed. Please check the error messages above."
fi

# Cleanup
if [[ "$BACKUP_IMAGE" == *.tmp ]]; then
    echo "Cleaning up temporary files..."
    rm "$BACKUP_IMAGE"
fi

echo "Flash process completed."