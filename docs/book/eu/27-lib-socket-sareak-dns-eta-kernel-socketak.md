# 27. kapitulua: `socket` lib-a — TCP, UDP, AF_UNIX, Framing, RFC 1035 DNS eta Kernel Socketak (`RGF-001`)

## 1. Zergatik existitzen da `socket` lib-a?

Izan gaitezen zintzoak: C-n BSD socketak `struct sockaddr_in`, `htons`, `inet_pton` eta `getaddrinfo`-rekin programatzea (`glibc`-ren `libnss` arrastaka dakarrena gainera) 80ko hamarkadako erritu arkano bat da.

**`socket`** lib-ak bi geruza osagarri eskaintzen ditu C lerro bakar bat gabe: (1) **Solstice** bezalako ekoizpen-zerbitzarietarako **`RGF-001`** nukleoko deskribatzaileen APIa (`sys tcp listen`, `sys tcp listen reuseport`, `sys accept`, `sys tcp connect`, `sys send`, `sys recv`, `sys resolve ipv4` `/etc/hosts` + 53 atakako RFC 1035 UDP DNS paketeen bidez) eta (2) `Socket` egoera-makina funtzional aldaezina luzera-aurrizkidun framing, CRLF lerro eta CIDR azpisareekin.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`socket`** lehen mailako **lib** bat da, `src/main/ridgun/lib/socket.rg` bidean kokatua (`SOCK` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/socket.rglib` | Banaketa eta inportazio zuzena `import socket` bidez |
| **Fitxategi konpilatua** | `target/socket.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libsocket.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import socket` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `socket` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `sys tcp listen / sys tcp listen reuseport / sys unix listen` | IPv4 TCP (`SO_REUSEADDR` / `SO_REUSEPORT`) edo `AF_UNIX` entzuten jartzen du |
| `sys accept / sys tcp connect / sys unix connect` | Timeout bidez mugatutako `accept` eta `connect`, `SockFdResult` / `SockAcceptResult` itzuliz |
| `sys send / sys recv / sys shutdown write` | Timeout bidezko socket bidalketa, harrera eta idazketa-itxiera (`SHUT_WR`) |
| `sys resolve ipv4 / dns resolve a` | Ridgun hutseko IPv4 ebazpena `/etc/hosts` eta RFC 1035 UDP DNS kontsulten bidez |
| `sock send frame / sock recv frame / ipv4 in cidr` | Luzera-aurrizkidun (`N:payload`) framinga eta IPv4 CIDR azpisareen bat-etortzea |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `socket` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

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

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`socket` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import socket

fn :: verificar ip interna (ip : String) => Bool
      verificar ip interna ip =
        ipv4 in cidr ip "10.0.0.0/8"
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Erregistroen eguneratzea `s with field = val` sintaxi aldaezinarekin, `glibc`/`libnss` gabeko DNS ebazpena eta egoera-kode deterministak (`0` OK, `-1` EOF, `-2` TIMEOUT, `-3` REFUSED).
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_socket.rg` suite automatizatuaren bidez.
