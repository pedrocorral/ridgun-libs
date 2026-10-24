# Capítulo 17: La lib `path` — Normalización POSIX (`path clean`) y Confinamiento contra Path Traversal

## 1. ¿Por qué existe la lib `path`?

Seamos sinceros: unir rutas con `base + "/" + archivo` sin limpiar segmentos `..` ni validar prefijos es como dejar la puerta abierta para que alguien pida `../../etc/passwd` en tu servidor web.

La lib **`path`** implementa normalización léxica POSIX (`path clean` al estilo `filepath.Clean` de Go), unión segura (`path join`), descomposición (`dirname`, `basename`, `stem`, `ext`, `replace ext`) y el predicado de seguridad **`path is safe subpath`** (`VUL-INJ-001`) contra escapes de directorio.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`path`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/path.rg` (dominio `PATH`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/path.rglib` | Distribución e importación directa con `import path` |
| **Archivo compilado** | `target/path.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libpath.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import path` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `path`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `path clean / path join / path join list` | Colapsa `//`, `.` y `..` léxicamente y une segmentos de ruta |
| `path dirname / path basename / path split` | Divide una ruta en directorio padre y nombre de archivo final |
| `path ext / path stem / path replace ext` | Extrae o cambia la extensión (tratando `.bashrc` como raíz `.bashrc` y ext `""`) |
| `path is safe subpath : String -> String -> Bool` | Verifica que `rel` permanezca estrictamente dentro de `base_dir` y sin bytes NUL |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `path`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import path

fn :: resolver archivo estatico (raiz : String) (peticion : String) => (Bool, String)
      resolver archivo estatico raiz peticion =
        seguro = path is safe subpath raiz peticion
        ruta   = path join raiz peticion
        (seguro, ruta)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `path` es componible con el resto de las 32 libs de `ridgun-libs`:

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

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: `path is safe subpath` rechaza rutas absolutas, bytes NUL y cualquier secuencia `..` que intente escapar del directorio raíz o de un prefijo hermano (`/srv/www-secret`).
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_path.rg`.
