# Capítulo 25: La lib `argon2id` — RFC 9106 Argon2id sobre `Tensor[U64 * 8 * 16]`, Blake2b y Presets OWASP

## 1. ¿Por qué existe la lib `argon2id`?

Seamos sinceros: guardar contraseñas con un simple SHA-256 permite que una GPU moderna pruebe miles de millones de combinaciones por segundo, pero enlazar bibliotecas C externas para tener Argon2id suele traer dolores de cabeza de compilación y memoria.

La lib **`argon2id`** implementa **RFC 9106 Argon2id** y **RFC 7693 Blake2b-512** al 100 % en Ridgun puro operando directamente sobre bloques nativos `Tensor[U64 * 8 * 16]` (1 024 bytes por bloque en memoria contigua RMM2), con generación de cadenas **PHC** (`$argon2id$v=19$m=...,t=...,p=...$`), perfiles **OWASP** (`owaspfirst`, `owaspsecond`), soporte de *pepper* (`argon2id hash ctx`), derivación de claves (`argon2id derive key`) y detección de actualización de parámetros (`argon2id needs rehash`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`argon2id`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/argon2id.rg` (dominio `CRYPTO`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/argon2id.rglib` | Distribución e importación directa con `import argon2id` |
| **Archivo compilado** | `target/argon2id.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libargon2id.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import argon2id` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `argon2id`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `argon2id hash / argon2id verify` | Hashing PHC RFC 9106 de 6 argumentos (`pwd, salt, m_kib, t, p, tag_len`) y verificación en tiempo constante |
| `argon2id hash with preset / argon2id params preset` | Perfiles con nombre: `"interactive"`, `"owaspfirst"` (`19456 KiB, t=2`), `"owaspsecond"` (`47104 KiB, t=1`), `"moderate"`, `"sensitive"` |
| `argon2id hash ctx / argon2id verify ctx` | Hashing RFC 9106 con secreto `pepper` ($K$) y datos asociados ($X$) |
| `argon2id derive key / argon2id needs rehash` | Derivación de clave binaria cruda y detección de necesidad de rehash en cadenas PHC |
| `blake2b / blake2b hex` | Resumen criptográfico de propósito general RFC 7693 Blake2b (`1..64` bytes) |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `argon2id`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import argon2id

fn :: proteger clave usuario (clave : String) => (String, Bool, Bool)
      proteger clave usuario clave =
        phc    = argon2id hash clave "sal-unica-16byte" 32 2 1 32
        valido = argon2id verify clave phc
        rehash = argon2id needs rehash phc 19456 2 1 32
        (phc, valido, rehash)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `argon2id` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import argon2id

fn :: derivar clave maestra (frase : String) (sal : String) => String
      derivar clave maestra frase sal =
        -- Deriva 32 bytes crudos listos para ChaCha20-Poly1305 AEAD
        argon2id derive key frase sal 64 2 1 32
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Coincidencia byte a byte con los vectores oficiales RFC 9106 §5.3 y OpenSSL 3.5, operando sobre `Tensor[U64 * 8 * 16]` sin una sola línea de C.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_argon2id.rg`.
