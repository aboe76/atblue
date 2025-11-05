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
git clone https://github.com/OpenVPN/ovpn-dco.git
cd ovpn-dco

# Build with relaxed compiler flags and specify kernel source directory
export CFLAGS="-Wno-error=sign-compare -Wno-error=missing-field-initializers -Wno-error=discarded-qualifiers -Wno-error"
make KDIR="/usr/src/kernels/$KERNEL_VERSION" CFLAGS="$CFLAGS"

# Copy the built module to output
cp ovpn-dco-v2.ko "/output/ovpn-dco-v2-${KERNEL_VERSION}.ko"
echo "Module built successfully: ovpn-dco-v2-${KERNEL_VERSION}.ko"
