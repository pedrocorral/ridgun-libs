# Kapitel 27: Lib:en `socket` — TCP, UDP, AF_UNIX, Framing, DNS och `RGF-001` Kärn-sockets

## 1. Varför finns lib:en `socket`?

Låt oss vara ärliga: att programmera BSD-sockets i C med `struct sockaddr_in`, `htons`, `inet_pton` och `getaddrinfo` (som dessutom drar in `libnss` från `glibc`) är en otymplig 80-talsritual.

Lib:en **`socket`** erbjuder två kompletterande lager helt utan C: (1) kärndeskriptor-API:et **`RGF-001`** för produktionsservrar som **Solstice** (`sys tcp listen`, `sys tcp listen reuseport`, `sys accept`, `sys tcp connect`, `sys send`, `sys recv`, `sys resolve ipv4` via `/etc/hosts` + RFC 1035 UDP-DNS-paket på port 53) och (2) den oföränderliga funktionella tillståndsmaskinen `Socket` med längdprefixad framing, CRLF-rader och CIDR-subnät.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`socket`** en förstklassig **lib** placerad i `src/main/ridgun/lib/socket.rg` (domän `SOCK`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/socket.rglib` | Portabel distribution och direkt import med `import socket` |
| **Kompilerat arkiv** | `target/socket.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libsocket.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import socket` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `socket`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `sys tcp listen / sys tcp listen reuseport / sys unix listen` | Binder och lyssnar på IPv4 TCP (`SO_REUSEADDR` / `SO_REUSEPORT`) eller `AF_UNIX` |
| `sys accept / sys tcp connect / sys unix connect` | Tidsbegränsad `accept` och `connect` som returnerar `SockFdResult` / `SockAcceptResult` |
| `sys send / sys recv / sys shutdown write` | Tidsbegränsad sändning, mottagning och skrivstängning (`SHUT_WR`) på kärn-socket |
| `sys resolve ipv4 / dns resolve a` | Ren Ridgun IPv4-uppslagning via `/etc/hosts` och RFC 1035 UDP DNS-frågor |
| `sock send frame / sock recv frame / ipv4 in cidr` | Längdprefixad (`N:payload`) framing och IPv4 CIDR-subnätsmatchning |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `socket`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

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

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `socket` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import socket

fn :: verificar ip interna (ip : String) => Bool
      verificar ip interna ip =
        ipv4 in cidr ip "10.0.0.0/8"
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Postuppdatering med oföränderlig `s with field = val`-syntax, DNS-uppslagning utan `glibc`/`libnss` och deterministiska statuskoder (`0` OK, `-1` EOF, `-2` TIMEOUT, `-3` REFUSED).
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_socket.rg`.
