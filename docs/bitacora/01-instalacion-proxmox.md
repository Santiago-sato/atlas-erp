# Instalación de Proxmox VE

## Objetivo

Instalar Proxmox VE como hipervisor principal del proyecto ERP.

---

## Actividades realizadas

- Descarga de la ISO oficial.
- Instalación en el portátil servidor.
- Configuración inicial.
- Acceso mediante interfaz web.

---

## Problemas encontrados

### Dirección IP incorrecta

Durante la instalación Proxmox detectó automáticamente la red:

192.168.100.2

Sin embargo, el router del laboratorio utiliza el rango:

192.168.0.x

Como consecuencia no era posible acceder a la interfaz web.

### Solución

Se modificó manualmente la configuración de red para utilizar:

IP: 192.168.0.200

Gateway:

192.168.0.1

Después del cambio fue posible acceder correctamente desde el navegador.

---

## Evidencias

- Instalador
- Dashboard inicial