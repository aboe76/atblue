#!/bin/bash
# Usage: ./build-evdi-docker.sh <base_image>
# Script to build rpm using Docker with the target Bazzite/Aurora base image
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

echo "Building rpm using Docker with $BASE_IMAGE base image..."

OUTPUT_DIR="./files/prebuilt-modules"
BUILD_SCRIPT="build-displaylink-docker.sh"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create a temporary build script
cat > "$BUILD_SCRIPT" << 'EOF'
#!/bin/bash
set -euo pipefail

# Install build dependencies
dnf5 -y install rpm-build make gcc gcc-c++ libdrm-devel systemd-rpm-macros glibc-devel wget git


# Build the RPM
cd /tmp
git clone https://github.com/displaylink-rpm/displaylink-rpm.git
cd displaylink-rpm
./ci/fedora.sh

# Copy the built module to output
cp x86_64/displaylink-*.x86_64.rpm "/output/"
echo "RPM built successfully: displaylink"
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

echo "rpm built successfully and saved to $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
