# Capítulo 23: A lib `io` — Erros Tipados `IoResult`, E/S com `with timeout` e Processos

## 1. Por que existe a lib `io`?

Sejamos sinceros: uma chamada `read()` ou um subprocesso filho sem prazo limite (`timeout`) é um convite para que um único recurso pendurado esgote todos os trabalhadores do seu servidor.

A lib **`io`** modela cada operação do sistema com ADTs explícitos (`IoError`, `IoResult[A]`), combina `ppoll` não bloqueante com quotas léxicas `with timeout wait_ms do` do Ridgun e oferece os operadores mixfix `read fd ... timeout` e `write fd ... timeout`.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`io`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/io.rg` (domínio `IO`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/io.rglib` | Distribuição e importação direta com `import io` |
| **Ficheiro compilado** | `target/io.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libio.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import io` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `io`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Leitura/escrita não bloqueante de descritor limitada por `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Operadores mixfix ergonómicos (`op ::`) para E/S de descritor com prazo limite |
| `io read file / io write file / io read lines` | Funções seguras de ficheiros e fluxos de linhas que devolvem `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Executa um comando externo limitado por uma quota léxica `with timeout` |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `io`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import io

fn :: leer peticion segura (fd : Int) => String
      leer peticion segura fd =
        res = read fd fd max 4096 timeout 250
        io unwrap or res ""
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `io` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import io

fn :: describir fallo () => String
      describir fallo =
        format io error (IoTimeout "read" 250)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Nenhuma leitura, escrita ou comando executado através de `io` com quota `wait_ms` pode bloquear indefinidamente a thread ou ator chamador.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_io.rg`.
