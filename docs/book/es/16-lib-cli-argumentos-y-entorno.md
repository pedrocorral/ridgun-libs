# Capítulo 16: La lib `cli` — Banderas, Opciones, Barrera `--`, Subcomandos y Variables de Entorno

## 1. ¿Por qué existe la lib `cli`?

Seamos sinceros: analizar `argv` a mano siempre empieza con un bucle inocente y termina rompiéndose cuando alguien pasa `-la` agrupado, `--port=9090` con signo igual o `--` seguido de un archivo que empieza por guion `-archivo.rg`.

La lib **`cli`** resuelve banderas largas (`--verbose`), cortas (`-v`), agrupadas (`-la`), opciones con valor (`--port=8080`, `--port 8080`, `-p 8080`), el separador POSIX `--`, argumentos posicionales, subcomandos y lectura tipada de variables de entorno (`env get int or`, `env get bool or`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`cli`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/cli.rg` (dominio `CLI`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/cli.rglib` | Distribución e importación directa con `import cli` |
| **Archivo compilado** | `target/cli.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libcli.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import cli` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `cli`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Detecta `--long`, `-s` o banderas agrupadas `-xyz` antes de `--` |
| `cli get opt / cli get int opt` | Extrae opción de texto o entera (`--k=v`, `--k v`, `-k v`) con valor por defecto |
| `cli positionals / cli subcommand` | Recoge los argumentos posicionales (incluyendo todo lo que sigue a `--`) |
| `env get or / env get int or / env get bool or` | Lee variables de entorno con conversión tipada y valores de respaldo |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `cli`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

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

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `cli` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno () => (Int, Bool)
      leer config entorno =
        workers = env get int or "SOLSTICE_WORKERS" 4
        debug   = env get bool or "SOLSTICE_DEBUG" False
        (workers, debug)
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Respeto estricto del separador POSIX `--`: ningún argumento situado a la derecha de `--` se interpreta jamás como bandera.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_cli.rg`.
