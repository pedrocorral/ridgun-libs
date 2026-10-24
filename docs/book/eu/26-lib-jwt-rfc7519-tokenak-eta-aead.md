# 26. kapitulua: `jwt` lib-a — RFC 7519 JSON Web Tokenak (`HS256`) eta ChaCha20-Poly1305 Token Zifratuak

## 1. Zergatik existitzen da `jwt` lib-a?

Izan gaitezen zintzoak: JWT ekosistema ospetsua da erasotzaile batek goiburua `"alg":"none"`-ra aldatzen duen eta zerbitzariak tokena sinadurarik gabe onartzen duen ahultasunengatik, edo payload-a Base64url-n kodetuta baino ez dagoela ahaztuta informazio sentikorra gordetzeagatik.

**`jwt`** lib-ak bi munduak konpontzen ditu: **RFC 7519 (`HS256`) JWTak** sinatu eta egiaztatzen ditu `alg == "HS256"` esplizituki eskatuz, HMACa denbora konstantean konparatuz eta `exp`/`nbf` baliozkotuz, eta gainera **`token seal` / `token open`** eskaintzen ditu **ChaCha20-Poly1305 AEAD** bidez zifratutako token opakuak jaulkitzeko.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`jwt`** lehen mailako **lib** bat da, `src/main/ridgun/lib/jwt.rg` bidean kokatua (`JWT` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/jwt.rglib` | Banaketa eta inportazio zuzena `import jwt` bidez |
| **Fitxategi konpilatua** | `target/jwt.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libjwt.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import jwt` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `jwt` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | `JsonVal` claim-ak sinatzen ditu eta sinadura + `alg == "HS256"` + `exp`/`nbf` egiaztatzen ditu |
| `jwt claims / jwt get str / jwt get int` | `(sub, iss, iat, exp)` claim estandarrak eraiki eta egiaztatutako payload-ak kontsultatzen ditu |
| `token seal / token open` | JSON token opakuak zifratu eta autentifikatzen ditu ChaCha20-Poly1305 AEAD bidez |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `jwt` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

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

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`jwt` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

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

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: `"alg":"none"` erasoaren aurkako immunitate osoa (`alg` zehazki `"HS256"` ez duen edozein goiburuk `JwtBadSignature` itzultzen du) eta sinaduraren denbora konstanteko konparazioa.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_jwt.rg` suite automatizatuaren bidez.
