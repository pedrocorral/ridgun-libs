# Capítulo 26: La lib `jwt` — JSON Web Tokens RFC 7519 (`HS256`) y Tokens Cifrados ChaCha20-Poly1305

## 1. ¿Por qué existe la lib `jwt`?

Seamos sinceros: el ecosistema JWT es famoso por vulnerabilidades donde un atacante cambia la cabecera a `"alg":"none"` y el servidor acepta el token sin firma, o donde se guarda información sensible en un JWT olvidando que su payload solo está codificado en Base64url, no cifrado.

La lib **`jwt`** resuelve ambos mundos: firma y verifica **JWTs RFC 7519 (`HS256`)** exigiendo explícitamente `alg == "HS256"`, comparando el HMAC en tiempo constante y validando `exp`/`nbf`, y además ofrece **`token seal` / `token open`** para emitir tokens opacos autenticados y cifrados con **ChaCha20-Poly1305 AEAD**.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`jwt`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/jwt.rg` (dominio `JWT`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/jwt.rglib` | Distribución e importación directa con `import jwt` |
| **Archivo compilado** | `target/jwt.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libjwt.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import jwt` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `jwt`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Firma claims `JsonVal` y verifica firma + `alg == "HS256"` + ventanas `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Construye claims estándar `(sub, iss, iat, exp)` y consulta payloads verificados |
| `token seal / token open` | Cifra y autentica tokens JSON opacos mediante ChaCha20-Poly1305 AEAD |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `jwt`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

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

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `jwt` es componible con el resto de las 32 libs de `ridgun-libs`:

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

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Inmunidad total al ataque `"alg":"none"` (cualquier cabecera cuyo `alg` no sea exactamente `"HS256"` devuelve `JwtBadSignature`) y comparación de firma en tiempo constante.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_jwt.rg`.
