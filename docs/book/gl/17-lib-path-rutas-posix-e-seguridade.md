# Capítulo 17: A lib `path` — Normalización POSIX (`path clean`) e Confinamento contra Path Traversal

## 1. Por que existe a lib `path`?

Sexamos sinceros: unir rutas con `base + "/" + ficheiro` sen limpar segmentos `..` nin validar prefixos é coma deixar a porta aberta para que alguén pida `../../etc/passwd` no teu servidor web.

A lib **`path`** implementa normalización léxica POSIX (`path clean` ao estilo `filepath.Clean` de Go), unión segura (`path join`), descomposición (`dirname`, `basename`, `stem`, `ext`, `replace ext`) e o predicado de seguridade **`path is safe subpath`** (`VUL-INJ-001`) contra escapes de directorio.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`path`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/path.rg` (dominio `PATH`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/path.rglib` | Distribución e importación directa con `import path` |
| **Ficheiro compilado** | `target/path.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libpath.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import path` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `path`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `path clean / path join / path join list` | Colapsa `//`, `.` e `..` lexicamente e une segmentos de ruta |
| `path dirname / path basename / path split` | Divide unha ruta en directorio pai e nome de ficheiro final |
| `path ext / path stem / path replace ext` | Extrae ou cambia a extensión (tratando `.bashrc` como raíz `.bashrc` e ext `""`) |
| `path is safe subpath : String -> String -> Bool` | Verifica que `rel` permaneza estritamente dentro de `base_dir` e sen bytes NUL |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `path`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import path

fn :: resolver archivo estatico (raiz : String) (peticion : String) => (Bool, String)
      resolver archivo estatico raiz peticion =
        seguro = path is safe subpath raiz peticion
        ruta   = path join raiz peticion
        (seguro, ruta)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `path` é compoñible co resto das 32 libs de `ridgun-libs`:

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

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: `path is safe subpath` rexeita rutas absolutas, bytes NUL e calquera secuencia `..` que intente escapar do directorio raíz ou dun prefixo irmán (`/srv/www-secret`).
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_path.rg`.
