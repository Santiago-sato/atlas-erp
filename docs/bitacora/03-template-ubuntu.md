# VM Base y Template

## Objetivo

Crear una máquina virtual base que será utilizada como plantilla para todas las VMs del proyecto.

---

## Configuración

Sistema Operativo

Ubuntu Server 24.04 LTS

CPU

1 Core

RAM

2 GB

Disco

32 GB

Red

VirtIO

Bridge

vmbr0

---

## Configuración realizada

- Instalación de Ubuntu Server.
- Instalación de OpenSSH.
- Actualización del sistema.
- Instalación de QEMU Guest Agent.
- Instalación de herramientas básicas.
- Conversión a Template.

---

## Problemas encontrados

### QEMU Guest Agent

Al intentar iniciar el servicio apareció un error de dependencias.

#### Solución

Se habilitó la opción **QEMU Guest Agent** desde la configuración de la máquina virtual en Proxmox y posteriormente el servicio inició correctamente.

---

### Snapshot y Template

Se creó inicialmente un Snapshot antes de convertir la máquina en plantilla.

Proxmox mostró el error:

unable to create template, because VM contains snapshots

#### Solución

Se eliminó el Snapshot y posteriormente fue posible convertir la máquina virtual en Template.

---

## Resultado

Se obtuvo una plantilla Ubuntu Server completamente funcional para ser clonada durante el Sprint 2.