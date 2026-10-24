# Capítol 19: La lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 i PRNG

## 1. Per què existeix la lib `uuid`?

Siguem sincers: fer servir `UUIDv4` completament aleatoris com a clau primària en una base de dades fragmenta els índexs B-Tree, mentre que inventar-se IDs casolans sense entropia del nucli acaba en col·lisions.

La lib **`uuid`** implementa **`UUIDv4`** (aleatori amb CSPRNG del nucli) i **`UUIDv7`** (ordenat cronològicament en els primers 48 bits segons **RFC 9562**), sumes de verificació ràpides (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) i un PRNG determinista amb llavor.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`uuid`** és una **lib** de primera classe situada a `src/main/ridgun/lib/uuid.rg` (domini `UUID`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/uuid.rglib` | Distribució i importació directa amb `import uuid` |
| **Fitxer compilat** | `target/uuid.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libuuid.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import uuid` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `uuid`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Genera UUIDs canònics de 36 caràcters RFC 9562 v4 (aleatori) i v7 (ordenat pel temps) |
| `uuid is valid / uuid version` | Valida l'estructura 8-4-4-4-12 i els bits de variant RFC 9562 (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Hashes no criptogràfics i sumes de verificació ràpides de 32 bits |
| `prng next / prng range` | PRNG congruencial lineal funcional pur per a proves i simulacions reproduïbles |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `uuid`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `uuid` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: `uuid v7 at t1 < uuid v7 at t2` garanteix ordre lexicogràfic monòton creixent amb el temps, ideal per a índexs `btree` i bases de dades.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_uuid.rg`.
