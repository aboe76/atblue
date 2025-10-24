#!/usr/bin/bash

set -eoux pipefail

# Get module configuration JSON
MODULE_CONFIG_JSON="$1"

# Parse configuration options using jq
RPM_PACKAGE=$(echo "$MODULE_CONFIG_JSON" | jq -r '.options.rpm_package // "/tmp/rpms/displaylink-1.14.9-1.x86_64.rpm"')
SIGNING_KEYS_DIR=$(echo "$MODULE_CONFIG_JSON" | jq -r '.options.signing_keys_dir // "/tmp/keys"')
EVDI_GIT_REPO=$(echo "$MODULE_CONFIG_JSON" | jq -r '.options.evdi_git_repo // "https://github.com/DisplayLink/evdi.git"')
CLEANUP_BUILD_DEPS=$(echo "$MODULE_CONFIG_JSON" | jq -r '.options.cleanup_build_deps // true')

# Get the actual kernel version from the target system, not the build environment
#KERNEL_VERSION=$(ls /lib/modules/ | grep -E ".*.fc[0-9]+" | head -1 || true)
KERNEL_VERSION=$(rpm -q kernel-devel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | head -1)
if [ -z "$KERNEL_VERSION" ]; then
    echo "WARNING: Could not find kernel version, falling back to uname -r"
    KERNEL_VERSION=$(uname -r)
fi

if [ -z "$KERNEL_VERSION" ]; then
    echo "ERROR: Could not determine kernel version"
    exit 1
fi

echo "=== DisplayLink EVDI Module Installation ==="
echo "RPM Package: $RPM_PACKAGE"
echo "Signing Keys Dir: $SIGNING_KEYS_DIR"
echo "EVDI Git Repo: $EVDI_GIT_REPO"
echo "Cleanup Build Deps: $CLEANUP_BUILD_DEPS"

# Install DisplayLink userspace driver from local RPM (skip deps since we handle EVDI ourselves)
echo "Installing DisplayLink userspace driver..."
if [ -f "$RPM_PACKAGE" ]; then
    rpm -i --nodeps "$RPM_PACKAGE"
    echo "DisplayLink RPM installed successfully"
else
    echo "WARNING: DisplayLink RPM not found at $RPM_PACKAGE, skipping RPM installation"
fi

# Build or install evdi module
echo "Setting up EVDI module..."

# Check if we have a pre-built module for this kernel
PREBUILT_MODULE="/tmp/prebuilt-modules/evdi-${KERNEL_VERSION}.ko"

if [ -f "$PREBUILT_MODULE" ]; then
    echo "Using pre-built EVDI module for kernel $KERNEL_VERSION"
    
    # Create module directory if it doesn't exist
    MODULE_DIR="/lib/modules/${KERNEL_VERSION}/extra"
    mkdir -p "$MODULE_DIR"
    
    # Copy the pre-built module
    cp "$PREBUILT_MODULE" "$MODULE_DIR/evdi.ko"
    
    # Update module dependencies for the target kernel
    depmod -a "$KERNEL_VERSION"
    
    echo "Pre-built EVDI module installed successfully"
    
else
    echo "No pre-built module found for kernel $KERNEL_VERSION, building from source..."

    # Install required tools
    echo "Installing build dependencies..."
    dnf5 -y install kernel-devel kernel-headers git make gcc libdrm-devel mokutil dkms unxz

    
    # Build evdi module from source
    cd /tmp
    git clone "$EVDI_GIT_REPO"
    cd evdi/module

    # Build with relaxed compiler flags for newer kernel compatibility
    export CFLAGS="-Wno-error=sign-compare -Wno-error=missing-field-initializers -Wno-error=discarded-qualifiers -Wno-error"
    make CFLAGS="$CFLAGS"

    # Install the module
    make install KDIR="/usr/src/kernels/$KERNEL_VERSION" CFLAGS="$CFLAGS"
    
    echo "EVDI module built and installed from source"
fi

# Clean up build artifacts
echo "Cleaning up build artifacts..."
cd /
rm -rf /tmp/evdi /tmp/module_signing_keys

# Clean up build dependencies if requested
if [ "$CLEANUP_BUILD_DEPS" = "true" ]; then
    echo "Removing build dependencies..."
    # Remove libdrm-devel as it is not needed after build
    dnf5 -y remove libdrm-devel || echo "libdrm-devel removal failed, continuing..."
fi

# Setup module loading on boot
echo "Setting up module loading on boot..."
mkdir -p /etc/modules-load.d
echo "evdi" > /etc/modules-load.d/evdi.conf
