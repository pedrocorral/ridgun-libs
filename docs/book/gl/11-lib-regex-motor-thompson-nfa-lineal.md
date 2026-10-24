# Capítulo 11: A lib `regex` — Motor de Expresións Regulares Thompson NFA en Tempo Lineal $O(N \cdot M)$

## 1. Por que existe a lib `regex`?

Sexamos sinceros: os motores de expresións regulares con *backtracking* teñen causado caídas globais famosas (coma en Cloudflare ou StackOverflow) cando un padrón coma `(a+)+b` recibe trinta `a` seguidas e entra en tempo exponencial $O(2^N)$.

A lib **`regex`** compila as túas expresións regulares (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) a un **autómata finito non determinista de Thompson (NFA)** e avanza o conxunto de estados paso a paso en tempo estritamente lineal **$O(N \cdot M)$**, facendo que os ataques **ReDoS sexan matematicamente imposibles**.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`regex`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/regex.rg` (dominio `REGEX`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/regex.rglib` | Distribución e importación directa con `import regex` |
| **Ficheiro compilado** | `target/regex.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libregex.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import regex` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `regex`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `regex match / regex is match` | Coincidencia de cadea completa e busca de subcadea en tempo lineal $O(N \cdot M)$ |
| `regex find / regex find all` | Extrae a primeira ou todas as subcadeas coincidentes sen solapamento |
| `regex replace / regex replace all` | Substitúe a primeira ou todas as coincidencias da expresión regular |
| `regex split / regex escape` | Divide texto segundo un delimitador regex e escapa metacaracteres |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `regex`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import regex

fn :: extraer codigos postales (texto : String) => [String]
      extraer codigos postales texto =
        regex find all "\\d+" texto
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `regex` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos (comentario : String) => (Bool, String)
      censurar telefonos comentario =
        tiene = regex is match "\\d+-\\d+" comentario
        limpio = regex replace all "\\d+-\\d+" comentario "[TELEFONO]"
        (tiene, limpio)
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Simulación de conxunto de estados NFA sen recursión descontrolada de pila e tempo $O(N \cdot M)$ garantido mesmo ante padróns patolóxicos `(a+)+b`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_regex.rg`.
