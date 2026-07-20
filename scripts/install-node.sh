#!/bin/bash

echo "======================================"
echo " Instalación de Node.js y Git"
echo "======================================"

sudo apt update
sudo apt install -y nodejs npm git

echo ""
echo "Versiones instaladas:"
node -v
echo ""
npm -v
echo ""
git --version