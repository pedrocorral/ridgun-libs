# Kapitel 07: Lib:en `codec` — RFC 4648 Hex, Base64, Base64url och URL-kodning

## 1. Varför finns lib:en `codec`?

Låt oss vara ärliga: inget kraschar en webbintegration snabbare än att blanda ihop standard-Base64 (`+/=`) med URL-säker Base64url (`-_` utan utfyllnad) i en JWT, eller att bygga query-strängar utan att koda specialtecken.

Lib:en **`codec`** implementerar **RFC 4648** (Hex, Base64 och Base64url), **RFC 3986** (procentkodning av URL:er samt `query encode` / `query decode`) och lättviktiga **RFC 8259 JSON**-byggare.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`codec`** en förstklassig **lib** placerad i `src/main/ridgun/lib/codec.rg` (domän `CODEC`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/codec.rglib` | Portabel distribution och direkt import med `import codec` |
| **Kompilerat arkiv** | `target/codec.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libcodec.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import codec` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `codec`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `hex encode / hex decode / hex is valid` | Hexadecimal kodning i gemener enligt RFC 4648 och validerad avkodning |
| `base64 encode / base64 decode` | Standard Base64 enligt RFC 4648 §4 med `=`-utfyllnad |
| `base64url encode / base64url decode` | URL-säker RFC 4648 §5 Base64url (`-`, `_`, utan utfyllnad) |
| `url encode / url decode / query encode / query decode` | RFC 3986-procentkodning och `k=v&...` query-strängkonvertering |
| `json quote / json object / json get str / json get int` | Snabb JSON-serialisering utan AST och nyckeluppslagning på toppnivå |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `codec`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import codec

fn :: empaquetar parametros (usuario : String) (redir : String) => String
      empaquetar parametros usuario redir =
        token_b64 = base64url encode usuario
        query encode [("token", token_b64), ("next", redir)]
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `codec` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import codec

fn :: construir respuesta rapida (id : Int) (nombre : String) => (String, Int)
      construir respuesta rapida id nombre =
        doc = json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)]
        leido = json get int doc "id" 0
        (doc, leido)
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Deterministiskt avvisande av felformade Hex- eller Base64-indata (returnerar `""` utan läsningar utanför gränserna) och exakt $decode(encode(x)) == x$-rundresa.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_codec.rg`.
