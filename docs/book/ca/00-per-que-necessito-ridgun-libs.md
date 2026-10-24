# Capítol 00: Per què necessito `ridgun-libs`? 32 libs sense ni una línia de C? Explica-m'ho!

Siguem sincers: quan descobreixes que un llenguatge compila a un binari ELF natiu minúscul i sense recol·lector de brossa, la segona pregunta que et fas —amb tota la raó del món— és:

> *"D'acord, el llenguatge mola molt... però quan hagi d'obrir un socket TCP, calcular un hash Argon2id, analitzar un JSON, resoldre un sistema lineal amb tensors o muntar un pool d'actors, hauré d'enllaçar `libc`, `OpenSSL`, `libcurl` i `pcre2`, o baixar-me 800 paquets de tercers mantinguts per un desconegut?"*

És una pregunta excel·lent. I la resposta curta és: **no**. Per a això existeix **`ridgun-libs`**: una suite de **32 libs fonamentals** escrites al **100 % en Ridgun pur (`v0.9.16`)**, amb **zero dependències en C** i **zero `libc`**.

Posem nom als quatre mals de cap diaris que `ridgun-libs` elimina d'arrel.

---

## Mal de cap núm. 1: "L'infern de `libc`, OpenSSL i l'enllaçat creuat"

Segur que has viscut aquest malson:

1. Escrius un servidor o una eina CLI suposadament "estàtica" o "portable".
2. Tan bon punt necessites criptografia (`SHA-256`, `Argon2id`, `ChaCha20-Poly1305`), xarxa (`DNS`, `HTTP`, `WebSockets`) o expressions regulars, el teu programa acaba depenent de `glibc 2.38`, `libssl.so.3` i tres capçaleres de C.
3. Intentes copiar el binari a un contenidor mínim o a una altra distribució Linux i explota en arrencar amb l'infame `version 'GLIBC_2.38' not found`.

**Què canvia amb `ridgun-libs`?**
Cadascuna de les 32 libs d'aquest repositori està escrita íntegrament en Ridgun tabular i parla directament amb el nucli del sistema operatiu mitjançant la capa PAL (`posix`) o executa algorismes purs en memòria determinista (`RMM1`/`RMM2`). Es compilen tant a paquets portables (`.rglib` / `.rgc`) com a objectes compartits ELF64 natius (`lib*.so`). Sense `libc`, sense FFI fràgil i sense sorpreses en desplegar.

---

## Mal de cap núm. 2: "La síndrome del `node_modules` / `Cargo.lock` de 400 dependències"

En molts ecosistemes moderns, la biblioteca estàndard és tan esquelètica que per llegir un fitxer `.ini`, validar un `UUIDv7`, aplicar un pedaç Unified Diff o renderitzar una plantilla HTML segura necessites instal·lar mitja dotzena de paquets externs.

A **`ridgun-libs`**, les **32 libs** segueixen una única filosofia de disseny:

```ridgun
import crypto
import json
import http

fn :: autenticar y pedir (token : String) => String
      autenticar y pedir token =
        -- Totes les libs comparteixen tipus purs, alineació tabular i semàntica determinista
        mac_hex = sha256 hex token
        cuerpo  = json stringify (JnObj [("token_sha256", JnStr mac_hex)])
        pet     = http build request "POST" "/v1/sesion" [("Content-Type", "application/json")] cuerpo
        pet
```

Mateixa estètica tabular, mateixos ADTs immutables (`Option`, `Result`, `IoResult`, `JsonVal`), zero efectes laterals ocults.

---

## Mal de cap núm. 3: "Expressions regulars que pengen la CPU (ReDoS) i sockets que bloquegen per sempre"

Dues bombes de rellotgeria clàssiques a producció:

- Un usuari maliciós envia una cadena dissenyada perquè el teu motor d'expressions regulars amb *backtracking* entri en temps exponencial $O(2^N)$ i deixi fregit un nucli al 100 %.
- Un descriptor de xarxa es queda mig obert i el teu fil es queda bloquejat eternament esperant un `read()` sense data límit.

A **`ridgun-libs`**:
- La lib **`regex`** (Capítol 11) implementa un autòmat **NFA de Thompson** que garanteix temps lineal estricte **$O(N \cdot M)$**: immune per construcció a atacs ReDoS.
- Les libs **`posix`**, **`io`** i **`socket`** (Capítols 22, 23 i 27) integren quotes lèxiques `with timeout` i `ppoll` a nivell de descriptor: cap operació d'entrada/sortida pot penjar el teu servei.

---

## Mal de cap núm. 4: "Criptografia i àlgebra lineal que semblen jeroglífics"

A **`ridgun-libs`**, la potència dels tipus `Tensor[...]` de Ridgun permet que libs com **`tensor`** (Capítol 05), **`linalg`** (Capítol 06) i **`argon2id`** (Capítol 25) operin sobre blocs de memòria contigua (`Tensor[U64 * 8 * 16]`, `Tensor[Real]`) mantenint la llegibilitat d'una taula matemàtica.

---

## Mapa complet del llibre: 32 capítols per a 32 libs

Cada capítol d'aquest llibre està dedicat a **una lib** de `ridgun-libs`, agrupades en una progressió lògica de baix a dalt:

| Capítols | Família de libs | Libs incloses |
|---|---|---|
| **01 – 04** | Text, Matemàtiques i Estructures de Dades | `str`, `math`, `list`, `btree` |
| **05 – 06** | Tensors i Àlgebra Lineal | `tensor`, `linalg` |
| **07 – 10** | Codificació i Formats de Dades | `codec`, `json`, `csv`, `ini` |
| **11 – 15** | Motors de Text, Diffs, Plantilles i Formatat | `regex`, `glob`, `diff`, `template`, `fmt` |
| **16 – 21** | CLI, Rutes, Temps, UUIDs, Logs i Testing | `cli`, `path`, `time`, `uuid`, `log`, `test` |
| **22 – 23** | Sistemes POSIX i E/S amb Timeout | `posix`, `io` |
| **24 – 26** | Criptografia, Argon2id i Tokens JWT | `crypto`, `argon2id`, `jwt` |
| **27 – 29** | Xarxes, Sockets del Nucli, HTTP/1.1 i WebSockets | `socket`, `http`, `ws` |
| **30 – 32** | Concurrència d'Actors, Pools i Supervisió de Xarxa | `agent`, `pool`, `net_agent` |

Som-hi! Passa al **Capítol 01 (`str`)** i comencem a construir.
