# Capítol 08: La lib `json` — Arbre AST Recursiu RFC 8259, Pretty-Printer i Consultes per Ruta

## 1. Per què existeix la lib `json`?

Siguem sincers: navegar un JSON imbricat en molts llenguatges estàtics implica escriure tres pantalles de boilerplate o encadenar deu `.and_then()` abans de llegir un simple port.

La lib **`json`** proporciona un analitzador descendent recursiu complet per a **RFC 8259** sobre l'ADT algebraic `JsonVal` (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), serialització compacta i sagnada (`json pretty`) i consultes directes per ruta amb punts (`"server.http.port"`, `"users.0.name"`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`json`** és una **lib** de primera classe situada a `src/main/ridgun/lib/json.rg` (domini `JSON`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/json.rglib` | Distribució i importació directa amb `import json` |
| **Fitxer compilat** | `target/json.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libjson.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import json` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `json`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | Analitza text JSON en un arbre `JsonVal` i valida l'absència de `JnErr` |
| `json stringify / json pretty` | Serialitza `JsonVal` a JSON compacte o multilínia sagnat |
| `json get path / json get str / json get int / json get bool` | Recorre objectes i llistes imbricats mitjançant rutes amb punts (`"a.b.0.c"`) |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `json`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

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

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `json` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import json

fn :: construir manifiesto () => String
      construir manifiesto =
        nodo = JnObj [("app", JnStr "solstice"), ("workers", JnInt 8), ("tags", JnArr [JnStr "elf64", JnStr "rmm2"])]
        json pretty nodo 2
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Rebuig estricte de brossa sobrant després del valor arrel (`trailing garbage`), maneig complet d'escapaments i retorn segur de `JnErr` sense excepcions.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_json.rg`.
