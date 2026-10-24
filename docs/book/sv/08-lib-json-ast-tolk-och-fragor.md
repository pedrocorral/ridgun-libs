# Kapitel 08: Lib:en `json` — Rekursiv RFC 8259 AST-tolk, Pretty-Printer och Sökvägsfrågor

## 1. Varför finns lib:en `json`?

Låt oss vara ärliga: att navigera i djupt nästlad JSON i många statiskt typade språk kräver sidor av boilerplate-kod eller tio kedjade `.and_then()` bara för att läsa ett portnummer.

Lib:en **`json`** erbjuder en komplett rekursiv **RFC 8259**-tolk till den algebraiska datatypen `JsonVal` (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), kompakt och indenterad serialisering (`json pretty`) samt punktseparerade sökvägsfrågor (`"server.http.port"`, `"users.0.name"`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`json`** en förstklassig **lib** placerad i `src/main/ridgun/lib/json.rg` (domän `JSON`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/json.rglib` | Portabel distribution och direkt import med `import json` |
| **Kompilerat arkiv** | `target/json.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libjson.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import json` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `json`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | Tolkar JSON-text till `JsonVal` och kontrollerar att `JnErr` inte uppstått |
| `json stringify / json pretty` | Serialiserar `JsonVal` till kompakt eller flerradig indenterad JSON |
| `json get path / json get str / json get int / json get bool` | Navigerar i nästlade objekt och listor via punktseparerade sökvägar (`"a.b.0.c"`) |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `json`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import json

fn :: leer config servidor (raw : String) => (String, Int, Bool)
      leer config servidor raw =
        doc  = json parse raw
        host = json get str doc "server.host" "127.0.0.1"
        port = json get int doc "server.port" 8080
        tls  = json get bool doc "server.tls.enabled" False
        (host, port, tls)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `json` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import json

fn :: construir manifiesto () => String
      construir manifiesto =
        nodo = JnObj [("app", JnStr "solstice"), ("workers", JnInt 8), ("tags", JnArr [JnStr "elf64", JnStr "rmm2"])]
        json pretty nodo 2
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Strikt avvisande av skräptecken efter rotvärdet (`trailing garbage`), fullständig hantering av escape-sekvenser och undantagsfri felrapportering med `JnErr`.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_json.rg`.
