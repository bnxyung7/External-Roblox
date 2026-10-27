# BNXYUNG7 · External Roblox

Script para PC y movil con panel de control, circulo FOV ajustable, ESP y walkspeed.
Sin KEY, sin instalador, sin dependencias externas: una linea y adentro.

## Ejecutar

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bnxyung7/External-Roblox/main/main_code.lua"))()
```

## Controles en PC

| Tecla | Accion |
| --- | --- |
| `P` | Abre y cierra el menu. No apaga nada: deja el aim, el FOV y el ESP como estaban. |
| `Delete` | Descarga el script del cliente: borra la interfaz, el circulo y todas las conexiones. |
| `x` | El boton de cierre del panel hace lo mismo que `Delete`. |

## Controles en movil

| Elemento | Accion |
| --- | --- |
| Boton `B` | Abre y cierra el menu, igual que `P` en PC. |
| Arrastrar el boton `B` | Lo mueves donde te sea comodo y queda ahi. |
| Arrastrar la cabecera | Mueve el panel. |
| `x` | Descarga el script del cliente. |

El panel detecta el aparato: en celular agranda los controles, el cuadro de WalkSpeed
abre el teclado numerico y cualquier valor escrito se aplica al tocar afuera, sin
necesidad de confirmar.

El menu no se pierde al respawnear.

## Panel

| Control | Que hace |
| --- | --- |
| Sistema | Activa o apaga el apuntado. |
| Círculo FOV | Muestra u oculta el circulo alrededor del cursor. |
| WalkSpeed | Cuadro de texto, valor entre 0 y 100. |
| Campo de visión (FOV) | Slider de 10 a 400. Solo apunta a quien esta adentro del circulo. |

El circulo sigue al cursor y el panel se acomoda solo al cambiar el tamaño de la ventana.

## Estructura

```
main_code.lua          el unico que se ejecuta
.sys/
  rt/session.lua       version y modulos de la rama
  core/runtime.lua     el script
```

El loader verifica un checksum de cada modulo antes de correrlo. Si alguien
modifica un archivo del repo, el script no carga y avisa cual fue.

## Soporte

Discord: https://discord.gg/projectbnxyung7

Version 2.2 · canal release
