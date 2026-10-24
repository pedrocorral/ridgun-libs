# Capítulo 01: A lib `str` — Manipulación de Texto, Busca e Formato Tabular

## 1. Por que existe a lib `str`?

Sexamos sinceros: en C manipular cadeas con `strtok` e `strncpy` é camiñar por un campo de minas de desbordamentos de búfer e punteiros `NULL`, e noutras linguaxes acabas importando tres paquetes só para aliñar columnas ou repetir un separador en $O(\log N)$.

A lib **`str`** proporciona todas as primitivas puras e inmutables para buscar, recortar, dividir, unir, cambiar maiúsculas/minúsculas, repetir por duplicación binaria $O(\log N)$ e encher cadeas.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`str`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/str.rg` (dominio `STR`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/str.rglib` | Distribución e importación directa con `import str` |
| **Ficheiro compilado** | `target/str.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libstr.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import str` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `str`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `str index of : String -> String -> Int` | Primeiro índice da subcadea (`-1` se non existe / `0` se é baleira) |
| `str contains / str starts with / str ends with` | Predicados `Bool` de subcadea, prefixo e sufixo |
| `str trim / str trim left / str trim right` | Elimina espazos en branco ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | Divide en `[String]` e une listas cun separador |
| `str replace / str to upper / str to lower` | Substitución sen solapamento e conversión ASCII de maiúsculas/minúsculas |
| `str repeat / str pad left / str pad right` | Repetición en $O(\log N)$ e recheo de columnas a ancho fixo |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `str`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import str

fn :: normalizar cabecera (raw : String) => String
      normalizar cabecera raw =
        limpia = str to lower (str trim raw)
        partes = str words limpia
        slug   = str join partes "-"
        str pad right slug 24 "."
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `str` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import str

fn :: extraer dominio (correo : String) => String
      extraer dominio correo =
        pos = str index of correo "@"
        | pos < 0   = "sin-dominio"
        | otherwise =
          partes = str split correo "@"
          str replace (str to lower correo) "@" " en "
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Repetición en $O(\log N)$ mediante duplicación de cadeas, predicados seguros ante agullas baleiras e cero mutación no lugar.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_str.rg`.
