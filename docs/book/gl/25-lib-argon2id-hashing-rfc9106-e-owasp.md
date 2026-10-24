# Capítulo 25: A lib `argon2id` — RFC 9106 Argon2id sobre `Tensor[U64 * 8 * 16]`, Blake2b e Presets OWASP

## 1. Por que existe a lib `argon2id`?

Sexamos sinceros: gardar contrasinais cun simple SHA-256 permite que unha GPU moderna probe miles de millóns de combinacións por segundo, pero enlazar bibliotecas C externas para ter Argon2id adoita traer dores de cabeza de compilación e memoria.

A lib **`argon2id`** implementa **RFC 9106 Argon2id** e **RFC 7693 Blake2b-512** ao 100 % en Ridgun puro operando directamente sobre bloques nativos `Tensor[U64 * 8 * 16]` (1 024 bytes por bloque en memoria contigua RMM2), con xeración de cadeas **PHC** (`$argon2id$v=19$m=...,t=...,p=...$`), perfís **OWASP** (`owaspfirst`, `owaspsecond`), soporte de *pepper* (`argon2id hash ctx`), derivación de chaves (`argon2id derive key`) e detección de actualización de parámetros (`argon2id needs rehash`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`argon2id`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/argon2id.rg` (dominio `CRYPTO`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/argon2id.rglib` | Distribución e importación directa con `import argon2id` |
| **Ficheiro compilado** | `target/argon2id.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libargon2id.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import argon2id` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `argon2id`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `argon2id hash / argon2id verify` | Hashing PHC RFC 9106 de 6 argumentos (`pwd, salt, m_kib, t, p, tag_len`) e verificación en tempo constante |
| `argon2id hash with preset / argon2id params preset` | Perfís con nome: `"interactive"`, `"owaspfirst"` (`19456 KiB, t=2`), `"owaspsecond"` (`47104 KiB, t=1`), `"moderate"`, `"sensitive"` |
| `argon2id hash ctx / argon2id verify ctx` | Hashing RFC 9106 con segredo `pepper` ($K$) e datos asociados ($X$) |
| `argon2id derive key / argon2id needs rehash` | Derivación de chave binaria crúa e detección de necesidade de rehash en cadeas PHC |
| `blake2b / blake2b hex` | Resumo criptográfico de propósito xeral RFC 7693 Blake2b (`1..64` bytes) |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `argon2id`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import argon2id

fn :: proteger clave usuario (clave : String) => (String, Bool, Bool)
      proteger clave usuario clave =
        phc    = argon2id hash clave "sal-unica-16byte" 32 2 1 32
        valido = argon2id verify clave phc
        rehash = argon2id needs rehash phc 19456 2 1 32
        (phc, valido, rehash)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `argon2id` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import argon2id

fn :: derivar clave maestra (frase : String) (sal : String) => String
      derivar clave maestra frase sal =
        -- Deriva 32 bytes crudos listos para ChaCha20-Poly1305 AEAD
        argon2id derive key frase sal 64 2 1 32
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Coincidencia byte a byte cos vectores oficiais RFC 9106 §5.3 e OpenSSL 3.5, operando sobre `Tensor[U64 * 8 * 16]` sen unha soa liña de C.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_argon2id.rg`.
