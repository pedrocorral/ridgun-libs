# Capítol 27: La lib `socket` — TCP, UDP, AF_UNIX, Framing, DNS RFC 1035 i Kernel Sockets (`RGF-001`)

## 1. Per què existeix la lib `socket`?

Siguem sincers: programar sockets BSD en C amb `struct sockaddr_in`, `htons`, `inet_pton` i `getaddrinfo` (que a més arrossega `libnss` de `glibc`) és un ritual arcà dels anys 80.

La lib **`socket`** ofereix dues capes complementàries sense ni una línia de C: (1) l'API de descriptors del nucli **`RGF-001`** per a servidors de producció com **Solstice** (`sys tcp listen`, `sys tcp listen reuseport`, `sys accept`, `sys tcp connect`, `sys send`, `sys recv`, `sys resolve ipv4` mitjançant `/etc/hosts` + paquets DNS UDP RFC 1035 al port 53) i (2) la màquina d'estats funcional immutable `Socket` amb framing prefixat per longitud, línies CRLF i subxarxes CIDR.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`socket`** és una **lib** de primera classe situada a `src/main/ridgun/lib/socket.rg` (domini `SOCK`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/socket.rglib` | Distribució i importació directa amb `import socket` |
| **Fitxer compilat** | `target/socket.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libsocket.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import socket` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `socket`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `sys tcp listen / sys tcp listen reuseport / sys unix listen` | Enllaça i escolta en TCP IPv4 (`SO_REUSEADDR` / `SO_REUSEPORT`) o `AF_UNIX` |
| `sys accept / sys tcp connect / sys unix connect` | `accept` i `connect` acotats per timeout retornant `SockFdResult` / `SockAcceptResult` |
| `sys send / sys recv / sys shutdown write` | Enviament, recepció i tancament d'escriptura (`SHUT_WR`) de socket amb timeout |
| `sys resolve ipv4 / dns resolve a` | Resolució IPv4 pura en Ridgun mitjançant `/etc/hosts` i consultes DNS UDP RFC 1035 |
| `sock send frame / sock recv frame / ipv4 in cidr` | Framing prefixat per longitud (`N:payload`) i coincidència de subxarxes CIDR IPv4 |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `socket`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

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

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `socket` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import socket

fn :: verificar ip interna (ip : String) => Bool
      verificar ip interna ip =
        ipv4 in cidr ip "10.0.0.0/8"
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Actualització de registres amb sintaxi immutable `s with field = val`, resolució DNS sense `glibc`/`libnss` i codis d'estat deterministes (`0` OK, `-1` EOF, `-2` TIMEOUT, `-3` REFUSED).
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_socket.rg`.
