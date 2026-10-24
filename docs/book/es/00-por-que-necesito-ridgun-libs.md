# Capítulo 00: ¿Por qué necesito `ridgun-libs`? ¿32 libs sin una línea de C? ¡Cuéntame más!

Seamos sinceros: cuando descubres que un lenguaje compila a un binario ELF nativo minúsculo y sin recolector de basura, la segunda pregunta que te haces —con toda la razón del mundo— es:

> *"Vale, el lenguaje mola mucho... pero cuando tenga que abrir un socket TCP, calcular un hash Argon2id, parsear un JSON, resolver un sistema lineal con tensores o montar un pool de actores, ¿voy a tener que enlazar `libc`, `OpenSSL`, `libcurl` y `pcre2`, o descargarme 800 paquetes de terceros mantenidos por un desconocido?"*

Es una pregunta excelente. Y la respuesta corta es: **no**. Para eso existe **`ridgun-libs`**: una suite de **32 libs fundamentales** escritas al **100 % en Ridgun puro (`v0.9.16`)**, con **cero dependencias en C** y **cero `libc`**.

Pongámosle nombre a los cuatro dolores diarios que `ridgun-libs` elimina de raíz.

---

## Dolor n.º 1: "El infierno de `libc`, OpenSSL y el enlazado cruzado"

Seguro que has vivido esta pesadilla:

1. Escribes un servidor o una herramienta CLI supuestamente "estática" o "portable".
2. En cuanto necesitas criptografía (`SHA-256`, `Argon2id`, `ChaCha20-Poly1305`), red (`DNS`, `HTTP`, `WebSockets`) o expresiones regulares, tu programa acaba dependiendo de `glibc 2.38`, `libssl.so.3` y tres cabeceras de C.
3. Intentas copiar el binario a un contenedor mínimo o a otra distribución Linux y explota al arrancar con el infame `version 'GLIBC_2.38' not found`.

**¿Qué cambia con `ridgun-libs`?**
Cada una de las 32 libs de este repositorio está escrita íntegramente en Ridgun tabular y habla directamente con el núcleo del sistema operativo mediante la capa PAL (`posix`) o ejecuta algoritmos puros en memoria determinista (`RMM1`/`RMM2`). Se compilan tanto a paquetes portables (`.rglib` / `.rgc`) como a objetos compartidos ELF64 nativos (`lib*.so`). Sin `libc`, sin FFI frágil y sin sorpresas al desplegar.

---

## Dolor n.º 2: "El síndrome del `node_modules` / `Cargo.lock` de 400 dependencias"

En muchos ecosistemas modernos, la biblioteca estándar es tan esquelética que para leer un archivo `.ini`, validar un `UUIDv7`, aplicar un parche Unified Diff o renderizar una plantilla HTML segura necesitas instalar media docena de paquetes externos. Cada paquete trae sus propias convenciones, sus propios tipos de error y su propio riesgo de cadena de suministro.

En **`ridgun-libs`**, las **32 libs** siguen una única filosofía de diseño:

```ridgun
import crypto
import json
import http

fn :: autenticar y pedir (token : String) => String
      autenticar y pedir token =
        -- Todas las libs comparten tipos puros, alineación tabular y semántica determinista
        mac_hex = sha256 hex token
        cuerpo  = json stringify (JnObj [("token_sha256", JnStr mac_hex)])
        pet     = http build request "POST" "/v1/sesion" [("Content-Type", "application/json")] cuerpo
        pet
```

Misma estética tabular, mismos ADTs inmutables (`Option`, `Result`, `IoResult`, `JsonVal`), cero efectos laterales ocultos.

---

## Dolor n.º 3: "Expresiones regulares que cuelgan la CPU (ReDoS) y sockets que bloquean para siempre"

Dos bombas de relojería clásicas en producción:

- Un usuario malicioso envía una cadena diseñada para que tu motor de expresiones regulares con *backtracking* entre en tiempo exponencial $O(2^N)$ y deje frito un núcleo al 100 %.
- Un descriptor de red se queda medio abierto y tu hilo se queda bloqueado eternamente esperando un `read()` sin fecha límite.

En **`ridgun-libs`**:
- La lib **`regex`** (Capítulo 11) implementa un autómata **NFA de Thompson** que garantiza tiempo lineal estricto **$O(N \cdot M)$**: inmune por construcción a ataques ReDoS.
- Las libs **`posix`**, **`io`** y **`socket`** (Capítulos 22, 23 y 27) integran cuotas léxicas `with timeout` y `ppoll` a nivel de descriptor: ninguna operación de entrada/salida puede colgar tu servicio.

---

## Dolor n.º 4: "Criptografía y álgebra lineal que parecen jeroglíficos"

En **`ridgun-libs`**, la potencia de los tipos `Tensor[...]` de Ridgun permite que libs como **`tensor`** (Capítulo 05), **`linalg`** (Capítulo 06) y **`argon2id`** (Capítulo 25) operen sobre bloques de memoria contigua (`Tensor[U64 * 8 * 16]`, `Tensor[Real]`) manteniendo la legibilidad de una tabla matemática.

---

## Mapa completo del libro: 32 capítulos para 32 libs

Cada capítulo de este libro está dedicado a **una lib** de `ridgun-libs`, agrupadas en una progresión lógica de abajo arriba:

| Capítulos | Familia de libs | Libs incluidas |
|---|---|---|
| **01 – 04** | Texto, Matemáticas y Estructuras de Datos | `str`, `math`, `list`, `btree` |
| **05 – 06** | Tensores y Álgebra Lineal | `tensor`, `linalg` |
| **07 – 10** | Codificación y Formatos de Datos | `codec`, `json`, `csv`, `ini` |
| **11 – 15** | Motores de Texto, Diffs, Plantillas y Formateo | `regex`, `glob`, `diff`, `template`, `fmt` |
| **16 – 21** | CLI, Rutas, Tiempo, UUIDs, Logs y Testing | `cli`, `path`, `time`, `uuid`, `log`, `test` |
| **22 – 23** | Sistemas POSIX y E/S con Timeout | `posix`, `io` |
| **24 – 26** | Criptografía, Argon2id y Tokens JWT | `crypto`, `argon2id`, `jwt` |
| **27 – 29** | Redes, Sockets del Kernel, HTTP/1.1 y WebSockets | `socket`, `http`, `ws` |
| **30 – 32** | Concurrencia de Actores, Pools y Supervisión de Red | `agent`, `pool`, `net_agent` |

¡Venga, al turrón! Pasa al **Capítulo 01 (`str`)** y empecemos a construir.
