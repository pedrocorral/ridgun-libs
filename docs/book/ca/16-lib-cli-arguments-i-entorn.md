# Capítol 16: La lib `cli` — Banderes, Opcions, Barrera `--`, Subcomandes i Variables d'Entorn

## 1. Per què existeix la lib `cli`?

Siguem sincers: analitzar `argv` a mà sempre comença amb un bucle innocent i acaba trencant-se quan algú passa `-la` agrupat, `--port=9090` amb signe igual o `--` seguit d'un fitxer que comença per guió `-fitxer.rg`.

La lib **`cli`** resol banderes llargues (`--verbose`), curtes (`-v`), agrupades (`-la`), opcions amb valor (`--port=8080`, `--port 8080`, `-p 8080`), el separador POSIX `--`, arguments posicionals, subcomandes i lectura tipada de variables d'entorn (`env get int or`, `env get bool or`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`cli`** és una **lib** de primera classe situada a `src/main/ridgun/lib/cli.rg` (domini `CLI`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/cli.rglib` | Distribució i importació directa amb `import cli` |
| **Fitxer compilat** | `target/cli.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libcli.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import cli` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `cli`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Detecta `--long`, `-s` o banderes agrupades `-xyz` abans de `--` |
| `cli get opt / cli get int opt` | Extreu opció de text o entera (`--k=v`, `--k v`, `-k v`) amb valor per defecte |
| `cli positionals / cli subcommand` | Recull els arguments posicionals (incloent-hi tot el que segueix a `--`) |
| `env get or / env get int or / env get bool or` | Llegeix variables d'entorn amb conversió tipada i valors de suport |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `cli`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import cli

fn :: analizar comando (args : [String]) => (String, Bool, Int, [String])
      analizar comando args =
        sub   = cli subcommand args
        all_f = cli has flag args "--all" "-a"
        port  = cli get int opt args "--port" "-p" 8080
        arch  = cli positionals args ["--port", "-p"]
        (sub, all_f, port, arch)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `cli` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno () => (Int, Bool)
      leer config entorno =
        workers = env get int or "SOLSTICE_WORKERS" 4
        debug   = env get bool or "SOLSTICE_DEBUG" False
        (workers, debug)
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Respecte estricte del separador POSIX `--`: cap argument situat a la dreta de `--` s'interpreta mai com a bandera.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_cli.rg`.
