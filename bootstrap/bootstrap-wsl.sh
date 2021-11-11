#!/bin/bash
# first do:
# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
# Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
# wsl --set-default-version 2
# Start-Process -FilePath https://www.microsoft.com/en-us/p/ubuntu-2004-lts/9n6svws3rx71
# Start-Process -FilePath https://www.microsoft.com/en-gb/p/windows-terminal/9n0dx20hk701
# Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
set -e
