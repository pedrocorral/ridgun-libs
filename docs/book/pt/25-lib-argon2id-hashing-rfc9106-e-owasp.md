# Capítulo 25: A lib `argon2id` — RFC 9106 Argon2id sobre `Tensor[U64 * 8 * 16]`, Blake2b e Presets OWASP

## 1. Por que existe a lib `argon2id`?

Sejamos sinceros: guardar palavras-passe com um simples SHA-256 permite que uma GPU moderna teste milhares de milhões de combinações por segundo, mas ligar bibliotecas C externas para ter Argon2id traz dores de cabeça de compilação.

A lib **`argon2id`** implementa **RFC 9106 Argon2id** e **RFC 7693 Blake2b-512** a 100 % em Ridgun puro operando diretamente sobre blocos nativos `Tensor[U64 * 8 * 16]` (1 024 bytes por bloco em memória contígua RMM2), com geração de cadeias **PHC** (`$argon2id$v=19$m=...,t=...,p=...$`), perfis **OWASP** (`owaspfirst`, `owaspsecond`), suporte de *pepper* (`argon2id hash ctx`), derivação de chaves (`argon2id derive key`) e deteção de atualização de parâmetros (`argon2id needs rehash`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`argon2id`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/argon2id.rg` (domínio `CRYPTO`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/argon2id.rglib` | Distribuição e importação direta com `import argon2id` |
| **Ficheiro compilado** | `target/argon2id.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libargon2id.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import argon2id` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `argon2id`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `argon2id hash / argon2id verify` | Hashing PHC RFC 9106 de 6 argumentos (`pwd, salt, m_kib, t, p, tag_len`) e verificação em tempo constante |
| `argon2id hash with preset / argon2id params preset` | Perfis nomeados: `"interactive"`, `"owaspfirst"` (`19456 KiB, t=2`), `"owaspsecond"` (`47104 KiB, t=1`), `"moderate"`, `"sensitive"` |
| `argon2id hash ctx / argon2id verify ctx` | Hashing RFC 9106 com segredo `pepper` ($K$) e dados associados ($X$) |
| `argon2id derive key / argon2id needs rehash` | Derivação de chave binária bruta e deteção de necessidade de rehash em cadeias PHC |
| `blake2b / blake2b hex` | Resumo criptográfico de uso geral RFC 7693 Blake2b (`1..64` bytes) |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `argon2id`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import argon2id

fn :: proteger clave usuario (clave : String) => (String, Bool, Bool)
      proteger clave usuario clave =
        phc    = argon2id hash clave "sal-unica-16byte" 32 2 1 32
        valido = argon2id verify clave phc
        rehash = argon2id needs rehash phc 19456 2 1 32
        (phc, valido, rehash)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `argon2id` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import argon2id

fn :: derivar clave maestra (frase : String) (sal : String) => String
      derivar clave maestra frase sal =
        -- Deriva 32 bytes crudos listos para ChaCha20-Poly1305 AEAD
        argon2id derive key frase sal 64 2 1 32
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Correspondência byte a byte com os vetores oficiais RFC 9106 §5.3 e OpenSSL 3.5, operando sobre `Tensor[U64 * 8 * 16]` sem uma única linha de C.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_argon2id.rg`.
