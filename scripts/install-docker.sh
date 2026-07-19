#!/bin/bash

# ======================================================
# AtlasERP
# Script de instalación de Docker Engine
# ======================================================

set -e

echo "======================================="
echo " Instalando Docker Engine..."
echo "======================================="

echo "[1/7] Actualizando repositorios..."
sudo apt update

echo "[2/7] Instalando dependencias..."
sudo apt install -y ca-certificates curl gnupg

echo "[3/7] Creando directorio para llaves..."
sudo install -m 0755 -d /etc/apt/keyrings

echo "[4/7] Descargando llave GPG de Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "[5/7] Agregando repositorio oficial..."

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[6/7] Actualizando repositorios..."
sudo apt update

echo "[7/7] Instalando Docker..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ""
echo "======================================="
echo " Docker instalado correctamente"
echo "======================================="

docker --version
docker compose version