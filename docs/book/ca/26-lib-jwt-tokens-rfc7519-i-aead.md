# Capítol 26: La lib `jwt` — JSON Web Tokens RFC 7519 (`HS256`) i Tokens Xifrats ChaCha20-Poly1305

## 1. Per què existeix la lib `jwt`?

Siguem sincers: l'ecosistema JWT és famós per vulnerabilitats on un atacant canvia la capçalera a `"alg":"none"` i el servidor accepta el token sense signatura, o on es desa informació sensible en un JWT oblidant que el seu payload només està codificat en Base64url, no xifrat.

La lib **`jwt`** resol tots dos mons: signa i verifica **JWTs RFC 7519 (`HS256`)** exigint explícitament `alg == "HS256"`, comparant l'HMAC en temps constant i validant `exp`/`nbf`, i a més ofereix **`token seal` / `token open`** per emetre tokens opacs autenticats i xifrats amb **ChaCha20-Poly1305 AEAD**.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`jwt`** és una **lib** de primera classe situada a `src/main/ridgun/lib/jwt.rg` (domini `JWT`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/jwt.rglib` | Distribució i importació directa amb `import jwt` |
| **Fitxer compilat** | `target/jwt.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libjwt.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import jwt` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `jwt`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Signa claims `JsonVal` i verifica signatura + `alg == "HS256"` + finestres `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Construeix claims estàndard `(sub, iss, iat, exp)` i consulta payloads verificats |
| `token seal / token open` | Xifra i autentica tokens JSON opacs mitjançant ChaCha20-Poly1305 AEAD |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `jwt`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

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

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `jwt` és componible amb la resta de les 32 libs de `ridgun-libs`:

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

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Immunitat total a l'atac `"alg":"none"` (qualsevol capçalera el `alg` de la qual no sigui exactament `"HS256"` retorna `JwtBadSignature`) i comparació de signatura en temps constant.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_jwt.rg`.
