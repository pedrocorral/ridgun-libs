# Capítol 12: La lib `glob` — Patrons de Comodins (`*`, `?`, `[a-z]`) i Filtratge de Llistes

## 1. Per què existeix la lib `glob`?

Siguem sincers: fer servir una expressió regular completa només per comprovar si un fitxer acaba en `*.rg` o comença per `test_[0-9]*.rg` és matar mosques a canonades.

La lib **`glob`** implementa coincidència exacta de comodins de shell (`*`, `?`, classes `[a-z]`, classes negades `[!0-9]` / `[^a-z]`), variants insensibles a majúscules (`glob match ci`) i filtratge directe de llistes de rutes o noms.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`glob`** és una **lib** de primera classe situada a `src/main/ridgun/lib/glob.rg` (domini `GLOB`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/glob.rglib` | Distribució i importació directa amb `import glob` |
| **Fitxer compilat** | `target/glob.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libglob.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import glob` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `glob`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `glob match / glob match ci` | Coincidència de patrons glob sensible i insensible a majúscules ASCII |
| `glob filter / glob any match` | Filtra `[String]` segons un patró o comprova si coincideix algun patró d'una llista |
| `glob has magic` | Detecta si una cadena conté metacaràcters de comodí (`*`, `?`, `[`) |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `glob`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import glob

fn :: seleccionar fuentes ridgun (archivos : [String]) => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `glob` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida (ruta : String) => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Col·lapse automàtic d'estrelles consecutives (`***` $\rightarrow$ `*`) per evitar retrocessos redundants i maneig segur de claudàtors sense tancar `[`.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_glob.rg`.
