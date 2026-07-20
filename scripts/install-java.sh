#!/bin/bash

echo "======================================"
echo " Instalación de Java, Maven y Git"
echo "======================================"

sudo apt update
sudo apt install -y openjdk-21-jdk maven git

echo ""
echo "Versiones instaladas:"
java -version
echo ""
mvn -version
echo ""
git --version