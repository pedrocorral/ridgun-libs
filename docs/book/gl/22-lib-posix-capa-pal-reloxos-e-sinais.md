# Capítulo 22: A lib `posix` — Capa de Abstracción de Plataforma (PAL), Reloxos, Sinais e CSPRNG

## 1. Por que existe a lib `posix`?

Sexamos sinceros: as bandeiras coma `O_CREAT`, `O_NONBLOCK` ou os números de syscall mudan entre Linux, macOS e arquitecturas (`X86_64` vs `Arm64`), e en C todo se resolve cunha xungla ilexible de `#ifdef`.

A lib **`posix`** implementa a **Capa de Abstracción de Plataforma (PAL)** de 2 niveis de Ridgun usando gardas tabulares sobre `sys os` (`Linux | MacOS | Windows`) e `sys arch` (`X86_64 | Arm64 | RiscV64`), ademais de sondaxe de descritores (`wait fd` / `PollStatus`), reloxos monótonos e de parede (`RGF-017`), sinais (`RGF-018`) e entropía CSPRNG do kernel (`sys random bytes`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`posix`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/posix.rg` (dominio `POSIX`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/posix.rglib` | Distribución e importación directa con `import posix` |
| **Ficheiro compilado** | `target/posix.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libposix.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import posix` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `posix`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Tradución de bandeiras do SO segundo `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Sonda un descritor devolvendo `PollReady`, `PollTimeout` ou `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Reloxos monótonos e reloxo de parede UTC en milisegundos (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Sondaxe non bloqueante de sinais (`SIGINT`, `SIGTERM`) e bytes CSPRNG do kernel |
| `read text / write text / file exists / run cmd` | E/S de ficheiros de alto nivel, directorios e execución de subprocesos |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `posix`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import posix

fn :: medir operacion () => (Int, Int)
      medir operacion =
        t0  = clock monotonic ms
        rnd = len (sys random bytes 32)
        t1  = clock monotonic ms
        (rnd, t1 - t0)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `posix` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura (fd : Int) => Bool
      esperar lectura fd =
        est = wait fd fd poll_in 100
        est == PollReady
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: As ramas de `sys os` e `sys arch` que non corresponden ao binario destino son eliminadas en tempo de compilación (Dead-Code Elimination) por `ridgunc`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_posix.rg`.
