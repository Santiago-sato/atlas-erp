#!/bin/bash

echo "======================================"
echo " Instalación de PostgreSQL"
echo "======================================"

sudo apt update
sudo apt install -y postgresql postgresql-contrib

echo ""
echo "Versión:"
psql --version

echo ""
echo "Cluster:"
sudo pg_lsclusters