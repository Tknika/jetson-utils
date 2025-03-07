#!/bin/bash
# Jetson Nano SD Card Backup Script
# This script creates a backup of a Jetson Nano SD card using NVIDIA SDK Manager via Docker

# Set variables (modify these as needed)
BACKUP_NAME="jetson_nano_backup_$(date +%Y%m%d)"
BACKUP_DIR="$HOME/jetson_backups"
DOCKER_IMAGE="nvcr.io/nvidia/sdk-manager:latest"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
echo "Created backup directory at $BACKUP_DIR"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Docker daemon is not running. Please start Docker service."
    exit 1
fi

# Ensure the Docker image is available locally
echo "Pulling the NVIDIA SDK Manager Docker image..."
docker pull $DOCKER_IMAGE

# Connect Jetson to recovery mode
echo "Please put your Jetson Nano into recovery mode:"
echo "1. Power off the Jetson Nano"
echo "2. Connect the micro-USB cable to your computer"
echo "3. Hold down the RECOVERY button (labeled 'REC' on the board)"
echo "4. While holding the RECOVERY button, press the POWER button"
echo "5. Release the POWER button"
echo "6. Wait 2 seconds, then release the RECOVERY button"
read -p "Press Enter once your Jetson Nano is in recovery mode..."

# Check if the device is in recovery mode
lsusb | grep -q "0955:7f21" 
if [ $? -ne 0 ]; then
    echo "Jetson Nano not detected in recovery mode. Please try again."
    exit 1
fi
echo "Jetson Nano detected in recovery mode."

# Run the SDK Manager in Docker to create a backup
echo "Starting backup process with SDK Manager..."
docker run --privileged -it --rm \
    -v /dev/bus/usb:/dev/bus/usb \
    -v "$BACKUP_DIR:/home/nvidia/nvidia/nvidia_sdk/backup" \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    $DOCKER_IMAGE \
    --cli --op backup --login-type devzone \
    --product Jetson --target-os Linux \
    --host-arch $(uname -m) \
    --target P3448-0020 \
    --storage sdcard \
    --target-overlay "Nano (4GB Developer Kit Version)" \
    --ota-upgrade false \
    --select-project always \
    --backup-path "/home/nvidia/nvidia/nvidia_sdk/backup/$BACKUP_NAME.img"

# Check if the backup was successful
if [ $? -eq 0 ]; then
    echo "Backup completed successfully!"
    echo "Your backup image is located at: $BACKUP_DIR/$BACKUP_NAME.img"
    
    # Create a compressed version of the backup to save space
    echo "Creating compressed backup image..."
    gzip -c "$BACKUP_DIR/$BACKUP_NAME.img" > "$BACKUP_DIR/$BACKUP_NAME.img.gz"
    echo "Compressed backup created at: $BACKUP_DIR/$BACKUP_NAME.img.gz"
    
    # Display backup information
    if [ -f "$BACKUP_DIR/$BACKUP_NAME.img" ]; then
        BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME.img" | cut -f1)
        echo "Original backup size: $BACKUP_SIZE"
    fi
    
    if [ -f "$BACKUP_DIR/$BACKUP_NAME.img.gz" ]; then
        COMPRESSED_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME.img.gz" | cut -f1)
        echo "Compressed backup size: $COMPRESSED_SIZE"
    fi
else
    echo "Backup process failed. Please check the error messages above."
fi

echo "Backup process completed."