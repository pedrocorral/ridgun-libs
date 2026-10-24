# 25. kapitulua: `argon2id` lib-a — RFC 9106 Argon2id `Tensor[U64 * 8 * 16]` gainean, Blake2b eta OWASP Aurrezarpenak

## 1. Zergatik existitzen da `argon2id` lib-a?

Izan gaitezen zintzoak: pasahitzak SHA-256 soil batekin gordetzeak GPU moderno bati segundoko milaka milioi konbinazio probatzea ahalbidetzen dio, baina Argon2id izateko kanpoko C liburutegiak estekatzeak konpilazio- eta memoria-buruhausteak ekartzen ditu.

**`argon2id`** lib-ak **RFC 9106 Argon2id** eta **RFC 7693 Blake2b-512** % 100ean Ridgun hutsean inplementatzen ditu `Tensor[U64 * 8 * 16]` bloke natiboen gainean (1 024 byte blokeko RMM2 memoria jarraituan), **PHC** kateen sorrerarekin (`$argon2id$v=19$m=...,t=...,p=...$`), **OWASP** profilekin (`owaspfirst`, `owaspsecond`), *pepper* euskarriarekin (`argon2id hash ctx`), gakoen eratorpenarekin (`argon2id derive key`) eta parametroen eguneratze-detekzioarekin (`argon2id needs rehash`).

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`argon2id`** lehen mailako **lib** bat da, `src/main/ridgun/lib/argon2id.rg` bidean kokatua (`CRYPTO` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/argon2id.rglib` | Banaketa eta inportazio zuzena `import argon2id` bidez |
| **Fitxategi konpilatua** | `target/argon2id.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libargon2id.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import argon2id` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `argon2id` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `argon2id hash / argon2id verify` | 6 argumentuko RFC 9106 PHC pasahitz-hashinga (`pwd, salt, m_kib, t, p, tag_len`) eta denbora konstanteko egiaztapena |
| `argon2id hash with preset / argon2id params preset` | Izendun profilak: `"interactive"`, `"owaspfirst"` (`19456 KiB, t=2`), `"owaspsecond"` (`47104 KiB, t=1`), `"moderate"`, `"sensitive"` |
| `argon2id hash ctx / argon2id verify ctx` | RFC 9106 hashinga `pepper` sekretuarekin ($K$) eta datu elkartuekin ($X$) |
| `argon2id derive key / argon2id needs rehash` | Gako bitar gordinaren eratorpena eta PHC kateetan rehash beharraren detekzioa |
| `blake2b / blake2b hex` | Helburu orokorreko RFC 7693 Blake2b laburpen kriptografikoa (`1..64` byte) |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `argon2id` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import argon2id

fn :: proteger clave usuario (clave : String) => (String, Bool, Bool)
      proteger clave usuario clave =
        phc    = argon2id hash clave "sal-unica-16byte" 32 2 1 32
        valido = argon2id verify clave phc
        rehash = argon2id needs rehash phc 19456 2 1 32
        (phc, valido, rehash)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`argon2id` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import argon2id

fn :: derivar clave maestra (frase : String) (sal : String) => String
      derivar clave maestra frase sal =
        -- Deriva 32 bytes crudos listos para ChaCha20-Poly1305 AEAD
        argon2id derive key frase sal 64 2 1 32
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Bat-etortze zehatza bytez byte RFC 9106 §5.3 eta OpenSSL 3.5 bektore ofizialekin, `Tensor[U64 * 8 * 16]` gainean C lerro bakar bat ere gabe lan eginez.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_argon2id.rg` suite automatizatuaren bidez.
