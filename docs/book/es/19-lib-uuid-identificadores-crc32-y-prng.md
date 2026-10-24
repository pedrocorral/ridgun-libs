# Capítulo 19: La lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 y PRNG

## 1. ¿Por qué existe la lib `uuid`?

Seamos sinceros: usar `UUIDv4` completamente aleatorios como clave primaria en una base de datos fragmenta los índices B-Tree, mientras que inventarse IDs caseros sin entropía del kernel acaba en colisiones.

La lib **`uuid`** implementa **`UUIDv4`** (aleatorio con CSPRNG del kernel) y **`UUIDv7`** (ordenado cronológicamente en los primeros 48 bits según **RFC 9562**), sumas de verificación rápidas (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) y un PRNG determinista con semilla.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`uuid`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/uuid.rg` (dominio `UUID`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/uuid.rglib` | Distribución e importación directa con `import uuid` |
| **Archivo compilado** | `target/uuid.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libuuid.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import uuid` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `uuid`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Genera UUIDs canónicos de 36 caracteres RFC 9562 v4 (aleatorio) y v7 (ordenado por tiempo) |
| `uuid is valid / uuid version` | Valida la estructura 8-4-4-4-12 y los bits de variante RFC 9562 (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Hashes no criptográficos y sumas de verificación rápidas de 32 bits |
| `prng next / prng range` | PRNG congruencial lineal funcional puro para pruebas y simulaciones reproducibles |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `uuid`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `uuid` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: `uuid v7 at t1 < uuid v7 at t2` garantiza orden lexicográfico monótono creciente con el tiempo, ideal para índices `btree` y bases de datos.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_uuid.rg`.
