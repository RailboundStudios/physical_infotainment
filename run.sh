#!/bin/bash

## All binaries should be for arm64 architecture, for the Raspberry Pi Zero 2 W

## Colors
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

## Important directories
BaseDir=$(pwd)
DartServerDir=$BaseDir/dart_server
ThirdPartyDir=$BaseDir/third_party

DartDir=$ThirdPartyDir/dart-sdk

# Im lazy, should remove this
git pull

# sudo ./dart_server/lib/main
sudo $DartDir/bin/dart run $DartServerDir/lib/main.dart

