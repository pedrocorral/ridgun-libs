# Kapitel 26: Lib:en `jwt` — RFC 7519 `HS256` JSON Web Tokens och ChaCha20-Poly1305-krypterade Tokens

## 1. Varför finns lib:en `jwt`?

Låt oss vara ärliga: JWT-ekosystemet är ökänt för sårbarheter där en angripare ändrar headern till `"alg":"none"` och servern godkänner token utan signatur, eller där känslig data lagras i en vanlig JWT vars payload bara är Base64url-kodad, inte krypterad.

Lib:en **`jwt`** löser båda behoven: den signerar och verifierar **RFC 7519 (`HS256`) JWT:er** med strikt krav på `alg == "HS256"`, konstanttidsjämförelse av MAC och kontroll av `exp`/`nbf`, samt erbjuder **`token seal` / `token open`** för opaka tokens krypterade med **ChaCha20-Poly1305 AEAD**.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`jwt`** en förstklassig **lib** placerad i `src/main/ridgun/lib/jwt.rg` (domän `JWT`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/jwt.rglib` | Portabel distribution och direkt import med `import jwt` |
| **Kompilerat arkiv** | `target/jwt.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libjwt.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import jwt` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `jwt`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Signerar `JsonVal`-claims och verifierar signatur + `alg == "HS256"` + `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Bygger standard-claims `(sub, iss, iat, exp)` och frågar verifierade payloads |
| `token seal / token open` | Krypterar och autentiserar opaka JSON-tokens via ChaCha20-Poly1305 AEAD |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `jwt`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

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

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `jwt` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

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

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Fullständig immunitet mot `"alg":"none"`-attacker (alla headers där `alg != "HS256"` returnerar `JwtBadSignature`) och konstanttidsverifiering av signaturer.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_jwt.rg`.
