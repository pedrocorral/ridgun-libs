# Capítulo 19: A lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 e PRNG

## 1. Por que existe a lib `uuid`?

Sexamos sinceros: usar `UUIDv4` completamente aleatorios como chave primaria nunha base de datos fragmenta os índices B-Tree, mentres que inventarse IDs caseiros sen entropía do kernel acaba en colisións.

A lib **`uuid`** implementa **`UUIDv4`** (aleatorio con CSPRNG do kernel) e **`UUIDv7`** (ordenado cronoloxicamente nos primeiros 48 bits segundo **RFC 9562**), sumas de verificación rápidas (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) e un PRNG determinista con semente.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`uuid`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/uuid.rg` (dominio `UUID`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/uuid.rglib` | Distribución e importación directa con `import uuid` |
| **Ficheiro compilado** | `target/uuid.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libuuid.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import uuid` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `uuid`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Xera UUIDs canónicos de 36 caracteres RFC 9562 v4 (aleatorio) e v7 (ordenado polo tempo) |
| `uuid is valid / uuid version` | Valida a estrutura 8-4-4-4-12 e os bits de variante RFC 9562 (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Hashes non criptográficos e sumas de verificación rápidas de 32 bits |
| `prng next / prng range` | PRNG congruencial lineal funcional puro para probas e simulacións reproducibles |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `uuid`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `uuid` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: `uuid v7 at t1 < uuid v7 at t2` garante orde lexicográfica monótona crecente co tempo, ideal para índices `btree` e bases de datos.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_uuid.rg`.
