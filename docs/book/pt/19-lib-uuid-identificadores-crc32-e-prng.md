# Capítulo 19: A lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 e PRNG

## 1. Por que existe a lib `uuid`?

Sejamos sinceros: usar `UUIDv4` totalmente aleatórios como chave primária numa base de dados fragmenta os índices B-Tree, enquanto inventar IDs caseiros sem entropia do kernel acaba em colisões.

A lib **`uuid`** implementa **`UUIDv4`** (aleatório com CSPRNG do kernel) e **`UUIDv7`** (ordenado cronologicamente nos primeiros 48 bits segundo a **RFC 9562**), *checksums* rápidos (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) e um PRNG determinístico com semente.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`uuid`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/uuid.rg` (domínio `UUID`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/uuid.rglib` | Distribuição e importação direta com `import uuid` |
| **Ficheiro compilado** | `target/uuid.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libuuid.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import uuid` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `uuid`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Gera UUIDs canónicos de 36 caracteres RFC 9562 v4 (aleatório) e v7 (ordenado no tempo) |
| `uuid is valid / uuid version` | Valida o formato 8-4-4-4-12 e os bits de variante RFC 9562 (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Hashes não criptográficos e *checksums* rápidos de 32 bits |
| `prng next / prng range` | PRNG congruencial linear funcional puro para testes e simulações reprodutíveis |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `uuid`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `uuid` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: `uuid v7 at t1 < uuid v7 at t2` garante ordem lexicográfica monótona crescente ao longo do tempo, ideal para índices `btree` e bases de dados.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_uuid.rg`.
