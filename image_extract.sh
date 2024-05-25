#!/bin/bash

# Check if at least an .img file and a target directory are provided as arguments
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "Usage: $0 <image_file.img> <target_directory> [partition_number]"
  exit 1
fi

IMG_FILE=$1
TARGET_DIR=$2
PARTITION_NUMBER=${3:-all}

# Check if the file exists
if [ ! -f "$IMG_FILE" ]; then
  echo "The file $IMG_FILE does not exist."
  exit 1
fi

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "The directory $TARGET_DIR does not exist. Creating directory..."
  mkdir -p "$TARGET_DIR"
  if [ $? -ne 0 ]; then
    echo "Failed to create directory $TARGET_DIR."
    exit 1
  fi
fi

# Read the partition list with fdisk
PARTITIONS=$(fdisk -lu "$IMG_FILE" | grep "^$IMG_FILE")

# Partition counter
PART_NUM=0

echo "Partitions found in $IMG_FILE:"
echo "$PARTITIONS"

# Extract partitions
echo "$PARTITIONS" | while read -r line; do
  PART_START=$(echo $line | awk '{print $2}')
  PART_END=$(echo $line | awk '{print $3}')
  PART_SIZE=$((PART_END - PART_START + 1))
  OUTPUT_FILE="$TARGET_DIR/part$PART_NUM.img"

  if [ "$PARTITION_NUMBER" == "all" ] || [ "$PARTITION_NUMBER" -eq "$PART_NUM" ]; then
    echo "Extracting partition $PART_NUM to $OUTPUT_FILE..."
    dd if="$IMG_FILE" of="$OUTPUT_FILE" bs=512 skip=$PART_START count=$PART_SIZE
    
    if [ $? -eq 0 ]; then
      echo "Partition $PART_NUM extracted to $OUTPUT_FILE"
    else
      echo "Error extracting partition $PART_NUM"
    fi
  fi

  PART_NUM=$((PART_NUM + 1))
done

echo "Extraction complete. Partitions are extracted to $TARGET_DIR."
