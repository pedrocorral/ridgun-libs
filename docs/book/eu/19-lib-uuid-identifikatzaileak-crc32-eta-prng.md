# 19. kapitulua: `uuid` lib-a — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 eta PRNG

## 1. Zergatik existitzen da `uuid` lib-a?

Izan gaitezen zintzoak: datu-base batean gako nagusi gisa erabat ausazko `UUIDv4`-ak erabiltzeak B-Tree indizeak zatikatzen ditu, eta nukleoaren entropiarik gabeko etxeko IDak asmatzeak talketan amaitzen du.

**`uuid`** lib-ak **`UUIDv4`** (nukleoaren CSPRNG bidezko ausazkoa) eta **`UUIDv7`** (**RFC 9562** arauaren arabera lehen 48 bitetan kronologikoki ordenatua), egiaztapen-batura azkarrak (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) eta hazidun PRNG determinista bat inplementatzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`uuid`** lehen mailako **lib** bat da, `src/main/ridgun/lib/uuid.rg` bidean kokatua (`UUID` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/uuid.rglib` | Banaketa eta inportazio zuzena `import uuid` bidez |
| **Fitxategi konpilatua** | `target/uuid.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libuuid.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import uuid` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `uuid` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | 36 karaktereko RFC 9562 v4 (ausazkoa) eta v7 (denboraz ordenatua) UUID kanonikoak sortzen ditu |
| `uuid is valid / uuid version` | 8-4-4-4-12 egitura eta RFC 9562 aldaera-bitak (`8, 9, a, b`) baliozkotzen ditu |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | 32 biteko hash ez-kriptografiko eta egiaztapen-batura azkarrak |
| `prng next / prng range` | Proba eta simulazio errepikagarrietarako PRNG kongruentzial lineal funtzional hutsa |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `uuid` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`uuid` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: `uuid v7 at t1 < uuid v7 at t2`-k denborarekin hazten den ordena lexikografiko monotonoa bermatzen du, `btree` indizeetarako eta datu-baseetarako aproposa.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_uuid.rg` suite automatizatuaren bidez.
