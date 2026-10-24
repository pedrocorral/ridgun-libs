# Capítulo 24: A lib `crypto` — SHA-256, HMAC, PBKDF2, Argon2id e ChaCha20-Poly1305 AEAD

## 1. Por que existe a lib `crypto`?

Sejamos sinceros: comparar um HMAC com `==` abre a porta a ataques de temporização (*timing attacks*), e depender da `libssl.so` para calcular um `SHA-256` ou cifrar com `ChaCha20-Poly1305` destrói a portabilidade do seu binário.

A lib **`crypto`** implementa a 100 % em Ridgun puro sobre `Tensor[Int]` pré-alocado: operações de bytes/bits (`RGF-019`), **FIPS 180-4 SHA-256**, **RFC 2104 HMAC-SHA-256**, igualdade em tempo constante (`ct equal`), **RFC 8018 PBKDF2-HMAC-SHA-256** com pré-computação de estado intermédio, fachada **Argon2id** de 5 argumentos e cifra autenticada **RFC 8439 ChaCha20-Poly1305 AEAD** (`aead seal` / `aead open`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`crypto`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/crypto.rg` (domínio `CRYPTO`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/crypto.rglib` | Distribuição e importação direta com `import crypto` |
| **Ficheiro compilado** | `target/crypto.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libcrypto.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import crypto` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `crypto`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `sha256 bytes / sha256 hex` | Resumo binário de 32 bytes ou hexadecimal de 64 caracteres FIPS 180-4 SHA-256 |
| `hmac sha256 / hmac sha256 hex / ct equal` | MAC com chave RFC 2104 e comparação por acumulador em tempo constante |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | Derivação de chaves RFC 8018 com estados intermédios SHA-256 pré-computados |
| `argon2id hash / argon2id verify` | Hashing de palavras-passe PHC RFC 9106 de 5 argumentos e verificação em tempo constante |
| `aead seal / aead open` | Cifra autenticada RFC 8439 ChaCha20-Poly1305 e decifra com verificação de tag |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `crypto`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import crypto

fn :: cifrar mensaje sesion (secreto : String) (texto : String) => (Int, String)
      cifrar mensaje sesion secreto texto =
        key32   = sha256 bytes secreto
        nonce12 = "0123456789ab"
        aad     = "canal-autenticado"
        sellado = aead seal key32 nonce12 aad texto
        aead open key32 nonce12 aad sellado
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `crypto` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import crypto

fn :: verificar firma webhook (clave : String) (cuerpo : String) (firma_hex : String) => Bool
      verificar firma webhook clave cuerpo firma_hex =
        esperada = hmac sha256 hex clave cuerpo
        ct equal esperada firma_hex
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: `aead open` verifica a tag Poly1305 de 16 bytes em tempo constante antes de libertar um único byte de texto limpo (devolvendo `(-1, "")` em caso de adulteração).
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_crypto.rg`.
