# Capítulo 00: Por que preciso do `ridgun-libs`? 32 libs sem uma linha de C? Conte-me mais!

Sejamos sinceros: quando descobre que uma linguagem compila para um binário ELF nativo minúsculo e sem coletor de lixo, a segunda pergunta que faz a si mesmo — com toda a razão do mundo — é:

> *"Muito bem, a linguagem é excelente... mas quando eu precisar de abrir um socket TCP, calcular um hash Argon2id, analisar um JSON, resolver um sistema linear com tensores ou montar um pool de atores, vou ter de ligar `libc`, `OpenSSL`, `libcurl` e `pcre2`, ou descarregar 800 pacotes de terceiros mantidos por desconhecidos?"*

É uma excelente pergunta. E a resposta curta é: **não**. É exatamente para isso que existe o **`ridgun-libs`**: uma suite de **32 libs fundamentais** escritas a **100 % em Ridgun puro (`v0.9.16`)**, com **zero dependências em C** e **zero `libc`**.

Vamos dar nome às quatro dores diárias que o `ridgun-libs` elimina pela raiz.

---

## Dor n.º 1: "O inferno da `libc`, OpenSSL e da ligação cruzada"

De certeza que já viveu este pesadelo:

1. Escreve um servidor ou uma ferramenta CLI supostamente "estática" ou "portátil".
2. Assim que precisa de criptografia (`SHA-256`, `Argon2id`, `ChaCha20-Poly1305`), rede (`DNS`, `HTTP`, `WebSockets`) ou expressões regulares, o seu programa acaba dependente da `glibc 2.38`, `libssl.so.3` e cabeçalhos C.
3. Tenta copiar o binário para um contentor mínimo ou outra distribuição Linux e ele rebenta no arranque com o famoso `version 'GLIBC_2.38' not found`.

**O que muda com o `ridgun-libs`?**
Cada uma das 32 libs deste repositório está escrita integralmente em Ridgun tabular e comunica diretamente com o kernel do sistema operativo através da camada PAL (`posix`) ou executa algoritmos puros em memória determinística (`RMM1`/`RMM2`). Compilam tanto para pacotes portáteis (`.rglib` / `.rgc`) como para objetos partilhados ELF64 nativos (`lib*.so`). Sem `libc`, sem FFI frágil e sem surpresas na implementação.

---

## Dor n.º 2: "A síndrome do `node_modules` / `Cargo.lock` de 400 dependências"

Em muitos ecossistemas modernos, a biblioteca padrão é tão esquelética que para ler um ficheiro `.ini`, validar um `UUIDv7`, aplicar um patch Unified Diff ou renderizar um template HTML seguro precisa de instalar meia dúzia de pacotes externos.

No **`ridgun-libs`**, todas as **32 libs** seguem uma única filosofia de desenho:

```ridgun
import crypto
import json
import http

fn :: autenticar y pedir (token : String) => String
      autenticar y pedir token =
        -- Todas as libs partilham tipos puros, alinhamento tabular e semântica determinística
        mac_hex = sha256 hex token
        cuerpo  = json stringify (JnObj [("token_sha256", JnStr mac_hex)])
        pet     = http build request "POST" "/v1/sesion" [("Content-Type", "application/json")] cuerpo
        pet
```

Mesma estética tabular, mesmos ADTs imutáveis (`Option`, `Result`, `IoResult`, `JsonVal`), zero efeitos colaterais ocultos.

---

## Dor n.º 3: "Expressões regulares que bloqueiam a CPU (ReDoS) e sockets que ficam pendurados para sempre"

Duas bombas-relógio clássicas em produção:

- Um utilizador malicioso envia uma cadeia desenhada para forçar o seu motor de expressões regulares com *backtracking* a entrar em tempo exponencial $O(2^N)$, queimando um núcleo a 100 %.
- Um descritor de rede fica meio aberto e a sua tarefa bloqueia eternamente num `read()` sem prazo limite.

No **`ridgun-libs`**:
- A lib **`regex`** (Capítulo 11) implementa um autómato **NFA de Thompson** que garante tempo linear estrito **$O(N \cdot M)$**: imune por construção a ataques ReDoS.
- As libs **`posix`**, **`io`** e **`socket`** (Capítulos 22, 23 e 27) integram quotas léxicas `with timeout` e `ppoll` ao nível do descritor: nenhuma operação de entrada/saída pode bloquear o seu serviço.

---

## Dor n.º 4: "Criptografia e álgebra linear que parecem hieróglifos"

No **`ridgun-libs`**, o poder dos tipos `Tensor[...]` do Ridgun permite que libs como **`tensor`** (Capítulo 05), **`linalg`** (Capítulo 06) e **`argon2id`** (Capítulo 25) operem sobre blocos de memória contígua (`Tensor[U64 * 8 * 16]`, `Tensor[Real]`) mantendo a legibilidade de uma tabela matemática.

---

## Mapa completo do livro: 32 capítulos para 32 libs

Cada capítulo deste livro é dedicado a **uma lib** do `ridgun-libs`, organizadas numa progressão lógica de baixo para cima:

| Capítulos | Família de libs | Libs incluídas |
|---|---|---|
| **01 – 04** | Texto, Matemática e Estruturas de Dados | `str`, `math`, `list`, `btree` |
| **05 – 06** | Tensores e Álgebra Linear | `tensor`, `linalg` |
| **07 – 10** | Codificação e Formatos de Dados | `codec`, `json`, `csv`, `ini` |
| **11 – 15** | Motores de Texto, Diffs, Templates e Formatação | `regex`, `glob`, `diff`, `template`, `fmt` |
| **16 – 21** | CLI, Caminhos, Tempo, UUIDs, Logs e Testes | `cli`, `path`, `time`, `uuid`, `log`, `test` |
| **22 – 23** | Sistemas POSIX e E/S com Timeout | `posix`, `io` |
| **24 – 26** | Criptografia, Argon2id e Tokens JWT | `crypto`, `argon2id`, `jwt` |
| **27 – 29** | Redes, Sockets do Kernel, HTTP/1.1 e WebSockets | `socket`, `http`, `ws` |
| **30 – 32** | Concorrência de Atores, Pools e Supervisão de Rede | `agent`, `pool`, `net_agent` |

Vamos a isto! Avance para o **Capítulo 01 (`str`)** e comecemos a construir.
