# Capítulo 27: A lib `socket` — TCP, UDP, AF_UNIX, Framing, DNS RFC 1035 e Kernel Sockets (`RGF-001`)

## 1. Por que existe a lib `socket`?

Sexamos sinceros: programar sockets BSD en C con `struct sockaddr_in`, `htons`, `inet_pton` e `getaddrinfo` (que ademais arrastra `libnss` de `glibc`) é un ritual arcano dos anos 80.

A lib **`socket`** ofrece dúas capas complementarias sen unha liña de C: (1) a API de descritores do kernel **`RGF-001`** para servidores de produción coma **Solstice** (`sys tcp listen`, `sys tcp listen reuseport`, `sys accept`, `sys tcp connect`, `sys send`, `sys recv`, `sys resolve ipv4` mediante `/etc/hosts` + paquetes DNS UDP RFC 1035 no porto 53) e (2) a máquina de estados funcional inmutable `Socket` con framing prefixado por lonxitude, liñas CRLF e subredes CIDR.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`socket`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/socket.rg` (dominio `SOCK`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/socket.rglib` | Distribución e importación directa con `import socket` |
| **Ficheiro compilado** | `target/socket.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libsocket.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import socket` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `socket`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `sys tcp listen / sys tcp listen reuseport / sys unix listen` | Enlaza e escoita en TCP IPv4 (`SO_REUSEADDR` / `SO_REUSEPORT`) ou `AF_UNIX` |
| `sys accept / sys tcp connect / sys unix connect` | `accept` e `connect` acoutados por timeout devolvendo `SockFdResult` / `SockAcceptResult` |
| `sys send / sys recv / sys shutdown write` | Envío, recepción e peche de escritura (`SHUT_WR`) de socket con timeout |
| `sys resolve ipv4 / dns resolve a` | Resolución IPv4 pura en Ridgun mediante `/etc/hosts` e consultas DNS UDP RFC 1035 |
| `sock send frame / sock recv frame / ipv4 in cidr` | Framing prefixado por lonxitude (`N:payload`) e coincidencia de subredes CIDR IPv4 |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `socket`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

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

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `socket` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import socket

fn :: verificar ip interna (ip : String) => Bool
      verificar ip interna ip =
        ipv4 in cidr ip "10.0.0.0/8"
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Actualización de rexistros con sintaxe inmutable `s with field = val`, resolución DNS sen `glibc`/`libnss` e códigos de estado deterministas (`0` OK, `-1` EOF, `-2` TIMEOUT, `-3` REFUSED).
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_socket.rg`.
