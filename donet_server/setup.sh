#!/bin/bash

# Load the PATH environment variable
dotnetbin=/home/imbenji/.dotnet/dotnet

# Compile the c# code for arm64

# if "donet_server/includes/rpi-rgb-led-matrix/bindings/c#/bin" does not exist, create it
if [ ! -d "donet_server/includes/rpi-rgb-led-matrix/bindings/c#/bin" ]; then
  $dotnetbin build donet_server/includes/rpi-rgb-led-matrix/bindings/c#
fi
$dotnetbin publish -c Release -r linux-arm64 # Compile the server code


# Run the c# code
#dotnet bin/Release/net5.0/linux-arm64/publish/HelloWorld.dll
$dotnetbin bin/Release/net5.0/linux-arm64/publish/HelloWorld.dll