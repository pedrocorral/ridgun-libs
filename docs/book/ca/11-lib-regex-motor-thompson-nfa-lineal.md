# Capítol 11: La lib `regex` — Motor d'Expressions Regulars Thompson NFA en Temps Lineal $O(N \cdot M)$

## 1. Per què existeix la lib `regex`?

Siguem sincers: els motors d'expressions regulars amb *backtracking* han causat caigudes globals famoses (com a Cloudflare o StackOverflow) quan un patró com `(a+)+b` rep trenta `a` seguides i entra en temps exponencial $O(2^N)$.

La lib **`regex`** compila les teves expressions regulars (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) a un **autòmat finit no determinista de Thompson (NFA)** i avança el conjunt d'estats pas a pas en temps estrictament lineal **$O(N \cdot M)$**, fent que els atacs **ReDoS siguin matemàticament impossibles**.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`regex`** és una **lib** de primera classe situada a `src/main/ridgun/lib/regex.rg` (domini `REGEX`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/regex.rglib` | Distribució i importació directa amb `import regex` |
| **Fitxer compilat** | `target/regex.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libregex.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import regex` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `regex`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `regex match / regex is match` | Coincidència de cadena completa i cerca de subcadena en temps lineal $O(N \cdot M)$ |
| `regex find / regex find all` | Extreu la primera o totes les subcadenes coincidents sense solapament |
| `regex replace / regex replace all` | Reemplaça la primera o totes les coincidències de l'expressió regular |
| `regex split / regex escape` | Divideix text segons un delimitador regex i escapa metacaràcters |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `regex`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import regex

fn :: extraer codigos postales (texto : String) => [String]
      extraer codigos postales texto =
        regex find all "\\d+" texto
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `regex` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos (comentario : String) => (Bool, String)
      censurar telefonos comentario =
        tiene = regex is match "\\d+-\\d+" comentario
        limpio = regex replace all "\\d+-\\d+" comentario "[TELEFONO]"
        (tiene, limpio)
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Simulació de conjunt d'estats NFA sense recursió descontrolada de pila i temps $O(N \cdot M)$ garantit fins i tot davant patrons patològics `(a+)+b`.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_regex.rg`.
