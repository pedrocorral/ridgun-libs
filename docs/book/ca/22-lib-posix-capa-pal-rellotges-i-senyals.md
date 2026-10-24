# Capítol 22: La lib `posix` — Capa d'Abstracció de Plataforma (PAL), Rellotges, Senyals i CSPRNG

## 1. Per què existeix la lib `posix`?

Siguem sincers: les banderes com `O_CREAT`, `O_NONBLOCK` o els números de syscall canvien entre Linux, macOS i arquitectures (`X86_64` vs `Arm64`), i en C tot es resol amb una jungla il·legible d'`#ifdef`.

La lib **`posix`** implementa la **Capa d'Abstracció de Plataforma (PAL)** de 2 nivells de Ridgun fent servir guardes tabulars sobre `sys os` (`Linux | MacOS | Windows`) i `sys arch` (`X86_64 | Arm64 | RiscV64`), a més de sondeig de descriptors (`wait fd` / `PollStatus`), rellotges monòtons i de paret (`RGF-017`), senyals (`RGF-018`) i entropia CSPRNG del nucli (`sys random bytes`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`posix`** és una **lib** de primera classe situada a `src/main/ridgun/lib/posix.rg` (domini `POSIX`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/posix.rglib` | Distribució i importació directa amb `import posix` |
| **Fitxer compilat** | `target/posix.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libposix.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import posix` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `posix`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Traducció de banderes del SO segons `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Sondeja un descriptor retornant `PollReady`, `PollTimeout` o `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Rellotges monòtons i rellotge de paret UTC en mil·lisegons (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Sondeig no bloquejant de senyals (`SIGINT`, `SIGTERM`) i bytes CSPRNG del nucli |
| `read text / write text / file exists / run cmd` | E/S de fitxers d'alt nivell, directoris i execució de subprocessos |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `posix`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import posix

fn :: medir operacion () => (Int, Int)
      medir operacion =
        t0  = clock monotonic ms
        rnd = len (sys random bytes 32)
        t1  = clock monotonic ms
        (rnd, t1 - t0)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `posix` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura (fd : Int) => Bool
      esperar lectura fd =
        est = wait fd fd poll_in 100
        est == PollReady
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Les branques de `sys os` i `sys arch` que no corresponen al binari destí són eliminades en temps de compilació (Dead-Code Elimination) per `ridgunc`.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_posix.rg`.
