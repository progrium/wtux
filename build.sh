#!/bin/bash
set -e

# Ensure output directory exists and is empty
rm -rf output
mkdir -p output

# Build the image
docker build -t wtux-i386-builder .

# Run the container to copy files
docker run --rm -v "$PWD/output:/output-mount" wtux-i386-builder

echo "Build complete! Files in ./output:"
ls -lh output/