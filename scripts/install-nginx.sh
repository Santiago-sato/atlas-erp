#!/bin/bash

echo "======================================"
echo " Instalación de Nginx"
echo "======================================"

sudo apt update
sudo apt install -y nginx

sudo systemctl enable nginx
sudo systemctl start nginx

echo ""
echo "Estado del servicio:"
sudo systemctl status nginx --no-pager

echo ""
echo "Puertos abiertos:"
sudo ss -tulpn | grep :80