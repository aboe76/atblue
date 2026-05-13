#!/usr/bin/bash

set -eoux pipefail

# Get module configuration JSON
MODULE_CONFIG_JSON="$1"

# Parse configuration options using jq
RPM_PACKAGE=$(echo "$MODULE_CONFIG_JSON" | jq -r '.options.rpm_package // "/tmp/rpms/displaylink-1.14.11-2.x86_64.rpm"')
GIT_REPO=$(echo "$MODULE_CONFIG_JSON" | jq -r '.options.git_repo // "https://github.com/displaylink-rpm/displaylink-rpm.git"')
CLEANUP_BUILD_DEPS=$(echo "$MODULE_CONFIG_JSON" | jq -r '.options.cleanup_build_deps // true')

# Get the actual kernel version from the target system, not the build environment
#KERNEL_VERSION=$(ls /lib/modules/ | grep -E ".*.fc[0-9]+" | head -1 || true)
if ! rpm -qa | grep -qw kernel-devel; then
	dnf5 -y --disablerepo=updates install kernel-devel kernel-headers
fi
KERNEL_VERSION=$(rpm -q kernel-devel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | head -1)
if [ -z "$KERNEL_VERSION" ]; then
    echo "WARNING: Could not find kernel version, falling back to uname -r"
    KERNEL_VERSION=$(uname -r)
fi

if [ -z "$KERNEL_VERSION" ]; then
    echo "ERROR: Could not determine kernel version"
    exit 1
fi

echo "=== DisplayLink RPM Module Installation ==="
echo "RPM Package: $RPM_PACKAGE"
echo "Git Repo: $GIT_REPO"
echo "Cleanup Build Deps: $CLEANUP_BUILD_DEPS"

# Install DisplayLink userspace driver from local RPM (skip deps since we handle EVDI ourselves)
echo "Installing DisplayLink userspace driver..."
if [ -f "$RPM_PACKAGE" ]; then
    rpm -Uvh --noscripts --nodeps "$RPM_PACKAGE"
    echo "DisplayLink RPM installed successfully"
else
    echo "WARNING: DisplayLink RPM not found at $RPM_PACKAGE, skipping RPM installation"

# Build or install RPM module
echo "Setting up RPM module..."

# Install required tools
echo "Installing build dependencies..."
dnf5 -y install git make gcc libdrm-devel mokutil dkms unxz || echo "already installed"


# Build RPM module from source
cd /tmp
git clone "$GIT_REPO"
cd displaylink-rpm/
echo "OSVERSION=43" >> $GITHUB_ENV
./ci/fedora.sh
rpm -Uvh --noscripts x86_64/displaylink-*.x86_64.rpm

fi

# Clean up build dependencies if requested
if [ "$CLEANUP_BUILD_DEPS" = "true" ]; then
    echo "Removing build dependencies..."
    # Remove libdrm-devel as it is not needed after build
    dnf5 -y remove libdrm-devel || echo "libdrm-devel removal failed, continuing..."
fi

# Clean up build artifacts
echo "Cleaning up build artifacts..."
cd /
rm -rf /tmp/displaylink-rpm
