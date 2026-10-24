# Capítol 07: La lib `codec` — Hex, Base64, Base64url, URL Percent-Encoding i JSON Lleuger

## 1. Per què existeix la lib `codec`?

Siguem sincers: res no trenca més ràpid una integració web que confondre Base64 estàndard (`+/=`) amb Base64url (`-_` sense farciment) en un token JWT, o construir una query string concatenant cadenes sense escapar.

La lib **`codec`** implementa els estàndards **RFC 4648** (Hex, Base64 i Base64url), **RFC 3986** (codificació percentual d'URLs i diccionaris `query encode` / `query decode`) i constructors/extractors ràpids de **JSON lleuger (RFC 8259)**.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`codec`** és una **lib** de primera classe situada a `src/main/ridgun/lib/codec.rg` (domini `CODEC`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/codec.rglib` | Distribució i importació directa amb `import codec` |
| **Fitxer compilat** | `target/codec.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libcodec.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import codec` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `codec`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `hex encode / hex decode / hex is valid` | Codificació hexadecimal RFC 4648 en minúscules i descodificació validada |
| `base64 encode / base64 decode` | Base64 estàndard RFC 4648 §4 amb farciment `=` |
| `base64url encode / base64url decode` | Base64url segur per a URLs RFC 4648 §5 (`-`, `_`, sense farciment) |
| `url encode / url decode / query encode / query decode` | Codificació percentual RFC 3986 i diccionaris de query string `k=v&...` |
| `json quote / json object / json get str / json get int` | Serialització JSON ràpida sense AST i extracció de claus de primer nivell |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `codec`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import codec

fn :: empaquetar parametros (usuario : String) (redir : String) => String
      empaquetar parametros usuario redir =
        token_b64 = base64url encode usuario
        query encode [("token", token_b64), ("next", redir)]
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `codec` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import codec

fn :: construir respuesta rapida (id : Int) (nombre : String) => (String, Int)
      construir respuesta rapida id nombre =
        doc = json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)]
        leido = json get int doc "id" 0
        (doc, leido)
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Rebuig determinista d'entrades hexadecimals o Base64 mal formades (retornant `""` sense lectures fora de límits) i reversibilitat exacta $decode(encode(x)) == x$.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_codec.rg`.
