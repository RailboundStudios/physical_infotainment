#!/bin/bash

# Load the PATH environment variable
dotnetbin=/home/imbenji/.dotnet/dotnet

red="\033[0;31m"
reset="\033[0m"

# Compile the c# code for arm64

# if "donet_server/includes/rpi-rgb-led-matrix/bindings/c#/bin" does not exist, create it
if [ ! -d "dotnet_server/includes/rpi-rgb-led-matrix/bindings/c#/bin" ]; then
  printf "${red}building c# bindings${reset}\n"
  $dotnetbin build dotnet_server/includes/rpi-rgb-led-matrix/bindings/c#
  printf "${red}building c# bindings done${reset}\n"
fi
printf "${red}building c# code${reset}\n"
$dotnetbin publish -o ./bin -r linux-arm64 --self-contained true dotnet_server
printf "${red}building c# code done${reset}\n"

# Run the c# code
$dotnetbin ./bin/dotnet_server.dll