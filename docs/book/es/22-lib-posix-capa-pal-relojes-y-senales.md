# Capítulo 22: La lib `posix` — Capa de Abstracción de Plataforma (PAL), Relojes, Señales y CSPRNG

## 1. ¿Por qué existe la lib `posix`?

Seamos sinceros: las banderas como `O_CREAT`, `O_NONBLOCK` o los números de syscall cambian entre Linux, macOS y arquitecturas (`X86_64` vs `Arm64`), y en C todo se resuelve con una jungla ilegible de `#ifdef`.

La lib **`posix`** implementa la **Capa de Abstracción de Plataforma (PAL)** de 2 niveles de Ridgun usando guardas tabulares sobre `sys os` (`Linux | MacOS | Windows`) y `sys arch` (`X86_64 | Arm64 | RiscV64`), además de sondeo de descriptores (`wait fd` / `PollStatus`), relojes monótonos y de pared (`RGF-017`), señales (`RGF-018`) y entropía CSPRNG del kernel (`sys random bytes`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`posix`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/posix.rg` (dominio `POSIX`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/posix.rglib` | Distribución e importación directa con `import posix` |
| **Archivo compilado** | `target/posix.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libposix.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import posix` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `posix`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Traducción de banderas del SO según `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Sondea un descriptor devolviendo `PollReady`, `PollTimeout` o `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Relojes monótonos y reloj de pared UTC en milisegundos (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Sondeo no bloqueante de señales (`SIGINT`, `SIGTERM`) y bytes CSPRNG del kernel |
| `read text / write text / file exists / run cmd` | E/S de archivos de alto nivel, directorios y ejecución de subprocesos |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `posix`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import posix

fn :: medir operacion () => (Int, Int)
      medir operacion =
        t0  = clock monotonic ms
        rnd = len (sys random bytes 32)
        t1  = clock monotonic ms
        (rnd, t1 - t0)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `posix` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura (fd : Int) => Bool
      esperar lectura fd =
        est = wait fd fd poll_in 100
        est == PollReady
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Las ramas de `sys os` y `sys arch` que no corresponden al binario destino son eliminadas en tiempo de compilación (Dead-Code Elimination) por `ridgunc`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_posix.rg`.
