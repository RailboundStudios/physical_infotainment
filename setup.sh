#!/bin/bash

## All binaries should be for arm64 architecture, for the Raspberry Pi Zero 2 W

## Colors
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

## Important directories
BaseDir=$(pwd)
DartServerDir=$BaseDir/dart_server
DotNetServerDir=$BaseDir/dotnet_server

DotNetDir="/home/imbenji/.dotnet" # If this doesnt exist, stop the script
if [ ! -d $DotNetDir ]; then
    echo -e "${ORANGE}DotNet not installed, this script does not install dotnet yet.${NC}"
    echo -e "${ORANGE}Please install .NET 6.0 SDK for ARM64${NC}"
    exit 1
fi

ThirdPartyDir=$BaseDir/third_party # Might not exist, but we'll create it
if [ ! -d $ThirdPartyDir ]; then
    mkdir $ThirdPartyDir
fi

TmpDir=$BaseDir/tmp # Might not exist, but we'll create it
if [ ! -d $TmpDir ]; then
    mkdir $TmpDir
fi

## Install Dart
DartVersion=3.4.4
DartDir=$ThirdPartyDir/dart-sdk

if [ ! -d $DartDir ]; then

    echo -e "${YELLOW}Installing Dart...${NC}"

    # Example: https://storage.googleapis.com/dart-archive/channels/stable/release/3.5.1/sdk/dartsdk-linux-arm64-release.zip

    DartUrl="https://storage.googleapis.com/dart-archive/channels/stable/release/$DartVersion/sdk/dartsdk-linux-arm64-release.zip"
    DartZipFile=$TmpDir/dartsdk-linux-arm64-release.zip

    wget $DartUrl -O $DartZipFile
    unzip $DartZipFile -d $ThirdPartyDir
    rm $DartZipFile

    # Rename the directory
    mv $ThirdPartyDir/dart-sdk-linux-arm64 $DartDir

    echo -e "${ORANGE}Dart installed successfully${NC}"

else

    echo -e "${ORANGE}Dart already installed${NC}"

fi

## Compile dotnet_server for ARM64 to /dotnet_server/bin
echo -e "${YELLOW}Compiling dotnet_server for ARM64...${NC}"
cd $DotNetServerDir
$DotNetDir/dotnet publish -c Release -r linux-arm64 -o bin --self-contained true
echo -e "${ORANGE}dotnet_server compiled successfully${NC}"

## Install dart_server dependencies
echo -e "${YELLOW}Installing dart_server dependencies...${NC}"
cd $DartServerDir
$DartDir/bin/dart pub get
echo -e "${ORANGE}dart_server dependencies installed successfully${NC}"

## Compile dart_server for ARM64
echo -e "${YELLOW}Compiling dart_server for ARM64...${NC}"
$DartDir/bin/dart compile exe lib/main.dart -o lib/main
echo -e "${ORANGE}Dart server compiled successfully${NC}"



