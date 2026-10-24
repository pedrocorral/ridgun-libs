# 07. kapitulua: `codec` lib-a — Hex, Base64, Base64url, URL Percent-Encoding eta JSON Arina

## 1. Zergatik existitzen da `codec` lib-a?

Izan gaitezen zintzoak: ezerk ez du web integrazio bat azkarragoapurtzen JWT token batean Base64 estandarra (`+/=`) eta Base64url (`-_` betegarririk gabe) nahasteak edo query string bat ihes-karaktererik gabe kateatzeak baino.

**`codec`** lib-ak **RFC 4648** (Hex, Base64 eta Base64url), **RFC 3986** (URLen ehunekozko kodetzea eta `query encode` / `query decode`) eta **JSON arinaren (RFC 8259)** eraikitzaile/erauzleak inplementatzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`codec`** lehen mailako **lib** bat da, `src/main/ridgun/lib/codec.rg` bidean kokatua (`CODEC` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/codec.rglib` | Banaketa eta inportazio zuzena `import codec` bidez |
| **Fitxategi konpilatua** | `target/codec.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libcodec.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import codec` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `codec` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `hex encode / hex decode / hex is valid` | RFC 4648 kodeketa hamaseitarra letra xehez eta deskodeketa baliozkotua |
| `base64 encode / base64 decode` | RFC 4648 §4 Base64 estandarra `=` betegarriarekin |
| `base64url encode / base64url decode` | URLetarako RFC 4648 §5 Base64url segurua (`-`, `_`, betegarririk gabe) |
| `url encode / url decode / query encode / query decode` | RFC 3986 ehunekozko kodetzea eta `k=v&...` query string bihurketak |
| `json quote / json object / json get str / json get int` | AST gabeko JSON serializazio azkarra eta lehen mailako gakoen erauzketa |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `codec` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import codec

fn :: empaquetar parametros (usuario : String) (redir : String) => String
      empaquetar parametros usuario redir =
        token_b64 = base64url encode usuario
        query encode [("token", token_b64), ("next", redir)]
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`codec` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import codec

fn :: construir respuesta rapida (id : Int) (nombre : String) => (String, Int)
      construir respuesta rapida id nombre =
        doc = json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)]
        leido = json get int doc "id" 0
        (doc, leido)
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Gaizki osatutako sarrera hamaseitar edo Base64-en ukapen determinista (`""` itzuliz mugetatik kanpoko irakurketarik gabe) eta $decode(encode(x)) == x$ itzulgarritasun zehatza.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_codec.rg` suite automatizatuaren bidez.
