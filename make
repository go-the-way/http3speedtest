#!/bin/bash

set -e

PRODUCT_NAME="http3speedtest"
BUILD_DIR="build"
ANDROID_NAME="$PRODUCT_NAME.aar"
JAVA_PKG="com.gotheway"
IOS_NAME="$PRODUCT_NAME.xcframework"
MACOS_NAME="$PRODUCT_NAME.dylib"
MACOS_AMD64_NAME="$PRODUCT_NAME-amd64.dylib"
MACOS_ARM64_NAME="$PRODUCT_NAME-arm64.dylib"
WINDOWS_NAME="$PRODUCT_NAME.ddl"
MAIN_PACKAGE="github.com/go-the-way/http3speedtest"
GO_PACKAGE="./http3SpeedTest"

OS=$(uname -s)
GO_VERSION="1.22.5"
GO_TAR_FILE="go$GO_VERSION.tar.gz"

GO_DOWNLOAD_URL="https://go.dev/dl/$GO_TAR_FILE"
GO_INSTALL_DIR="$HOME/sdk"
GO_ROOT_DIR="$GO_INSTALL_DIR/go"
GO_PATH_DIR="$HOME/go"
GO_ROOT_BIN_DIR="$GO_ROOT_DIR/bin"
GO_PATH_BIN_DIR="$GO_PATH_DIR/bin"

go-sdk-check() {
    if ! command -v go > /dev/null 2>&1; then
        echo "Go is not installed. Installing..."
        go-sdk-download
    fi
}

go-prints() {
    echo "GO_DOWNLOAD_URL: $GO_DOWNLOAD_URL"
    echo "GO_INSTALL_DIR: $GO_INSTALL_DIR"
    echo "GO_ROOT_DIR: $GO_ROOT_DIR"
    echo "GO_PATH_DIR: $GO_PATH_DIR"
    echo "GO_ROOT_BIN_DIR: $GO_ROOT_BIN_DIR"
    echo "GO_PATH_BIN_DIR: $GO_PATH_BIN_DIR"
}

go-sdk-download() {
    echo "Downloading Go SDK $GO_VERSION from $GO_DOWNLOAD_URL"
    mkdir -p "$GO_INSTALL_DIR"
    curl -LO "$GO_DOWNLOAD_URL"
    echo "Extracting Go SDK $GO_VERSION to $GO_ROOT_DIR"
    tar -C "$GO_INSTALL_DIR" -xvf "$GO_TARFILE"
    echo "Go SDK $GO_VERSION installed successfully."
    rm -f "$GO_TARFILE"
}

go-deps-install() {
    if ! command -v gomobile > /dev/null 2>&1; then
        echo "gomobile is not installed. Installing..."
        go install -v github.com/sagernet/gomobile/cmd/gomobile@v0.1.3
    fi
    if ! command -v gobind > /dev/null 2>&1; then
        echo "gobind is not installed. Installing..."
        go install -v github.com/sagernet/gomobile/cmd/gobind@v0.1.3
    fi
    go get github.com/sagernet/gomobile/bind
}

prepare-install() {
    go-sdk-check
    go-deps-install
}

android() {
    prepare-install
    gomobile bind -v -androidapi=21 -javapkg=$JAVA_PKG -trimpath -target=android -o "$BUILD_DIR/$ANDROID_NAME" $GO_PACKAGE
    rm -rf $BUILD_DIR/{386,amd64,arm,arm64}
}

android-arm64() {
    prepare-install
    gomobile bind -v -androidapi=21 -javapkg=$JAVA_PKG -tags="$TAGS" -trimpath -target=android/arm64 -o "$BUILD_DIR/$ANDROID_NAME" $GO_PACKAGE
    rm -rf $BUILD_DIR/arm64
}

ios-full() {
    prepare-install
    gomobile bind -v -target ios,iossimulator,tvos,tvossimulator,macos -libname=$PRODUCT_NAME -trimpath -ldflags="-w -s" -o "$BUILD_DIR/$IOS_NAME" $GO_PACKAGE
    rm -rf $BUILD_DIR/{ios*,tvos*,macos*}
}

ios() {
    prepare-install
    gomobile bind -v -target ios -libname=$PRODUCT_NAME -trimpath -ldflags="-w -s" -o "$BUILD_DIR/$IOS_NAME" $GO_PACKAGE
    rm -rf $BUILD_DIR/ios*
}

macos-amd64() {
    go-sdk-check
    env GOOS=darwin GOARCH=amd64 CGO_CFLAGS="-mmacosx-version-min=10.11" CGO_LDFLAGS="-mmacosx-version-min=10.11" CGO_ENABLED=1 go build -trimpath -buildmode=c-shared -v -o "$BUILD_DIR/$MACOS_AMD64_NAME" $MAIN_PACKAGE
}

macos-arm64() {
    go-sdk-check
    env GOOS=darwin GOARCH=arm64 CGO_CFLAGS="-mmacosx-version-min=10.11" CGO_LDFLAGS="-mmacosx-version-min=10.11" CGO_ENABLED=1 go build -trimpath -buildmode=c-shared -v -o "$BUILD_DIR/$MACOS_ARM64_NAME" $MAIN_PACKAGE
}

macos-universal() {
    macos-amd64
    macos-arm64
    lipo -create "$BUILD_DIR/$MACOS_AMD64_NAME" "$BUILD_DIR/$MACOS_ARM64_NAME" -output "$BUILD_DIR/$MACOS_NAME"
}

windows-amd64() {
    go-sdk-check
    env GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -trimpath -ldflags="-s -w" -buildmode=c-shared -v -o "$BUILD_DIR/$WINDOWS_NAME" $MAIN_PACKAGE
}

clean() {
  rm -rf $BUILD_DIR
  mkdir -p $BUILD_DIR
}

# Main entry point
case $1 in
    go-sdk-check)
        go-sdk-check
        ;;
    go-prints)
        go-prints
        ;;
    go-sdk-download)
        go-sdk-download
        ;;
    go-deps-install)
        go-deps-install
        ;;
    prepare-install)
        prepare-install
        ;;
    android)
        android
        ;;
    android-arm64)
        android-arm64
        ;;
    ios-full)
        ios-full
        ;;
    ios)
        ios
        ;;
    windows-amd64)
        windows-amd64
        ;;
    macos-amd64)
        macos-amd64
        ;;
    macos-arm64)
        macos-arm64
        ;;
    macos-universal)
        macos-universal
        ;;
    clean)
        clean
        ;;
    *)
        echo "Usage: $0 {go-sdk-check|go-prints|go-sdk-download|go-deps-install|prepare-install|android|android-amd64|ios-full|ios|windows-amd64|macos-amd64|macos-arm64|macos-universal|clean}"
        exit 1
        ;;
esac