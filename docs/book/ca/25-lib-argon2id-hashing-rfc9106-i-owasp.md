# Capítol 25: La lib `argon2id` — RFC 9106 Argon2id sobre `Tensor[U64 * 8 * 16]`, Blake2b i Presets OWASP

## 1. Per què existeix la lib `argon2id`?

Siguem sincers: desar contrasenyes amb un simple SHA-256 permet que una GPU moderna provi milers de milions de combinacions per segon, però enllaçar biblioteques C externes per tenir Argon2id sol portar mals de cap de compilació i memòria.

La lib **`argon2id`** implementa **RFC 9106 Argon2id** i **RFC 7693 Blake2b-512** al 100 % en Ridgun pur operant directament sobre blocs natius `Tensor[U64 * 8 * 16]` (1 024 bytes per bloc en memòria contigua RMM2), amb generació de cadenes **PHC** (`$argon2id$v=19$m=...,t=...,p=...$`), perfils **OWASP** (`owaspfirst`, `owaspsecond`), suport de *pepper* (`argon2id hash ctx`), derivació de claus (`argon2id derive key`) i detecció d'actualització de paràmetres (`argon2id needs rehash`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`argon2id`** és una **lib** de primera classe situada a `src/main/ridgun/lib/argon2id.rg` (domini `CRYPTO`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/argon2id.rglib` | Distribució i importació directa amb `import argon2id` |
| **Fitxer compilat** | `target/argon2id.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libargon2id.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import argon2id` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `argon2id`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `argon2id hash / argon2id verify` | Hashing PHC RFC 9106 de 6 arguments (`pwd, salt, m_kib, t, p, tag_len`) i verificació en temps constant |
| `argon2id hash with preset / argon2id params preset` | Perfils amb nom: `"interactive"`, `"owaspfirst"` (`19456 KiB, t=2`), `"owaspsecond"` (`47104 KiB, t=1`), `"moderate"`, `"sensitive"` |
| `argon2id hash ctx / argon2id verify ctx` | Hashing RFC 9106 amb secret `pepper` ($K$) i dades associades ($X$) |
| `argon2id derive key / argon2id needs rehash` | Derivació de clau binària crua i detecció de necessitat de rehash en cadenes PHC |
| `blake2b / blake2b hex` | Resum criptogràfic de propòsit general RFC 7693 Blake2b (`1..64` bytes) |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `argon2id`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import argon2id

fn :: proteger clave usuario (clave : String) => (String, Bool, Bool)
      proteger clave usuario clave =
        phc    = argon2id hash clave "sal-unica-16byte" 32 2 1 32
        valido = argon2id verify clave phc
        rehash = argon2id needs rehash phc 19456 2 1 32
        (phc, valido, rehash)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `argon2id` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import argon2id

fn :: derivar clave maestra (frase : String) (sal : String) => String
      derivar clave maestra frase sal =
        -- Deriva 32 bytes crudos listos para ChaCha20-Poly1305 AEAD
        argon2id derive key frase sal 64 2 1 32
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Coincidència byte a byte amb els vectors oficials RFC 9106 §5.3 i OpenSSL 3.5, operant sobre `Tensor[U64 * 8 * 16]` sense ni una sola línia de C.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_argon2id.rg`.
