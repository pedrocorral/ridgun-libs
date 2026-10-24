# Capítulo 26: A lib `jwt` — JSON Web Tokens RFC 7519 (`HS256`) e Tokens Cifrados ChaCha20-Poly1305

## 1. Por que existe a lib `jwt`?

Sejamos sinceros: o ecossistema JWT é famoso por vulnerabilidades onde um atacante muda o cabeçalho para `"alg":"none"` e o servidor aceita o token sem assinatura, ou onde se guarda informação confidencial esquecendo que o payload apenas está em Base64url, não cifrado.

A lib **`jwt`** resolve ambos os mundos: assina e verifica **JWTs RFC 7519 (`HS256`)** exigindo explicitamente `alg == "HS256"`, comparando o HMAC em tempo constante e validando `exp`/`nbf`, e oferece ainda **`token seal` / `token open`** para emitir tokens opacos cifrados com **ChaCha20-Poly1305 AEAD**.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`jwt`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/jwt.rg` (domínio `JWT`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/jwt.rglib` | Distribuição e importação direta com `import jwt` |
| **Ficheiro compilado** | `target/jwt.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libjwt.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import jwt` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `jwt`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Assina claims `JsonVal` e verifica assinatura + `alg == "HS256"` + janelas `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Constrói claims padrão `(sub, iss, iat, exp)` e consulta payloads verificados |
| `token seal / token open` | Cifra e autentica tokens JSON opacos através de ChaCha20-Poly1305 AEAD |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `jwt`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import jwt
import json

fn :: emitir y verificar sesion (secreto : String) => (String, String)
      emitir y verificar sesion secreto =
        claims = jwt claims "user-42" "solstice" 1700000000 1700003600
        tok    = jwt sign hs256 secreto claims
        res    = jwt verify hs256 secreto tok 1700001000
        sub    = jwt get str res "sub" "anonimo"
        (tok, sub)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `jwt` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import jwt
import json

fn :: sellar token confidencial (clave : String) => JwtResult
      sellar token confidencial clave =
        datos = JnObj [("rol", JnStr "root"), ("pin", JnInt 9988)]
        sobre = token seal clave "nonce-12byte" datos
        token open clave sobre
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Imunidade total ao ataque `"alg":"none"` (qualquer cabeçalho cujo `alg` não seja exatamente `"HS256"` devolve `JwtBadSignature`) e comparação de assinatura em tempo constante.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_jwt.rg`.
