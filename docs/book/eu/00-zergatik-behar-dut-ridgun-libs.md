# 00. kapitulua: Zergatik behar dut `ridgun-libs`? 32 lib C lerro bakar bat gabe? Kontaidazu gehiago!

Izan gaitezen zintzoak: lengoaia batek zabor-biltzailerik gabeko ELF bitar natibo txiki-txiki batera konpilatzen duela deskubritzen duzunean, zeure buruari egiten diozun bigarren galdera —arrazoi osoz— hauxe da:

> *"Ados, lengoaia bikaina da... baina TCP socket bat ireki, Argon2id hash bat kalkulatu, JSON bat analizatu, tentsoreekin sistema lineal bat ebatzi edo aktore-pool bat muntatu behar dudanean, `libc`, `OpenSSL`, `libcurl` eta `pcre2` estekatu beharko ditut, ala ezezagun batek mantendutako hirugarrenen 800 pakete deskargatu?"*

Galdera bikaina da. Eta erantzun laburra hauxe da: **ez**. Horretarako existitzen da **`ridgun-libs`**: **% 100ean Ridgun hutsean (`v0.9.16`)** idatzitako **oinarrizko 32 lib-eko** suitea, **zero C mendekotasunekin** eta **zero `libc`-rekin**.

Jar diezaiegun izena `ridgun-libs`-ek errotik ezabatzen dituen eguneroko lau minei.

---

## 1. mina: "`libc`, OpenSSL eta estekatze gurutzatuaren infernua"

Ziur amesgaizto hau bizi izan duzula:

1. Ustez "estatikoa" edo "eramangarria" den zerbitzari edo CLI tresna bat idazten duzu.
2. Kriptografia (`SHA-256`, `Argon2id`, `ChaCha20-Poly1305`), sarea (`DNS`, `HTTP`, `WebSockets`) edo adierazpen erregularrak behar dituzun bezain laster, zure programa `glibc 2.38`, `libssl.so.3` eta C-ko hiru goibururen menpe geratzen da.
3. Bitarra edukiontzi minimo batera edo beste Linux banaketa batera kopiatzen saiatzen zara eta abiaraztean eztanda egiten du `version 'GLIBC_2.38' not found` mezu ezagunarekin.

**Zer aldatzen da `ridgun-libs`-ekin?**
Biltegi honetako 32 lib-etako bakoitza oso-osorik Ridgun taularatuan idatzita dago eta zuzenean sistema eragilearen nukleoarekin hitz egiten du PAL geruzaren bidez (`posix`), edo algoritmo hutsak exekutatzen ditu memoria deterministan (`RMM1`/`RMM2`). Pakete eramangarrietara (`.rglib` / `.rgc`) zein ELF64 objektu partekatu natiboetara (`lib*.so`) konpilatzen dira. `libc` gabe, FFI hauskorrik gabe eta ustekaberik gabe.

---

## 2. mina: "400 mendekotasuneko `node_modules` / `Cargo.lock` sindromea"

Ekosistema moderno askotan, liburutegi estandarra hain da hezurdura hutsa ezen `.ini` fitxategi bat irakurtzeko, `UUIDv7` bat baliozkotzeko, Unified Diff adabaki bat aplikatzeko edo HTML txantiloi seguru bat errenderizatzeko kanpoko dozena erdi pakete instalatu behar baitituzu.

**`ridgun-libs`**-en, **32 lib-ek** diseinu-filosofia bakar bati jarraitzen diote:

```ridgun
import crypto
import json
import http

fn :: autenticar y pedir (token : String) => String
      autenticar y pedir token =
        -- Lib guztiek mota hutsak, lerrokatze taularatua eta semantika determinista partekatzen dituzte
        mac_hex = sha256 hex token
        cuerpo  = json stringify (JnObj [("token_sha256", JnStr mac_hex)])
        pet     = http build request "POST" "/v1/sesion" [("Content-Type", "application/json")] cuerpo
        pet
```

Estetika taularatu bera, ADT aldaezin berdinak (`Option`, `Result`, `IoResult`, `JsonVal`), zero albo-ondorio ezkutu.

---

## 3. mina: "PUZa zintzilikatzen duten adierazpen erregularrak (ReDoS) eta betiko blokeatzen diren socketak"

Ekoizpeneko bi erloju-bonba klasiko:

- Erabiltzaile gaizto batek kate berezi bat bidaltzen du zure *backtracking* bidezko adierazpen erregularren motorra $O(2^N)$ denbora esponentzialean sartzeko eta nukleo bat % 100ean erretzeko.
- Sare-deskribatzaile bat erdi irekita geratzen da eta zure haria betiko blokeatuta geratzen da epemugarik gabeko `read()` baten zain.

**`ridgun-libs`**-en:
- **`regex`** lib-ak (11. kapitulua) **Thompsonen NFA** automata bat inplementatzen du, **$O(N \cdot M)$** denbora lineal zorrotza bermatuz: ReDoS erasoen aurka immunizatua eraikuntzaz.
- **`posix`**, **`io`** eta **`socket`** lib-ek (22, 23 eta 27. kapituluak) `with timeout` kuota lexikoak eta `ppoll` integratzen dituzte deskribatzaile-mailan: sarrera/irteerako inongo eragiketak ezin du zure zerbitzua zintzilik utzi.

---

## 4. mina: "Hieroglifikoak diruditen kriptografia eta aljebra lineala"

**`ridgun-libs`**-en, Ridgunen `Tensor[...]` moten ahalmenari esker, **`tensor`** (05. kapitulua), **`linalg`** (06. kapitulua) eta **`argon2id`** (25. kapitulua) bezalako lib-ek memoria jarraituko blokeen gainean (`Tensor[U64 * 8 * 16]`, `Tensor[Real]`) lan egiten dute, taula matematiko baten irakurgarritasuna mantenduz.

---

## Liburuaren mapa osoa: 32 kapitulu 32 lib-entzat

Liburu honetako kapitulu bakoitza `ridgun-libs`-eko **lib bati** eskainita dago, behetik gorako progresio logiko batean multzokatuta:

| Kapituluak | Lib familia | Barne hartutako lib-ak |
|---|---|---|
| **01 – 04** | Testua, Matematika eta Datu-egiturak | `str`, `math`, `list`, `btree` |
| **05 – 06** | Tentsoreak eta Aljebra Lineala | `tensor`, `linalg` |
| **07 – 10** | Kodetzea eta Datu-formatuak | `codec`, `json`, `csv`, `ini` |
| **11 – 15** | Testu-motorrak, Diff-ak, Txantiloiak eta Formateatzea | `regex`, `glob`, `diff`, `template`, `fmt` |
| **16 – 21** | CLI, Bideak, Denbora, UUIDak, Log-ak eta Testing-a | `cli`, `path`, `time`, `uuid`, `log`, `test` |
| **22 – 23** | POSIX Sistemak eta Timeout bidezko S/I | `posix`, `io` |
| **24 – 26** | Kriptografia, Argon2id eta JWT Tokenak | `crypto`, `argon2id`, `jwt` |
| **27 – 29** | Sareak, Nukleoko Socketak, HTTP/1.1 eta WebSocketak | `socket`, `http`, `ws` |
| **30 – 32** | Aktoreen Konkurrentzia, Pool-ak eta Sare-gainbegiratzea | `agent`, `pool`, `net_agent` |

Aurrera ba! Joan **01. kapitulura (`str`)** eta has gaitezen eraikitzen.
