# Capítulo 00: Por que preciso `ridgun-libs`? 32 libs sen unha liña de C? Cóntame máis!

Sexamos sinceros: cando descobres que unha linguaxe compila a un binario ELF nativo minúsculo e sen colector de lixo, a segunda pregunta que te fas —con toda a razón do mundo— é:

> *"Vale, a linguaxe mola moito... pero cando teña que abrir un socket TCP, calcular un hash Argon2id, analizar un JSON, resolver un sistema lineal con tensores ou montar un pool de actores, vou ter que enlazar `libc`, `OpenSSL`, `libcurl` e `pcre2`, ou descargar 800 paquetes de terceiros mantidos por un descoñecido?"*

É unha pregunta excelente. E a resposta curta é: **non**. Para iso existe **`ridgun-libs`**: unha suite de **32 libs fundamentais** escritas ao **100 % en Ridgun puro (`v0.9.16`)**, con **cero dependencias en C** e **cero `libc`**.

Poñámoslle nome ás catro dores diarias que `ridgun-libs` elimina de raíz.

---

## Dor n.º 1: "O inferno de `libc`, OpenSSL e o enlazado cruzado"

Seguro que xa viviches este pesadelo:

1. Escribes un servidor ou unha ferramenta CLI supostamente "estática" ou "portable".
2. En canto precisas criptografía (`SHA-256`, `Argon2id`, `ChaCha20-Poly1305`), rede (`DNS`, `HTTP`, `WebSockets`) ou expresións regulares, o teu programa acaba dependendo de `glibc 2.38`, `libssl.so.3` e tres cabeceiras de C.
3. Intentas copiar o binario a un contedor mínimo ou a outra distribución Linux e estoura ao arrincar co infame `version 'GLIBC_2.38' not found`.

**Que muda con `ridgun-libs`?**
Cada unha das 32 libs deste repositorio está escrita integramente en Ridgun tabular e fala directamente co núcleo do sistema operativo mediante a capa PAL (`posix`) ou executa algoritmos puros en memoria determinista (`RMM1`/`RMM2`). Compílanse tanto a paquetes portables (`.rglib` / `.rgc`) como a obxectos compartidos ELF64 nativos (`lib*.so`). Sen `libc`, sen FFI fráxil e sen sorpresas ao despregar.

---

## Dor n.º 2: "A síndrome do `node_modules` / `Cargo.lock` de 400 dependencias"

En moitos ecosistemas modernos, a biblioteca estándar é tan esquelética que para ler un ficheiro `.ini`, validar un `UUIDv7`, aplicar un parche Unified Diff ou renderizar un modelo HTML seguro precisas instalar media ducia de paquetes externos.

En **`ridgun-libs`**, as **32 libs** seguen unha única filosofía de deseño:

```ridgun
import crypto
import json
import http

fn :: autenticar y pedir (token : String) => String
      autenticar y pedir token =
        -- Todas as libs comparten tipos puros, aliñamento tabular e semántica determinista
        mac_hex = sha256 hex token
        cuerpo  = json stringify (JnObj [("token_sha256", JnStr mac_hex)])
        pet     = http build request "POST" "/v1/sesion" [("Content-Type", "application/json")] cuerpo
        pet
```

Mesma estética tabular, mesmos ADTs inmutables (`Option`, `Result`, `IoResult`, `JsonVal`), cero efectos laterais ocultos.

---

## Dor n.º 3: "Expresións regulares que colgan a CPU (ReDoS) e sockets que bloquean para sempre"

Dúas bombas de reloxaría clásicas en produción:

- Un usuario malicioso envía unha cadea deseñada para que o teu motor de expresións regulares con *backtracking* entre en tempo exponencial $O(2^N)$ e deixe frito un núcleo ao 100 %.
- Un descritor de rede queda medio aberto e o teu fío queda bloqueado eternamente agardando un `read()` sen data límite.

En **`ridgun-libs`**:
- A lib **`regex`** (Capítulo 11) implementa un autómata **NFA de Thompson** que garante tempo lineal estrito **$O(N \cdot M)$**: inmune por construción a ataques ReDoS.
- As libs **`posix`**, **`io`** e **`socket`** (Capítulos 22, 23 e 27) integran cotas léxicas `with timeout` e `ppoll` a nivel de descritor: ningunha operación de entrada/saída pode colgar o teu servizo.

---

## Dor n.º 4: "Criptografía e álxebra lineal que parecen xeroglíficos"

En **`ridgun-libs`**, a potencia dos tipos `Tensor[...]` de Ridgun permite que libs coma **`tensor`** (Capítulo 05), **`linalg`** (Capítulo 06) e **`argon2id`** (Capítulo 25) operen sobre bloques de memoria contigua (`Tensor[U64 * 8 * 16]`, `Tensor[Real]`) mantendo a lexibilidade dunha táboa matemática.

---

## Mapa completo do libro: 32 capítulos para 32 libs

Cada capítulo deste libro está dedicado a **unha lib** de `ridgun-libs`, agrupadas nunha progresión lóxica de abaixo cara arriba:

| Capítulos | Familia de libs | Libs incluídas |
|---|---|---|
| **01 – 04** | Texto, Matemáticas e Estruturas de Datos | `str`, `math`, `list`, `btree` |
| **05 – 06** | Tensores e Álxebra Lineal | `tensor`, `linalg` |
| **07 – 10** | Codificación e Formatos de Datos | `codec`, `json`, `csv`, `ini` |
| **11 – 15** | Motores de Texto, Diffs, Modelos e Formatado | `regex`, `glob`, `diff`, `template`, `fmt` |
| **16 – 21** | CLI, Rutas, Tempo, UUIDs, Logs e Testing | `cli`, `path`, `time`, `uuid`, `log`, `test` |
| **22 – 23** | Sistemas POSIX e E/S con Timeout | `posix`, `io` |
| **24 – 26** | Criptografía, Argon2id e Tokens JWT | `crypto`, `argon2id`, `jwt` |
| **27 – 29** | Redes, Sockets do Kernel, HTTP/1.1 e WebSockets | `socket`, `http`, `ws` |
| **30 – 32** | Concorrencia de Actores, Pools e Supervisión de Rede | `agent`, `pool`, `net_agent` |

Imos aló! Pasa ao **Capítulo 01 (`str`)** e comecemos a construír.
