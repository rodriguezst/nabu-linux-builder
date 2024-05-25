#!/bin/bash

# Check if an .img file and a mount directory are provided as arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 <image_file.img> <mount_directory>"
  exit 1
fi

IMG_FILE=$1
MOUNT_BASE_DIR=$2

# Check if the file exists
if [ ! -f "$IMG_FILE" ]; then
  echo "The file $IMG_FILE does not exist."
  exit 1
fi

# Check if the mount directory exists
if [ ! -d "$MOUNT_BASE_DIR" ]; then
  echo "The directory $MOUNT_BASE_DIR does not exist. Creating directory..."
  mkdir -p "$MOUNT_BASE_DIR"
  if [ $? -ne 0 ]; then
    echo "Failed to create directory $MOUNT_BASE_DIR."
    exit 1
  fi
fi

# Read the partition list with sfdisk
PARTITIONS=$(sfdisk -d "$IMG_FILE" | grep '^/dev/')

# Partition counter
PART_NUM=0

echo "Partitions found in $IMG_FILE:"
echo "$PARTITIONS"

# Mount each partition
echo "$PARTITIONS" | while read -r line; do
  PART_START=$(echo $line | awk '{print $4}' | sed 's/,//')
  PART_SIZE=$(echo $line | awk '{print $6}' | sed 's/,//')
  MOUNT_POINT="$MOUNT_BASE_DIR/part$PART_NUM"
  mkdir -p "$MOUNT_POINT"

  echo "Mounting partition $PART_NUM on $MOUNT_POINT..."
  mount -o loop,offset=$((512 * PART_START)),sizelimit=$((512 * PART_SIZE)) "$IMG_FILE" "$MOUNT_POINT"
  
  if [ $? -eq 0 ]; then
    echo "Partition $PART_NUM mounted on $MOUNT_POINT"
  else
    echo "Error mounting partition $PART_NUM"
  fi

  PART_NUM=$((PART_NUM + 1))
done

echo "Mounting complete. Partitions are mounted in $MOUNT_BASE_DIR."

# Note: To unmount the partitions and remove the mount directory, you can use:
# umount -R $MOUNT_BASE_DIR && rmdir $MOUNT_BASE_DIR
