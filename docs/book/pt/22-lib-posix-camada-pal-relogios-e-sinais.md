# Capítulo 22: A lib `posix` — Camada de Abstração de Plataforma (PAL), Relógios, Sinais e CSPRNG

## 1. Por que existe a lib `posix`?

Sejamos sinceros: flags como `O_CREAT`, `O_NONBLOCK` ou números de syscall mudam entre Linux, macOS e arquiteturas (`X86_64` vs `Arm64`), e em C tudo se resolve com uma selva ilegível de `#ifdef`.

A lib **`posix`** implementa a **Camada de Abstração de Plataforma (PAL)** de 2 níveis do Ridgun usando guardas tabulares sobre `sys os` (`Linux | MacOS | Windows`) e `sys arch` (`X86_64 | Arm64 | RiscV64`), além de sondagem de descritores (`wait fd`), relógios monotónicos (`RGF-017`), sinais (`RGF-018`) e entropia CSPRNG do kernel (`sys random bytes`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`posix`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/posix.rg` (domínio `POSIX`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/posix.rglib` | Distribuição e importação direta com `import posix` |
| **Ficheiro compilado** | `target/posix.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libposix.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import posix` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `posix`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Tradução de flags do SO conforme `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Sonda um descritor devolvendo `PollReady`, `PollTimeout` ou `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Relógios monotónicos e relógio de parede UTC em milissegundos (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Sondagem não bloqueante de sinais (`SIGINT`, `SIGTERM`) e bytes CSPRNG do kernel |
| `read text / write text / file exists / run cmd` | E/S de ficheiros de alto nível, diretórios e execução de subprocessos |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `posix`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import posix

fn :: medir operacion () => (Int, Int)
      medir operacion =
        t0  = clock monotonic ms
        rnd = len (sys random bytes 32)
        t1  = clock monotonic ms
        (rnd, t1 - t0)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `posix` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura (fd : Int) => Bool
      esperar lectura fd =
        est = wait fd fd poll_in 100
        est == PollReady
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Os ramos de `sys os` e `sys arch` que não correspondem ao binário alvo são eliminados em tempo de compilação (Dead-Code Elimination) pelo `ridgunc`.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_posix.rg`.
