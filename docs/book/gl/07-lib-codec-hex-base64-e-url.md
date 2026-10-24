# Capítulo 07: A lib `codec` — Hex, Base64, Base64url, URL Percent-Encoding e JSON Lixeiro

## 1. Por que existe a lib `codec`?

Sexamos sinceros: nada rompe máis rápido unha integración web ca confundir Base64 estándar (`+/=`) con Base64url (`-_` sen recheo) nun token JWT, ou construír unha query string concatenando cadeas sen escapar.

A lib **`codec`** implementa os estándares **RFC 4648** (Hex, Base64 e Base64url), **RFC 3986** (codificación porcentual de URLs e dicionarios `query encode` / `query decode`) e construtores/extractores rápidos de **JSON lixeiro (RFC 8259)**.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`codec`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/codec.rg` (dominio `CODEC`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/codec.rglib` | Distribución e importación directa con `import codec` |
| **Ficheiro compilado** | `target/codec.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libcodec.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import codec` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `codec`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `hex encode / hex decode / hex is valid` | Codificación hexadecimal RFC 4648 en minúsculas e descodificación validada |
| `base64 encode / base64 decode` | Base64 estándar RFC 4648 §4 con recheo `=` |
| `base64url encode / base64url decode` | Base64url seguro para URLs RFC 4648 §5 (`-`, `_`, sen recheo) |
| `url encode / url decode / query encode / query decode` | Codificación porcentual RFC 3986 e dicionarios de query string `k=v&...` |
| `json quote / json object / json get str / json get int` | Serialización JSON rápida sen AST e extracción de chaves de primeiro nivel |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `codec`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import codec

fn :: empaquetar parametros (usuario : String) (redir : String) => String
      empaquetar parametros usuario redir =
        token_b64 = base64url encode usuario
        query encode [("token", token_b64), ("next", redir)]
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `codec` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import codec

fn :: construir respuesta rapida (id : Int) (nombre : String) => (String, Int)
      construir respuesta rapida id nombre =
        doc = json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)]
        leido = json get int doc "id" 0
        (doc, leido)
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Rexeitamento determinista de entradas hexadecimais ou Base64 mal formadas (devolvendo `""` sen lecturas fóra de límites) e reversibilidade exacta $decode(encode(x)) == x$.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_codec.rg`.
