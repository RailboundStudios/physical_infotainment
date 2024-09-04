#!/bin/bash

## Colors
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

## Important directories
BaseDir=$(pwd)
DartServerDir="$BaseDir/dart_server"
DotNetServerDir="$BaseDir/dotnet_server"
DotNetDir="/home/imbenji/.dotnet"
ThirdPartyDir="$BaseDir/third_party"
TmpDir="$BaseDir/tmp"

## Create necessary directories if they don't exist
mkdir -p "$ThirdPartyDir" "$TmpDir"

## Install .NET 6.0 SDK for ARM64
if [ ! -d "$DotNetDir" ]; then
    echo -e "${YELLOW}.NET 6.0 SDK for ARM64 not found. Installing...${NC}"
    wget https://dot.net/v1/dotnet-install.sh -O "$TmpDir/dotnet-install.sh" &&
    chmod +x "$TmpDir/dotnet-install.sh" &&
    cd $HOME &&
    bash "$TmpDir/dotnet-install.sh" --channel 6.0 &&
    cd "$BaseDir"
fi

## Install Dart SDK
DartVersion=3.4.4
DartDir="$ThirdPartyDir/dart-sdk"
DartZipFile="$TmpDir/dartsdk-linux-arm64-release.zip"

if [ ! -d "$DartDir" ]; then
    echo -e "${YELLOW}Installing Dart...${NC}"
    wget "https://storage.googleapis.com/dart-archive/channels/stable/release/$DartVersion/sdk/dartsdk-linux-arm64-release.zip" -O "$DartZipFile" &&
    unzip "$DartZipFile" -d "$ThirdPartyDir" &&
    mv "$ThirdPartyDir/dart-sdk-linux-arm64" "$DartDir" &&
    rm "$DartZipFile"
    echo -e "${ORANGE}Dart installed successfully${NC}"
else
    echo -e "${ORANGE}Dart already installed${NC}"
fi

## Stop the server if already running
sudo systemctl is-active --quiet pi-ibus.service && sudo systemctl stop pi-ibus.service

## Compile dotnet_server for ARM64 to /dotnet_server/bin
echo -e "${YELLOW}Compiling dotnet_server for ARM64...${NC}"
cd "$DotNetServerDir" &&
"$DotNetDir/dotnet" publish -c Release -r linux-arm64 -o bin --self-contained true &&
echo -e "${ORANGE}dotnet_server compiled successfully${NC}"

## Install dart_server dependencies and compile it
echo -e "${YELLOW}Installing dart_server dependencies...${NC}"
cd "$DartServerDir" &&
"$DartDir/bin/dart" pub get &&
echo -e "${YELLOW}Compiling dart_server for ARM64...${NC}"
"$DartDir/bin/dart" compile exe lib/main.dart -o lib/main &&
echo -e "${ORANGE}Dart server compiled successfully${NC}"

## Run the server if --run flag is passed
if [ "$1" == "--run" ]; then
    sudo "$DartDir/bin/dart" run lib/main.dart
fi

## Ensure ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${YELLOW}ffmpeg not found. Installing...${NC}"
    sudo apt-get install -y ffmpeg &&
    echo -e "${ORANGE}ffmpeg installed successfully${NC}"
else
    echo -e "${ORANGE}ffmpeg already installed${NC}"
fi

## Create systemd service for dart_server if not exists
if [ ! -f /etc/systemd/system/pi-ibus.service ]; then
    echo -e "${YELLOW}Creating systemd service for dart_server...${NC}"
    sudo cp "$BaseDir/pi-ibus.service" /etc/systemd/system/pi-ibus.service &&
    sudo systemctl enable pi-ibus.service &&
    echo -e "${ORANGE}Systemd service created successfully${NC}"
else
    echo -e "${ORANGE}Systemd service already exists${NC}"
fi

sudo systemctl start pi-ibus.service
sudo journalctl -f -u pi-ibus.service