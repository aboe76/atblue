#!/bin/bash
# Usage: ./build-evdi-docker.sh <base_image>
# Script to build EVDI module using Docker with the target Bazzite/Aurora base image
# 
# This script is designed to work in GitHub Actions by using the kernel version
# from the container's kernel-devel package, not the host/runner's kernel.
# 
# Example: ./build-evdi-docker.sh ghcr.io/ublue-os/aurora-dx-nvidia-open:stable
set -euo pipefail

# Check if base image is provided
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <base_image> (e.g., ghcr.io/ublue-os/aurora-dx-nvidia-open:stable)"
    exit 1
fi
BASE_IMAGE="$1"

echo "Building EVDI module using Docker with $BASE_IMAGE base image..."

OUTPUT_DIR="./files/prebuilt-modules"
BUILD_SCRIPT="build-evdi-docker.sh"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create a temporary build script
cat > "$BUILD_SCRIPT" << 'EOF'
#!/bin/bash
set -euo pipefail

# Install build dependencies
dnf5 -y install kernel-devel kernel-headers git make gcc libdrm-devel

# Get kernel version from the installed kernel-devel package, not the running kernel
# This ensures we use the Aurora/Bazzite kernel, not the GitHub runner's kernel
KERNEL_VERSION=$(rpm -q kernel-devel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | head -1)
echo "Building for kernel: $KERNEL_VERSION"

# Verify kernel-devel is available for this version
if [[ ! -d "/usr/src/kernels/$KERNEL_VERSION" ]]; then
    echo "Error: Kernel headers not found for $KERNEL_VERSION"
    echo "Available kernel versions:"
    ls -la /usr/src/kernels/ || echo "No kernels found in /usr/src/kernels/"
    exit 1
fi

# Build the module
cd /tmp
git clone https://github.com/DisplayLink/evdi.git
cd evdi/module

# Build with relaxed compiler flags and specify kernel source directory
export CFLAGS="-Wno-error=sign-compare -Wno-error=missing-field-initializers -Wno-error=discarded-qualifiers -Wno-error"
make KDIR="/usr/src/kernels/$KERNEL_VERSION" CFLAGS="$CFLAGS"

# Copy the built module to output
cp evdi.ko "/output/evdi-${KERNEL_VERSION}.ko"
echo "Module built successfully: evdi-${KERNEL_VERSION}.ko"
EOF

chmod +x "$BUILD_SCRIPT"

# Run the build in Docker
docker run --rm \
    -v "$(pwd)/$OUTPUT_DIR:/output" \
    -v "$(pwd)/$BUILD_SCRIPT:/tmp/build-script.sh" \
    "$BASE_IMAGE" \
    /tmp/build-script.sh

# Clean up
rm "$BUILD_SCRIPT"

echo "EVDI module built successfully and saved to $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
