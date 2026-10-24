# Kapitel 00: Varför behöver jag `ridgun-libs`? 32 libs utan en enda rad C? Berätta mer!

Låt oss vara ärliga: när du upptäcker att ett språk kompilerar till en pytteliten inbyggd ELF-binär utan skräpsamlare är nästa naturliga fråga du ställer dig — med all rätt:

> *"Okej, själva språket är fantastiskt... men så fort jag behöver öppna en TCP-socket, beräkna en Argon2id-hash, tolka JSON, lösa ett linjärt ekvationssystem med tensorer eller starta en aktörspool, måste jag då länka in `libc`, `OpenSSL`, `libcurl` och `pcre2`, eller ladda ner 800 tredjepartspaket som underhålls av främlingar?"*

Det är en utmärkt fråga. Och det korta svaret är: **nej**. Det är precis därför **`ridgun-libs`** finns: en svit med **32 grundläggande libs** skrivna i **100 % ren Ridgun (`v0.9.16`)**, med **noll C-beroenden** och **noll `libc`**.

Låt oss sätta namn på de fyra vardagsplågor som `ridgun-libs` eliminerar från grunden.

---

## Plåga nr 1: "Helvetet med `libc`, OpenSSL och korslänkning"

Du har garanterat varit med om den här mardrömmen:

1. Du skriver en server eller ett CLI-verktyg som ska vara "portabelt".
2. Så fort du behöver kryptografi (`SHA-256`, `Argon2id`, `ChaCha20-Poly1305`), nätverk (`DNS`, `HTTP`, `WebSockets`) eller reguljära uttryck blir din binär beroende av `glibc 2.38`, `libssl.so.3` och C-headers.
3. Du kopierar binären till en minimal container eller en annan Linux-distribution och den kraschar direkt vid start med det ökända `version 'GLIBC_2.38' not found`.

**Vad förändras med `ridgun-libs`?**
Var och en av de 32 libs som ingår i detta arkiv är skriven helt i tabulär Ridgun och talar direkt med operativsystemets kärna via PAL-lagret (`posix`) eller kör rena algoritmer i deterministiskt minne (`RMM1`/`RMM2`). Alla libs kompileras både till portabla paket (`.rglib` / `.rgc`) och till inbyggda delade ELF64-objekt (`lib*.so`). Utan `libc`, utan bräcklig FFI och utan överraskningar vid driftsättning.

---

## Plåga nr 2: "`node_modules`- och `Cargo.lock`-syndromet med 400 beroenden"

I många moderna ekosystem är standardbiblioteket så avskalat att du måste installera ett halvt dussin externa paket bara för att läsa en `.ini`-fil, validera en `UUIDv7`, applicera en Unified Diff-patch eller rendera en säker HTML-mall.

I **`ridgun-libs`** följer alla **32 libs** en enda sammanhängande designfilosofi:

```ridgun
import crypto
import json
import http

fn :: autenticar y pedir (token : String) => String
      autenticar y pedir token =
        -- Alla libs delar rena typer, tabelljustering och deterministisk semantik
        mac_hex = sha256 hex token
        cuerpo  = json stringify (JnObj [("token_sha256", JnStr mac_hex)])
        pet     = http build request "POST" "/v1/sesion" [("Content-Type", "application/json")] cuerpo
        pet
```

Samma tabulära estetik, samma oföränderliga ADT:er (`Option`, `Result`, `IoResult`, `JsonVal`), noll dolda sidoeffekter.

---

## Plåga nr 3: "Reguljära uttryck som låser processorn (ReDoS) och sockets som hänger för evigt"

Två klassiska tidsinställda bomber i produktion:

- En illvillig användare skickar en sträng som tvingar en regex-motor med *backtracking* in i exponentiell tid $O(2^N)$ och låser en CPU-kärna på 100 %.
- En nätverksanslutning stannar upp mitt i en överföring och din tråd blockeras för evigt i en `read()` utan tidsgräns.

I **`ridgun-libs`**:
- Lib:en **`regex`** (Kapitel 11) bygger på en **Thompson-NFA**-automat som garanterar strikt linjär tid **$O(N \cdot M)$** — immun mot ReDoS-attacker genom sin konstruktion.
- Libs som **`posix`**, **`io`** och **`socket`** (Kapitel 22, 23 och 27) integrerar lexikala tidsgränser (`with timeout`) och `ppoll` på deskriptornivå.

---

## Plåga nr 4: "Kryptografi och linjär algebra som ser ut som hieroglyfer"

I **`ridgun-libs`** gör Ridguns inbyggda `Tensor[...]`-typer att libs som **`tensor`** (Kapitel 05), **`linalg`** (Kapitel 06) och **`argon2id`** (Kapitel 25) kan arbeta direkt över sammanhängande minnesblock (`Tensor[U64 * 8 * 16]`, `Tensor[Real]`) med samma läsbarhet som en matematisk tabell.

---

## Komplett bokkarta: 32 kapitel för 32 libs

Varje kapitel i den här boken är tillägnat **en lib** i `ridgun-libs`, ordnade i en logisk progression nerifrån och upp:

| Kapitel | Lib-familj | Inkluderade libs |
|---|---|---|
| **01 – 04** | Text, Matematik och Datastrukturer | `str`, `math`, `list`, `btree` |
| **05 – 06** | Tensorer och Linjär Algebra | `tensor`, `linalg` |
| **07 – 10** | Kodning och Dataformat | `codec`, `json`, `csv`, `ini` |
| **11 – 15** | Textmotorer, Diff, Mallar och Formatering | `regex`, `glob`, `diff`, `template`, `fmt` |
| **16 – 21** | CLI, Sökvägar, Tid, UUID, Loggning och Testning | `cli`, `path`, `time`, `uuid`, `log`, `test` |
| **22 – 23** | POSIX-system och Tidsbegränsad I/O | `posix`, `io` |
| **24 – 26** | Kryptografi, Argon2id och JWT-tokens | `crypto`, `argon2id`, `jwt` |
| **27 – 29** | Nätverk, Kärn-sockets, HTTP/1.1 och WebSockets | `socket`, `http`, `ws` |
| **30 – 32** | Aktörskonkurrens, Worker-pooler och Nätverksövervakning | `agent`, `pool`, `net_agent` |

Nu kör vi! Bläddra till **Kapitel 01 (`str`)** och börja bygga.
