# Capítulo 13: A lib `diff` — Algoritmo LCS, Distancia de Edición, Unified Diff e Parches

## 1. Por que existe a lib `diff`?

Sexamos sinceros: cando un test falla ou un ficheiro de configuración muda, un seco `"expected A, got B"` de 200 liñas obrígache a deixarte as pestanas buscando que liña exacta mudou.

A lib **`diff`** calcula a **Subsecuencia Común Máis Longa (LCS)** sobre `Tensor[Int]` 2D para producir edicións mínimas (`DiffKeep`, `DiffAdd`, `DiffDel`), distancia de edición, estatísticas, formato **Unified Diff** (`---`/`+++`/`@@`) e reconstrución exacta con `diff apply`.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`diff`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/diff.rg` (dominio `DIFF`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/diff.rglib` | Distribución e importación directa con `import diff` |
| **Ficheiro compilado** | `target/diff.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libdiff.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import diff` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `diff`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Calcula o guión mínimo de edición LCS entre listas `[String]` ou textos multiliña |
| `diff edit distance / diff stats` | Distancia mínima de inserción+borrado e reconto `(kept, added, deleted)` |
| `diff format / diff unified` | Formatea liñas compactas `+ / - /  ` ou Unified Diff estándar con cabeceiras |
| `diff apply / diff apply text` | Reconstrúe o documento destino sen perdas a partir do guión de edición |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `diff`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `diff` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Identidade matemática garantida $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ e reconstrución sen perdas `diff apply (diff lines a b) == b`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_diff.rg`.
