#!/bin/bash


set -e  # Exit on error

echo "======================================"
echo "Termux NDK Installer for Android"
echo "======================================"
echo ""


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}


NDK_URL="https://github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r27b-aarch64.zip"
NDK_ZIP="android-ndk-r27b-aarch64.zip"
NDK_DIR="android-ndk-r27b"
TARGET_DIR="ndk"


print_info "Checking required packages..."
if ! command -v wget &> /dev/null; then
    print_info "Installing wget..."
    pkg install wget -y
fi

if ! command -v unzip &> /dev/null; then
    print_info "Installing unzip..."
    pkg install unzip -y
fi


cd "$HOME" || { print_error "Failed to change to $HOME"; exit 1; }


if [ -d "$HOME/$TARGET_DIR" ]; then
    print_info "NDK directory already exists. Remove it? (y/n)"
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        rm -rf "$HOME/$TARGET_DIR"
        print_success "Old NDK removed"
    else
        print_error "Installation cancelled"
        exit 1
    fi
fi


if [ -f "$HOME/$NDK_ZIP" ]; then
    print_info "NDK zip file already exists. Use existing file? (y/n)"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        rm -f "$HOME/$NDK_ZIP"
        print_info "Old zip file removed, will download new one"
    else
        print_info "Using existing zip file"
    fi
fi

if [ ! -f "$HOME/$NDK_ZIP" ]; then
    print_info "Downloading NDK from GitHub..."
    print_info "This may take a while (file size ~800MB)..."
    
    if wget -c "$NDK_URL" -O "$NDK_ZIP"; then
        print_success "Download completed"
    else
        print_error "Failed to download NDK"
        exit 1
    fi
else
    print_info "Using existing NDK zip file"
fi


FILE_SIZE=$(stat -c%s "$NDK_ZIP" 2>/dev/null || stat -f%z "$NDK_ZIP" 2>/dev/null)
if [ "$FILE_SIZE" -lt 500000000 ]; then
    print_error "Downloaded file seems incomplete (size: $FILE_SIZE bytes)"
    print_info "Removing incomplete file..."
    rm -f "$NDK_ZIP"
    exit 1
fi

print_success "File size verified: $FILE_SIZE bytes"


print_info "Extracting NDK..."
if unzip -q "$NDK_ZIP"; then
    print_success "Extraction completed"
else
    print_error "Failed to extract NDK"
    exit 1
fi


print_info "Removing zip file to save space..."
rm -f "$NDK_ZIP"


print_info "Renaming NDK folder..."
if [ -d "$NDK_DIR" ]; then
    mv "$NDK_DIR" "$TARGET_DIR"
    print_success "NDK folder renamed to '$TARGET_DIR'"
else
    print_error "Extracted folder not found: $NDK_DIR"
    exit 1
fi


cd "$HOME/$TARGET_DIR" || { print_error "Failed to enter NDK directory"; exit 1; }


print_info "Configuring NDK..."
if [ -f "ndk-build" ]; then
    mv ndk-build ndk
    print_success "ndk-build renamed to ndk"
fi


print_info "Creating symlinks for toolchains..."
if [ -d "toolchains/llvm/prebuilt/linux-aarch64" ]; then
    cd "toolchains/llvm/prebuilt" || exit 1
    ln -sf linux-aarch64 linux-x86_64
    print_success "Toolchain symlink created"
else
    print_error "Toolchain directory not found"
    exit 1
fi


cd "$HOME/$TARGET_DIR" || exit 1
if [ -d "prebuilt/linux-aarch64" ]; then
    cd "prebuilt" || exit 1
    ln -sf linux-aarch64 linux-x86_64
    print_success "Prebuilt symlink created"
else
    print_error "Prebuilt directory not found"
    exit 1
fi


INCLUDES_PATH="$HOME/$TARGET_DIR/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1"
if [ -d "$INCLUDES_PATH" ]; then
    cd "$INCLUDES_PATH" || exit 1
    print_info "Creating Includes header file..."
    
    cat > Includes << 'EOL'
#include <iostream>
#include <stdio.h>
#include <string>
#include <unistd.h>
#include <stdint.h>
#include <inttypes.h>
#include <vector>
#include <map>
#include <chrono>
#include <fstream>
#include <thread>
#include <pthread.h>
#include <dirent.h>
#include <libgen.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/uio.h>
#include <fcntl.h>
#include <jni.h>
#include <android/log.h>
#include <elf.h>
#include <dlfcn.h>
#include <sys/system_properties.h>
#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <codecvt>
#include <libgen.h>
#include <sys/types.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/syscall.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>
#include <sys/un.h>
#include <time.h>
#include <ctype.h>
using namespace std;
EOL
    
    print_success "Includes file created"
else
    print_error "C++ include directory not found"
    exit 1
fi


print_info "Setting up environment variables..."
cd "$HOME" || exit 1

# Tambahkan ke .bashrc jika belum ada
if ! grep -q "export NDK=" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOL'


export NDK=$HOME/ndk
export PATH=$PATH:$NDK
EOL
    print_success "Environment variables added to .bashrc"
else
    print_info "Environment variables already in .bashrc"
fi


export NDK=$HOME/ndk
export PATH=$PATH:$NDK





if [ -f "$HOME/ndk/ndk" ]; then
    print_success "NDK binary found and ready to use!"
else
    print_error "NDK binary not found. Something went wrong."
    exit 1
fi



su -c "mv /data/data/com.termux/files/home/ndk /data/media/0/ && chmod -R 755 /data/media/0/ndk"


echo ""
echo "======================================"
print_success "NDK Installation Complete!"
echo "======================================"
echo ""

print_success "https://github.com/Shaizuro379/"
