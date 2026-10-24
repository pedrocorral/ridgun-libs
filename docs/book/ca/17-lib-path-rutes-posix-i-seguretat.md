# Capítol 17: La lib `path` — Normalització POSIX (`path clean`) i Confinament contra Path Traversal

## 1. Per què existeix la lib `path`?

Siguem sincers: unir rutes amb `base + "/" + fitxer` sense netejar segments `..` ni validar prefixos és com deixar la porta oberta perquè algú demani `../../etc/passwd` al teu servidor web.

La lib **`path`** implementa normalització lèxica POSIX (`path clean` a l'estil `filepath.Clean` de Go), unió segura (`path join`), descomposició (`dirname`, `basename`, `stem`, `ext`, `replace ext`) i el predicat de seguretat **`path is safe subpath`** (`VUL-INJ-001`) contra escapaments de directori.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`path`** és una **lib** de primera classe situada a `src/main/ridgun/lib/path.rg` (domini `PATH`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/path.rglib` | Distribució i importació directa amb `import path` |
| **Fitxer compilat** | `target/path.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libpath.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import path` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `path`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `path clean / path join / path join list` | Col·lapsa `//`, `.` i `..` lèxicament i uneix segments de ruta |
| `path dirname / path basename / path split` | Divideix una ruta en directori pare i nom de fitxer final |
| `path ext / path stem / path replace ext` | Extreu o canvia l'extensió (tractant `.bashrc` com a arrel `.bashrc` i ext `""`) |
| `path is safe subpath : String -> String -> Bool` | Verifica que `rel` romangui estrictament dins de `base_dir` i sense bytes NUL |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `path`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import path

fn :: resolver archivo estatico (raiz : String) (peticion : String) => (Bool, String)
      resolver archivo estatico raiz peticion =
        seguro = path is safe subpath raiz peticion
        ruta   = path join raiz peticion
        (seguro, ruta)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `path` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import path

fn :: cambiar salida a objeto (fuente : String) => (String, String, String)
      cambiar salida a objeto fuente =
        dir = path dirname fuente
        nom = path stem fuente
        obj = path replace ext (path clean fuente) ".rglib"
        (dir, nom, obj)
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: `path is safe subpath` rebutja rutes absolutes, bytes NUL i qualsevol seqüència `..` que intenti escapar del directori arrel o d'un prefix germà (`/srv/www-secret`).
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_path.rg`.
