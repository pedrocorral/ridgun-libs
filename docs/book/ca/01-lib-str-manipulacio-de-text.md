# Capítol 01: La lib `str` — Manipulació de Text, Cerca i Format Tabular

## 1. Per què existeix la lib `str`?

Siguem sincers: en C manipular cadenes amb `strtok` i `strncpy` és caminar per un camp de mines de desbordaments de memòria i punters `NULL`, i en altres llenguatges acabes important tres paquets només per alinear columnes o repetir un separador en $O(\log N)$.

La lib **`str`** proporciona totes les primitives pures i immutables per cercar, retallar, dividir, unir, canviar majúscules/minúscules, repetir per duplicació binària $O(\log N)$ i emplenar cadenes.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`str`** és una **lib** de primera classe situada a `src/main/ridgun/lib/str.rg` (domini `STR`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/str.rglib` | Distribució i importació directa amb `import str` |
| **Fitxer compilat** | `target/str.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libstr.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import str` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `str`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `str index of : String -> String -> Int` | Primer índex de la subcadena (`-1` si no existeix / `0` si és buida) |
| `str contains / str starts with / str ends with` | Predicats `Bool` de subcadena, prefix i sufix |
| `str trim / str trim left / str trim right` | Elimina espais en blanc ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | Divideix en `[String]` i uneix llistes amb un separador |
| `str replace / str to upper / str to lower` | Reemplaçament sense solapament i conversió ASCII de majúscules/minúscules |
| `str repeat / str pad left / str pad right` | Repetició en $O(\log N)$ i farciment de columnes a amplada fixa |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `str`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import str

fn :: normalizar cabecera (raw : String) => String
      normalizar cabecera raw =
        limpia = str to lower (str trim raw)
        partes = str words limpia
        slug   = str join partes "-"
        str pad right slug 24 "."
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `str` és componible amb la resta de les 32 libs de `ridgun-libs`:

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

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Repetició en $O(\log N)$ mitjançant duplicació de cadenes, predicats segurs davant agulles buides i zero mutació al lloc.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_str.rg`.
