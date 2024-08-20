#!/bin/bash

# Compile the c# code for arm64
dotnet publish -c Release -r linux-arm64

# Run the c# code
dotnet bin/Release/net5.0/linux-arm64/publish/HelloWorld.dll