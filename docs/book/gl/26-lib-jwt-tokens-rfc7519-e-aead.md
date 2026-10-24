# Capítulo 26: A lib `jwt` — JSON Web Tokens RFC 7519 (`HS256`) e Tokens Cifrados ChaCha20-Poly1305

## 1. Por que existe a lib `jwt`?

Sexamos sinceros: o ecosistema JWT é famoso por vulnerabilidades onde un atacante muda a cabeceira a `"alg":"none"` e o servidor acepta o token sen sinatura, ou onde se garda información sensible nun JWT esquecendo que o seu payload só está codificado en Base64url, non cifrado.

A lib **`jwt`** resolve ambos mundos: asina e verifica **JWTs RFC 7519 (`HS256`)** esixindo explicitamente `alg == "HS256"`, comparando o HMAC en tempo constante e validando `exp`/`nbf`, e ademais ofrece **`token seal` / `token open`** para emitir tokens opacos autenticados e cifrados con **ChaCha20-Poly1305 AEAD**.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`jwt`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/jwt.rg` (dominio `JWT`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/jwt.rglib` | Distribución e importación directa con `import jwt` |
| **Ficheiro compilado** | `target/jwt.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libjwt.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import jwt` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `jwt`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Asina claims `JsonVal` e verifica sinatura + `alg == "HS256"` + xanelas `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Constrúe claims estándar `(sub, iss, iat, exp)` e consulta payloads verificados |
| `token seal / token open` | Cifra e autentica tokens JSON opacos mediante ChaCha20-Poly1305 AEAD |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `jwt`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

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

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `jwt` é compoñible co resto das 32 libs de `ridgun-libs`:

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

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Inmunidade total ao ataque `"alg":"none"` (calquera cabeceira cuxo `alg` non sexa exactamente `"HS256"` devolve `JwtBadSignature`) e comparación de sinatura en tempo constante.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_jwt.rg`.
