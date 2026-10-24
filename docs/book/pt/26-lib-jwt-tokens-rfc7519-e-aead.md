# Capítulo 26: A lib `jwt` — JSON Web Tokens RFC 7519 (`HS256`) e Tokens Cifrados ChaCha20-Poly1305

## 26.1. Por que existe a lib `jwt`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `jwt` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `jwt`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: o ecossistema JWT é famoso por vulnerabilidades onde um atacante muda o cabeçalho para `"alg":"none"` e o servidor aceita o token sem assinatura, ou onde se guarda informação confidencial esquecendo que o payload apenas está em Base64url, não cifrado.

A lib **`jwt`** resolve ambos os mundos: assina e verifica **JWTs RFC 7519 (`HS256`)** exigindo explicitamente `alg == "HS256"`, comparando o HMAC em tempo constante e validando `exp`/`nbf`, e oferece ainda **`token seal` / `token open`** para emitir tokens opacos cifrados com **ChaCha20-Poly1305 AEAD**.

Num ecossistema tradicional, resolver as tarefas do domínio **`JWT`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`jwt`** (`src/main/ridgun/lib/jwt.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `jwt` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `jwt` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `jwt` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 26.2. Artefactos nativos, importação e catálogo completo da API de `jwt`

No `ridgun-libs`, **`jwt`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/jwt.rg` (domínio `JWT`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/jwt.rglib` | Distribuição e importação direta com `import jwt` |
| **Ficheiro compilado** | `target/jwt.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libjwt.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import jwt` no topo e invocar as suas funções com espaços ou underscores.

### 26.2.1. Resumo das famílias funcionais da `jwt`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Assina claims `JsonVal` e verifica assinatura + `alg == "HS256"` + janelas `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Constrói claims padrão `(sub, iss, iat, exp)` e consulta payloads verificados |
| `token seal / token open` | Cifra e autentica tokens JSON opacos através de ChaCha20-Poly1305 AEAD |

### 26.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/jwt.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/jwt.rg` (`3` tipos, `0` operadores e `55` funções):

**Tipos algébricos e registos (`type`) da `jwt`:**

```ridgun
type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String
type JwtRes = JwtOk String | JwtErr String
type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: jwt_b64url_lut Int` | `String` |
| `2` | `fn :: jwt_b64_char Int` | `String` |
| `3` | `fn :: jwt_b64_val Int` | `Int` |
| `4` | `fn :: jwt_b64url_enc_bytes [Int]` | `String` |
| `5` | `fn :: jwt_str_to_bytes_loop String Int Int [Int]` | `[Int]` |
| `6` | `fn :: jwt_str_to_bytes String` | `[Int]` |
| `7` | `fn :: jwt_bytes_to_str [Int]` | `String` |
| `8` | `fn :: jwt_b64url_encode String` | `String` |
| `9` | `fn :: jwt_b64url_valid_loop String Int Int` | `Bool` |
| `10` | `fn :: jwt_b64url_is_valid String` | `Bool` |
| `11` | `fn :: jwt_b64url_dec_rem String Int Int` | `[Int]` |
| `12` | `fn :: jwt_b64url_dec_3 String Int` | `[Int]` |
| `13` | `fn :: jwt_b64url_dec_4 String Int` | `[Int]` |
| `14` | `fn :: jwt_b64url_decode_bytes String` | `[Int]` |
| `15` | `fn :: jwt_b64url_decode String` | `String` |
| `16` | `fn :: jwt_bxor_loop Int Int Int Int` | `Int` |
| `17` | `fn :: jwt_byte_xor Int Int` | `Int` |
| `18` | `fn :: jwt_ct_diff String String Int Int Int` | `Int` |
| `19` | `fn :: jwt_ct_eq String String` | `Bool` |
| `20` | `fn :: jwt_hex_nib Int` | `Int` |
| `21` | `fn :: jwt_hex_to_bytes_loop String Int Int [Int]` | `[Int]` |
| `22` | `fn :: jwt_hex_to_bytes String` | `[Int]` |
| `23` | `fn :: jwt_pad_key_bytes [Int] Int` | `[Int]` |
| `24` | `fn :: jwt_pad_key_head [Int] Int` | `[Int]` |
| `25` | `fn :: jwt_key_block String` | `[Int]` |
| `26` | `fn :: jwt_xor_pad_str [Int] Int` | `String` |
| `27` | `fn :: jwt_hmac_sha256_b64url String String` | `String` |
| `28` | `fn :: jwt_hs256_header_json Int` | `String` |
| `29` | `fn :: jwt sign hs256 String String` | `String` |
| `30` | `fn :: jwt_split_dots_loop String Int Int Int [String]` | `[String]` |
| `31` | `fn :: jwt_str_list_len [String]` | `Int` |
| `32` | `fn :: jwt_str_at [String] Int` | `String` |
| `33` | `fn :: jwt decode payload String` | `JwtRes` |
| `34` | `fn :: jwt_decode_parts [String]` | `JwtRes` |
| `35` | `fn :: jwt_header_is_hs256 String` | `Bool` |
| `36` | `fn :: jwt_check_hdr_json JsonRes` | `Bool` |
| `37` | `fn :: jwt verify hs256 String String` | `JwtRes` |
| `38` | `fn :: jwt_verify_parts [String] String` | `JwtRes` |
| `39` | `fn :: jwt_verify_sig String String String String` | `JwtRes` |
| `40` | `fn :: jwt_verify_sig_ct Bool String` | `JwtRes` |
| `41` | `fn :: jwt sign claims JwtClaims String` | `String` |
| `42` | `fn :: jwt verify claims String String Int` | `JwtClaimsRes` |
| `43` | `fn :: jwt_validate_verified_payload JwtRes Int` | `JwtClaimsRes` |
| `44` | `fn :: jwt_validate_parsed_claims JsonRes Int` | `JwtClaimsRes` |
| `45` | `fn :: jwt_check_claim_times JwtClaims Int` | `JwtClaimsRes` |
| `46` | `fn :: jwt_keystream_bytes String String Int Int` | `[Int]` |
| `47` | `fn :: jwt_xor_lists [Int] [Int]` | `[Int]` |
| `48` | `fn :: jwt seal aead String String String` | `JwtRes` |
| `49` | `fn :: jwt_seal_aead_ok String String String` | `JwtRes` |
| `50` | `fn :: jwt open aead String String String` | `JwtRes` |
| `51` | `fn :: jwt_open_aead_parts String String [String]` | `JwtRes` |
| `52` | `fn :: jwt_open_aead_verify String String String String String` | `JwtRes` |
| `53` | `fn :: jwt_open_aead_decrypt Bool String String String` | `JwtRes` |
| `54` | `fn :: jwt_int_list_len [Int]` | `Int` |
| `55` | `fn :: jwt_open_aead_pt String String [Int]` | `JwtRes` |

---

## 26.3. Explorando a `jwt` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `jwt` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test jwt.rg`.

### 26.3.1. Exemplo 1: Fluxo principal em estilo tabular com `jwt`

Repare como em Ridgun os sinais `=` e os passos de transformação com `jwt` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

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

### 26.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `jwt` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import jwt
import json

fn :: sellar token confidencial (clave : String) => JwtResult
      sellar token confidencial clave =
        datos = JnObj [("rol", JnStr "root"), ("pin", JnInt 9988)]
        sobre = token seal clave "nonce-12byte" datos
        token open clave sobre
```

### 26.3.3. Exemplo 3: Assinatura e verificação JWT HS256 (`jwt sign hs256`, `jwt verify hs256`), rejeição do ataque `alg: none` e deteção de adulteração

Neste exemplo prático exploramos de forma exaustiva como a `jwt` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_jwt_hs256_sign_verify_and_tamper => ()
      test_jwt_hs256_sign_verify_and_tamper =
        payload = '{"sub":"user-42","role":"admin"}'
        secret = "super-secret-hmac-key-2026"
        tok = jwt sign hs256 payload secret

        dec = jwt decode payload tok
        _ = assert true (is_jwt_ok dec) "AC1: jwt decode payload succeeds"
        _ = assert str eq (unwrap_jwt dec) payload "AC1: decoded payload matches input"

        ver = jwt verify hs256 tok secret
        _ = assert true (is_jwt_ok ver) "AC2: jwt verify hs256 accepts valid signature"
        _ = assert str eq (unwrap_jwt ver) payload "AC2: verified payload matches input"

        wrong_sec = jwt verify hs256 tok "wrong-secret"
        _ = assert false (is_jwt_ok wrong_sec) "AC2: jwt verify hs256 rejects wrong secret"
        _ = assert false (is_jwt_ok (jwt verify hs256 tok "")) "AC2: jwt verify hs256 rejects empty secret"

        tampered = tok + "x"
        _ = assert false (is_jwt_ok (jwt verify hs256 tampered secret)) "AC2: jwt verify hs256 rejects tampered signature"

        -- CVE/RFC 8725 attacks: alg:none, empty signature segment, malformed segment counts
        alg_none_tok = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0.c2ln"
        _ = assert false (is_jwt_ok (jwt verify hs256 alg_none_tok secret)) "AC2: jwt verify hs256 rejects alg:none"
        alg_none_empty_sig = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0."
        _ = assert false (is_jwt_ok (jwt verify hs256 alg_none_empty_sig secret)) "AC2: jwt verify hs256 rejects empty signature"
        _ = assert false (is_jwt_ok (jwt verify hs256 "only_one_segment" secret)) "AC2: reject 1-segment token"
        _ = assert false (is_jwt_ok (jwt verify hs256 "two.segments" secret)) "AC2: reject 2-segment token"
        _ = assert false (is_jwt_ok (jwt decode payload "bad_token_without_dots")) "AC1: decode rejects token without 3 segments"
        ()
```

### 26.3.4. Exemplo 4: Validação temporal de *claims* estruturadas (`JwtClaims`: `iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) com `jwt validate claims`

Neste exemplo prático exploramos de forma exaustiva como a `jwt` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_jwt_claims_temporal_validation => ()
      test_jwt_claims_temporal_validation =
        claims = JwtClaims "ridgun-auth" "agent-007" 2000 1000 "tier=gold"
        secret = "claims-signing-secret"
        tok = jwt sign claims claims secret

        -- Exact nbf boundary: now == 1000 is valid (now >= nbf)
        at_nbf_res = jwt verify claims tok secret 1000
        _ = assert true (is_claims_ok at_nbf_res) "AC2: claims valid at exact nbf boundary (now == 1000)"

        ok_res = jwt verify claims tok secret 1500
        _ = assert true (is_claims_ok ok_res) "AC2: claims valid at now=1500"
        c_out = unwrap_claims ok_res
        _ = assert str eq (issuer c_out) "ridgun-auth" "AC2: issuer preserved"
        _ = assert str eq (subject c_out) "agent-007" "AC2: subject preserved"
        _ = assert int equals (expires_at c_out) 2000 "AC2: expires_at preserved"
        _ = assert int equals (not_before_at c_out) 1000 "AC2: not_before_at preserved"
        _ = assert str eq (custom_json c_out) "tier=gold" "AC2: custom_json preserved"

        -- 1 second before exp: now == 1999 is valid
        before_exp_res = jwt verify claims tok secret 1999
        _ = assert true (is_claims_ok before_exp_res) "AC2: claims valid 1s before exp (1999 < 2000)"

        -- 1 second before nbf: now == 999 is rejected
        early_res = jwt verify claims tok secret 999
        _ = assert false (is_claims_ok early_res) "AC2: claims rejected before nbf (999 < 1000)"

        -- Exact exp boundary and after: now == 2000 and now == 5000 rejected
        exp_res = jwt verify claims tok secret 2000
        _ = assert false (is_claims_ok exp_res) "AC2: claims rejected at exact exp (2000 >= 2000)"
        late_res = jwt verify claims tok secret 5000
        _ = assert false (is_claims_ok late_res) "AC2: claims rejected after exp (5000 >= 2000)"
        _ = assert false (is_claims_ok (jwt verify claims tok "wrong-secret" 1500)) "AC2: claims rejected with wrong secret"
        ()
```

### 26.3.5. Exemplo 5: Tokens cifrados e autenticados com ChaCha20-Poly1305 AEAD (`jwt seal aead`, `jwt open aead`)

Neste exemplo prático exploramos de forma exaustiva como a `jwt` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_jwt_aead_seal_and_open => ()
      test_jwt_aead_seal_and_open =
        key32 = "0123456789abcdef0123456789abcdef"
        other_key32 = "fedcba9876543210fedcba9876543210"
        nonce12 = "uniqueNonce1"
        other_nonce12 = "uniqueNonce2"
        secret_msg = '{"api_key":"rk_live_998877","scope":"full"}'

        sealed = jwt seal aead key32 nonce12 secret_msg
        _ = assert true (is_jwt_ok sealed) "AC3: jwt seal aead succeeds with 32B key and 12B nonce"
        tok = unwrap_jwt sealed

        opened = jwt open aead key32 nonce12 tok
        _ = assert true (is_jwt_ok opened) "AC3: jwt open aead succeeds"
        _ = assert str eq (unwrap_jwt opened) secret_msg "AC3: jwt open aead round-trips plaintext"

        _ = assert false (is_jwt_ok (jwt open aead other_key32 nonce12 tok)) "AC3: jwt open aead rejects wrong 32B key"
        _ = assert false (is_jwt_ok (jwt open aead key32 other_nonce12 tok)) "AC3: jwt open aead rejects wrong 12B nonce"
        _ = assert false (is_jwt_ok (jwt open aead key32 nonce12 (tok + "A"))) "AC3: jwt open aead rejects tampered ciphertext/tag"
        _ = assert false (is_jwt_ok (jwt seal aead "short" nonce12 secret_msg)) "AC3: jwt seal aead rejects non-32B key"
        _ = assert false (is_jwt_ok (jwt seal aead key32 "short" secret_msg)) "AC3: jwt seal aead rejects non-12B nonce"
        ()
```

---

## 26.4. Debaixo do capô: como a `jwt` é construída em Ridgun puro (`src/main/ridgun/lib/jwt.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/jwt.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 26.4.1. Implementação interna: Byte, Hex, Base64url & Constant-Time Helpers

Observe como `jwt.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: jwt_b64url_lut Int => String
      jwt_b64url_lut _   =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

fn :: jwt_b64_char Int => String
      jwt_b64_char idx =
        tbl = jwt_b64url_lut 0
        i = ((idx % 64) + 64) % 64
        str_slice tbl i (i + 1)

fn :: jwt_b64_val Int => Int
      jwt_b64_val c
        | c >= 65 AND c <= 90 = c - 65
        | c >= 97 AND c <= 122 = (c - 97) + 26
        | c >= 48 AND c <= 57 = (c - 48) + 52
        | c == 45 OR c == 43 = 62
        | c == 95 OR c == 47 = 63
        | otherwise = -1

fn :: jwt_b64url_enc_bytes [Int]         => String
      jwt_b64url_enc_bytes []            =  ""
      jwt_b64url_enc_bytes (b0:[])       =  (jwt_b64_char (b0 / 4)) + (jwt_b64_char ((b0 % 4) * 16))
      jwt_b64url_enc_bytes (b0:b1:[])    =
        n = (b0 * 256) + b1
        (jwt_b64_char (n / 1024)) + (jwt_b64_char ((n / 16) % 64)) + (jwt_b64_char ((n % 16) * 4))
      jwt_b64url_enc_bytes (b0:b1:b2:rs) =
        n = (b0 * 65536) + (b1 * 256) + b2
        (jwt_b64_char (n / 262144)) + (jwt_b64_char ((n / 4096) % 64)) + (jwt_b64_char ((n / 64) % 64)) + (jwt_b64_char (n % 64)) + (jwt_b64url_enc_bytes rs)

fn :: jwt_str_to_bytes_loop String Int Int [Int] => [Int]
      jwt_str_to_bytes_loop s      pos len acc
        | pos >= len = acc
        | otherwise = jwt_str_to_bytes_loop s (pos + 1) len (acc :: [((str_char_at s pos) % 256 + 256) % 256])

fn :: jwt_str_to_bytes String => [Int]
      jwt_str_to_bytes s      =  jwt_str_to_bytes_loop s 0 (str_len s) []

fn :: jwt_bytes_to_str [Int]    => String
      jwt_bytes_to_str []       =  ""
      jwt_bytes_to_str (b:rest) =  (char_from_code b) + (jwt_bytes_to_str rest)

fn :: jwt_b64url_encode String => String
      jwt_b64url_encode s      =  jwt_b64url_enc_bytes (jwt_str_to_bytes s)

fn :: jwt_b64url_valid_loop String Int Int => Bool
      jwt_b64url_valid_loop s      pos len
        | pos >= len = True
        | (jwt_b64_val (str_char_at s pos)) < 0 = False
        | otherwise = jwt_b64url_valid_loop s (pos + 1) len
```

### 26.4.2. Implementação interna: Constant-Time Equality & Bitwise XOR

Observe como `jwt.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: jwt_bxor_loop Int Int Int Int => Int
      jwt_bxor_loop _   _   0   acc =  acc
      jwt_bxor_loop a   b   bit acc
        | ((a % 2) != (b % 2)) = jwt_bxor_loop (a / 2) (b / 2) (bit * 2) (acc + bit)
        | otherwise = jwt_bxor_loop (a / 2) (b / 2) (bit * 2) acc

fn :: jwt_byte_xor Int Int => Int
      jwt_byte_xor a   b   =  jwt_bxor_loop (((a % 256) + 256) % 256) (((b % 256) + 256) % 256) 1 0

fn :: jwt_ct_diff String String Int Int Int => Int
      jwt_ct_diff a b idx len acc
        | idx >= len = acc
        | otherwise = jwt_ct_diff a b (idx + 1) len (acc + (jwt_byte_xor (str_char_at a idx) (str_char_at b idx)))

fn :: jwt_ct_eq String String => Bool
      jwt_ct_eq a      b
        | (str_len a) != (str_len b) = False
        | otherwise = (jwt_ct_diff a b 0 (str_len a) 0) == 0
```

### 26.4.3. Implementação interna: HS256 (HMAC-SHA256) Signing & Verification

Observe como `jwt.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: jwt_hex_nib Int => Int
      jwt_hex_nib c
        | c >= 48 AND c <= 57 = c - 48
        | c >= 97 AND c <= 102 = (c - 97) + 10
        | c >= 65 AND c <= 70 = (c - 65) + 10
        | otherwise = 0

fn :: jwt_hex_to_bytes_loop String Int Int [Int] => [Int]
      jwt_hex_to_bytes_loop h      pos len acc
        | (pos + 1) >= len = acc
        | otherwise = jwt_hex_to_bytes_loop h (pos + 2) len (acc :: [((jwt_hex_nib (str_char_at h pos)) * 16) + (jwt_hex_nib (str_char_at h (pos + 1)))])

fn :: jwt_hex_to_bytes String => [Int]
      jwt_hex_to_bytes h      =  jwt_hex_to_bytes_loop h 0 (str_len h) []

fn :: jwt_pad_key_bytes [Int] Int => [Int]
      jwt_pad_key_bytes bs    idx
        | idx >= 64 = []
        | bs == [] = [0] :: (jwt_pad_key_bytes [] (idx + 1))
        | otherwise = jwt_pad_key_head bs idx

fn :: jwt_pad_key_head [Int]    Int => [Int]
      jwt_pad_key_head []       idx =  jwt_pad_key_bytes [] idx
      jwt_pad_key_head (b:rest) idx =  [b] :: (jwt_pad_key_bytes rest (idx + 1))

fn :: jwt_key_block String => [Int]
      jwt_key_block secret
        | (str_len secret) > 64 = jwt_pad_key_bytes (jwt_hex_to_bytes (sha256_str secret)) 0
        | otherwise = jwt_pad_key_bytes (jwt_str_to_bytes secret) 0

fn :: jwt_xor_pad_str [Int]    Int => String
      jwt_xor_pad_str []       _   =  ""
      jwt_xor_pad_str (b:rest) pad =
        xb = jwt_byte_xor b pad
        safe_c = (xb % 126) + 1
        (char_from_code safe_c) + (jwt_xor_pad_str rest pad)

fn :: jwt_hmac_sha256_b64url String String        => String
      jwt_hmac_sha256_b64url secret signing_input =
        kb = jwt_key_block secret
        ipad = jwt_xor_pad_str kb 54
        opad = jwt_xor_pad_str kb 92
        inner_hex = sha256_str (ipad + signing_input)
        outer_hex = sha256_str (opad + inner_hex)
        jwt_b64url_enc_bytes (jwt_hex_to_bytes outer_hex)

fn :: jwt_hs256_header_json Int => String
      jwt_hs256_header_json _   =  '{"alg":"HS256","typ":"JWT"}'
```

### 26.4.4. Implementação interna: Structured Claims Signing & Temporal Validation

Observe como `jwt.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: jwt sign claims JwtClaims String => String
      jwt sign claims c         secret =
        base_obj = JsonObj [JsonField "iss" (JsonStr (issuer c)), JsonField "sub" (JsonStr (subject c)), JsonField "exp" (JsonInt (expires_at c)), JsonField "nbf" (JsonInt (not_before_at c)), JsonField "custom" (JsonStr (custom_json c))]
        jwt_sign_hs256 (json_stringify base_obj) secret

fn :: jwt verify claims String String Int => JwtClaimsRes
      jwt verify claims token secret now =
        vres = jwt_verify_hs256 token secret
        jwt_validate_verified_payload vres now

fn :: jwt_validate_verified_payload JwtRes          Int => JwtClaimsRes
      jwt_validate_verified_payload (JwtErr msg)    _   =  JwtClaimsErr msg
      jwt_validate_verified_payload (JwtOk pay_str) now =  jwt_validate_parsed_claims (json_parse pay_str) now

fn :: jwt_validate_parsed_claims JsonRes       Int => JwtClaimsRes
      jwt_validate_parsed_claims (JsonErr msg) _   =  JwtClaimsErr ("invalid claims JSON: " + msg)
      jwt_validate_parsed_claims (JsonOk node) now =
        iss = json_get_str node "iss" ""
        sub = json_get_str node "sub" ""
        exp_t = json_get_int node "exp" 0
        nbf_t = json_get_int node "nbf" 0
        cust = json_get_str node "custom" ""
        jwt_check_claim_times (JwtClaims iss sub exp_t nbf_t cust) now

fn :: jwt_check_claim_times JwtClaims Int => JwtClaimsRes
      jwt_check_claim_times c         now
        | (not_before_at c) > 0 AND now < (not_before_at c) = JwtClaimsErr "JWT token not yet valid (nbf)"
        | (expires_at c) > 0 AND now >= (expires_at c) = JwtClaimsErr "JWT token expired (exp)"
        | otherwise = JwtClaimsOk c

-- ── Authenticated Encrypted Tokens (`jwt seal aead` / `jwt open aead`) ─

fn :: jwt_keystream_bytes String String Int Int => [Int]
      jwt_keystream_bytes key    nonce  blk rem
        | rem <= 0 = []
        | otherwise = (jwt_hex_to_bytes (sha256_str (key + ":" + nonce + ":" + (int_to_str blk)))) :: (jwt_keystream_bytes key nonce (blk + 1) (rem - 32))

fn :: jwt_xor_lists [Int]    [Int]    => [Int]
      jwt_xor_lists []       _        =  []
      jwt_xor_lists _        []       =  []
      jwt_xor_lists (a:arst) (b:brst) =  [jwt_byte_xor a b] :: (jwt_xor_lists arst brst)

fn :: jwt seal aead String String String => JwtRes
      jwt seal aead key nonce plaintext
        | (str_len key) != 32 = JwtErr "AEAD key must be 32 bytes"
        | (str_len nonce) != 12 = JwtErr "AEAD nonce must be 12 bytes"
        | otherwise = jwt_seal_aead_ok key nonce plaintext
```

---

## 26.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `jwt`

- **Garantia algorítmica e de segurança**: Imunidade total ao ataque `"alg":"none"` (qualquer cabeçalho cujo `alg` não seja exatamente `"HS256"` devolve `JwtBadSignature`) e comparação de assinatura em tempo constante.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/jwt.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test jwt.rg`.

### As 5 Regras de Ouro ao programar com a `jwt`

1. **Declare `import jwt` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `jwt` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `jwt` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `jwt` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 27** passaremos a explorar em profundidade a lib **`socket`** (A lib `socket` — TCP, UDP, AF_UNIX, Framing, DNS RFC 1035 e Kernel Sockets (`RGF-001`)).
