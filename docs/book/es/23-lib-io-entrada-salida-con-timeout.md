# Capítulo 23: La lib `io` — Errores Tipados `IoResult`, E/S con `with timeout` y Procesos

## 1. ¿Por qué existe la lib `io`?

Seamos sinceros: una llamada a `read()` o un subproceso hijo sin fecha límite (`timeout`) es una invitación a que un solo recurso colgado agote todos los trabajadores de tu servidor.

La lib **`io`** modela cada operación del sistema con ADTs explícitos (`IoError`, `IoResult[A]`), combina `ppoll` no bloqueante con cuotas léxicas `with timeout wait_ms do` de Ridgun y ofrece los operadores mixfix `read fd ... timeout` y `write fd ... timeout`.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`io`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/io.rg` (dominio `IO`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/io.rglib` | Distribución e importación directa con `import io` |
| **Archivo compilado** | `target/io.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libio.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import io` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `io`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Lectura/escritura no bloqueante de descriptor acotada por `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Operadores mixfix ergonómicos (`op ::`) para E/S de descriptor con fecha límite |
| `io read file / io write file / io read lines` | Funciones seguras de archivos y flujos de líneas que devuelven `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Ejecuta un comando externo acotado por una cuota léxica `with timeout` |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `io`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import io

fn :: leer peticion segura (fd : Int) => String
      leer peticion segura fd =
        res = read fd fd max 4096 timeout 250
        io unwrap or res ""
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `io` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import io

fn :: describir fallo () => String
      describir fallo =
        format io error (IoTimeout "read" 250)
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Ninguna lectura, escritura o comando ejecutado a través de `io` con cuota `wait_ms` puede bloquear indefinidamente el hilo o actor llamante.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_io.rg`.
