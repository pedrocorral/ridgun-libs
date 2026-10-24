# Capítol 23: La lib `io` — Errors Tipats `IoResult`, E/S amb `with timeout` i Processos

## 1. Per què existeix la lib `io`?

Siguem sincers: una crida a `read()` o un subprocess fill sense data límit (`timeout`) és una invitació perquè un sol recurs penjat esgoti tots els treballadors del teu servidor.

La lib **`io`** modela cada operació del sistema amb ADTs explícits (`IoError`, `IoResult[A]`), combina `ppoll` no bloquejant amb quotes lèxiques `with timeout wait_ms do` de Ridgun i ofereix els operadors mixfix `read fd ... timeout` i `write fd ... timeout`.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`io`** és una **lib** de primera classe situada a `src/main/ridgun/lib/io.rg` (domini `IO`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/io.rglib` | Distribució i importació directa amb `import io` |
| **Fitxer compilat** | `target/io.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libio.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import io` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `io`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Lectura/escriptura no bloquejant de descriptor acotada per `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Operadors mixfix ergonòmics (`op ::`) per a E/S de descriptor amb data límit |
| `io read file / io write file / io read lines` | Funcions segures de fitxers i fluxos de línies que retornen `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Executa una comanda externa acotada per una quota lèxica `with timeout` |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `io`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import io

fn :: leer peticion segura (fd : Int) => String
      leer peticion segura fd =
        res = read fd fd max 4096 timeout 250
        io unwrap or res ""
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `io` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import io

fn :: describir fallo () => String
      describir fallo =
        format io error (IoTimeout "read" 250)
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Cap lectura, escriptura o comanda executada a través d'`io` amb quota `wait_ms` pot bloquejar indefinidament el fil o actor que fa la crida.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_io.rg`.
