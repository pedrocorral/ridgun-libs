# Capítulo 27: La lib `socket` — TCP, UDP, AF_UNIX, Framing, DNS RFC 1035 y Kernel Sockets (`RGF-001`)

## 1. ¿Por qué existe la lib `socket`?

Seamos sinceros: programar sockets BSD en C con `struct sockaddr_in`, `htons`, `inet_pton` y `getaddrinfo` (que además arrastra `libnss` de `glibc`) es un ritual arcano de los años 80.

La lib **`socket`** ofrece dos capas complementarias sin una línea de C: (1) la API de descriptores del kernel **`RGF-001`** para servidores de producción como **Solstice** (`sys tcp listen`, `sys tcp listen reuseport`, `sys accept`, `sys tcp connect`, `sys send`, `sys recv`, `sys resolve ipv4` mediante `/etc/hosts` + paquetes DNS UDP RFC 1035 en el puerto 53) y (2) la máquina de estados funcional inmutable `Socket` con framing prefijado por longitud, líneas CRLF y subredes CIDR.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`socket`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/socket.rg` (dominio `SOCK`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/socket.rglib` | Distribución e importación directa con `import socket` |
| **Archivo compilado** | `target/socket.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libsocket.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import socket` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `socket`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `sys tcp listen / sys tcp listen reuseport / sys unix listen` | Enlaza y escucha en TCP IPv4 (`SO_REUSEADDR` / `SO_REUSEPORT`) o `AF_UNIX` |
| `sys accept / sys tcp connect / sys unix connect` | `accept` y `connect` acotados por timeout devolviendo `SockFdResult` / `SockAcceptResult` |
| `sys send / sys recv / sys shutdown write` | Envío, recepción y cierre de escritura (`SHUT_WR`) de socket con timeout |
| `sys resolve ipv4 / dns resolve a` | Resolución IPv4 pura en Ridgun mediante `/etc/hosts` y consultas DNS UDP RFC 1035 |
| `sock send frame / sock recv frame / ipv4 in cidr` | Framing prefijado por longitud (`N:payload`) y coincidencia de subredes CIDR IPv4 |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `socket`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import socket

fn :: eco tcp local () => String
      eco tcp local =
        l_res = sys tcp listen "127.0.0.1" 0 16
        lfd   = sock fd l_res
        port  = sys local port lfd
        c_res = sys tcp connect "127.0.0.1" port 1000
        cfd   = sock fd c_res
        a_res = sys accept lfd 1000
        sfd   = sock accept fd a_res
        _     = sys send cfd "hola-solstice" 1000
        r_res = sys recv sfd 64 1000
        datos = sock recv data r_res
        _     = sys_close cfd
        _     = sys_close sfd
        _     = sys_close lfd
        datos
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `socket` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import socket

fn :: verificar ip interna (ip : String) => Bool
      verificar ip interna ip =
        ipv4 in cidr ip "10.0.0.0/8"
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Actualización de registros con sintaxis inmutable `s with field = val`, resolución DNS sin `glibc`/`libnss` y códigos de estado deterministas (`0` OK, `-1` EOF, `-2` TIMEOUT, `-3` REFUSED).
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_socket.rg`.
