# Capítol 37: La lib `tls` — Client TLS 1.3 i TLS 1.2, Validació de Cadenes X.509 i Verificació del Hostname

## 37.1. Per què existeix la lib `tls`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `tls` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `tls`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: gairebé tots els serveis amb què parla avui un programa són darrere de TLS, i enllaçar OpenSSL per arribar-hi comporta una dependència en C de mig milió de línies, amb el seu propi assignador de memòria i el seu propi calendari de correccions de seguretat.

La lib **`tls`** és un client TLS en Ridgun pur: **RFC 8446 TLS 1.3** i **RFC 5246 TLS 1.2**, amb intercanvi de claus ECDHE (X25519, secp256r1) i només suites AEAD (AES-128-GCM, ChaCha20-Poly1305), validació de cadenes **X.509** contra un paquet de certificats arrel, verificació del hostname **RFC 6125**, SNI i ALPN. Pren les seves primitives de `crypto` i les seves connexions de `socket`, i no té cap opció que se salti les comprovacions de cadena, caducitat, signatura o hostname.

En un ecosistema tradicional, resoldre les tasques del domini **`TLS`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`tls`** (`src/main/ridgun/lib/tls.ridgun`) aborda el problema amb quatre principis innegociables:

1. **Declara `import tls` (o `import tls as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: tls` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `tls` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 37.2. Artefactes natius, importació i catàleg complet de l'API de `tls`

A `ridgun-libs`, **`tls`** és una **lib** de primera classe situada a `src/main/ridgun/lib/tls.ridgun` (domini `TLS`). En compilar amb `stable bundle`, s'empaqueta en un format natiu:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tls.ridgunlib` | Distribució i importació directa amb `import tls` |

> Cada lib declara el seu propi espai de noms amb `module :: tls`: n'hi ha prou d'escriure `import tls` (o `import tls as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 37.2.1. Resum de famílies funcionals de `tls`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `tls defaults / tls with roots / tls with root pem / tls with alpn / tls with timeout / tls with versions` | Configuració: arrels de confiança, protocols ALPN, timeout i versions acceptades |
| `tls connect host / tls connect addr / tls connect` | Handshake sobre una connexió nova per nom o per adreça, o sobre un `Socket` existent, que retorna un `TlsResult` |
| `tls send / tls recv / tls close` | Enviament xifrat, recepció de fins a `max` bytes desxifrats, i `close_notify` més tancament |
| `tls is ok / tls unwrap / tls error kind / tls error reason` | Inspecciona el resultat: la connexió, o un de set errors tipats (`TlsCertExpired`, `TlsHostnameMismatch`, `TlsInvalidChain`, ...) |
| `tls verify chain / tls valid sni` | Valida una llista de certificats per a un nom de servidor sense connectar-se, i comprova un nom per a SNI |

### 37.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/tls.ridgun`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/tls.ridgun` (`5` tipus, `0` operadors i `185` funcions):

**Tipus algebraics i registres (`type`) de `tls`:**

```ridgun
type TlsConfig = root_certs_path: String, root_certs_pem: String, alpn_protocols: [String], min_version: Int, max_version: Int, timeout_ms: Int, verify_time_sec: Int
type TlsConn   = fd: Int, server_name: String, tls_version: Int, cipher_suite: Int, selected_alpn: String, c_key: String, c_iv: String, s_key: String, s_iv: String, io_timeout_ms: Int, state: Tensor[U64 * 16], rx_buf: Tensor[U64 * 65536]
type TlsError  = TlsCertExpired String | TlsHostnameMismatch String | TlsInvalidChain String | TlsUnsupportedVersion String | TlsServerAlert Int String | TlsTimeout String | TlsIoError String
type TlsResult = TlsOk TlsConn | TlsErr TlsError
type TlsHs = hs_fd: Int, hs_timeout: Int, hs_ver: Int, hs_suite: Int, hs_rkey: String, hs_riv: String, hs_rseq: Int, hs_wkey: String, hs_wiv: String, hs_wseq: Int, hs_pending: String, hs_transcript: String, hs_failed: Bool, hs_error: TlsError, hs_crand: String, hs_srand: String, hs_sid: String, hs_xpriv: String, hs_ppriv: String, hs_hsec: String, hs_csec: String, hs_ssec: String, hs_master: String, hs_leaf: String, hs_alpn: String, hs_cert_req: Bool, hs_cr_ctx: String, hs_ems: Bool, hs_group: Int, hs_peer_key: String, hs_next_rkey: String, hs_next_riv: String
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
|---|---|---|
| `1` | `fn :: tls st wseq` | `Int` |
| `2` | `fn :: tls st rseq` | `Int` |
| `3` | `fn :: tls st rx start` | `Int` |
| `4` | `fn :: tls st rx len` | `Int` |
| `5` | `fn :: tls st closed` | `Int` |
| `6` | `fn :: tls u8 String Int` | `Int` |
| `7` | `fn :: tls u16 String Int` | `Int` |
| `8` | `fn :: tls u24 String Int` | `Int` |
| `9` | `fn :: tls sub String Int Int` | `String` |
| `10` | `fn :: tls rest String Int` | `String` |
| `11` | `fn :: tls be2 Int` | `String` |
| `12` | `fn :: tls be3 Int` | `String` |
| `13` | `fn :: tls be4 Int` | `String` |
| `14` | `fn :: tls be8 Int` | `String` |
| `15` | `fn :: tls vec1 String` | `String` |
| `16` | `fn :: tls vec2 String` | `String` |
| `17` | `fn :: tls vec3 String` | `String` |
| `18` | `fn :: tls hs msg Int String` | `String` |
| `19` | `fn :: tls nonce String Int` | `String` |
| `20` | `fn :: tls random String Int` | `String` |
| `21` | `fn :: tls join [String] String` | `String` |
| `22` | `fn :: tls reverse [String] [String]` | `[String]` |
| `23` | `fn :: tls hex4 Int` | `String` |
| `24` | `fn :: tls suite is chacha Int` | `Bool` |
| `25` | `fn :: tls suite key len Int` | `Int` |
| `26` | `fn :: tls12 suite iv len Int` | `Int` |
| `27` | `fn :: tls12 suite known Int` | `Bool` |
| `28` | `fn :: tls12 suite is ecdsa Int` | `Bool` |
| `29` | `fn :: tls13 suite known Int` | `Bool` |
| `30` | `fn :: tls alert name Int` | `String` |
| `31` | `fn :: tls alert error Int` | `TlsError` |
| `32` | `fn :: tls error name TlsError` | `String` |
| `33` | `fn :: tls error text TlsError` | `String` |
| `34` | `fn :: tls defaults` | `TlsConfig` |
| `35` | `fn :: tls with roots TlsConfig String` | `TlsConfig` |
| `36` | `fn :: tls with root pem TlsConfig String` | `TlsConfig` |
| `37` | `fn :: tls with alpn TlsConfig [String]` | `TlsConfig` |
| `38` | `fn :: tls with timeout TlsConfig Int` | `TlsConfig` |
| `39` | `fn :: tls with verify time TlsConfig Int` | `TlsConfig` |
| `40` | `fn :: tls with versions TlsConfig Int Int` | `TlsConfig` |
| `41` | `fn :: tls aead seal Int String String String String` | `String` |
| `42` | `fn :: tls aead open Int String String String String` | `Int String` |
| `43` | `fn :: tls13 seal record Int String String Int Int String` | `String` |
| `44` | `fn :: tls13 strip inner String Int` | `Int Int String` |
| `45` | `fn :: tls13 open after Int String` | `Int Int String` |
| `46` | `fn :: tls13 open record Int String String Int String` | `Int Int String` |
| `47` | `fn :: tls12 seal record Int String String Int Int String` | `String` |
| `48` | `fn :: tls12 open record Int String String Int Int String` | `Int Int String` |
| `49` | `fn :: tls seal record Int Int String String Int Int String` | `String` |
| `50` | `fn :: tls open record Int Int String String Int Int String` | `Int Int String` |
| `51` | `fn :: tls plain record Int Int String` | `String` |
| `52` | `fn :: tls send all Int String Int` | `Bool` |
| `53` | `fn :: tls read exact step Int Int Int String Int String` | `Int String` |
| `54` | `fn :: tls read exact Int Int Int String` | `Int String` |
| `55` | `fn :: tls read record body Int Int Int String` | `Int Int String` |
| `56` | `fn :: tls read record Int Int` | `Int Int String` |
| `57` | `fn :: hs fail TlsHs TlsError` | `TlsHs` |
| `58` | `fn :: hs add TlsHs String` | `TlsHs` |
| `59` | `fn :: hs alert TlsHs String` | `TlsHs` |
| `60` | `fn :: hs absorb decrypted TlsHs Int Int String` | `TlsHs` |
| `61` | `fn :: hs absorb record TlsHs Int Int String` | `TlsHs` |
| `62` | `fn :: hs pull record TlsHs` | `TlsHs` |
| `63` | `fn :: hs msg len String` | `Int` |
| `64` | `fn :: hs next msg TlsHs` | `TlsHs Int String` |
| `65` | `fn :: hs send TlsHs String` | `TlsHs` |
| `66` | `fn :: hs seal hs TlsHs String` | `TlsHs String` |
| `67` | `fn :: tls find ext String Int Int` | `Bool Int Int` |
| `68` | `fn :: tls parse alpn String` | `String` |
| `69` | `fn :: tls alpn list [String] String` | `String` |
| `70` | `fn :: tls ch suites TlsConfig` | `String` |
| `71` | `fn :: tls ch versions TlsConfig` | `String` |
| `72` | `fn :: tls ext String String` | `String` |
| `73` | `fn :: tls sig schemes` | `String` |
| `74` | `fn :: tls client hello String String String String String TlsConfig` | `String` |
| `75` | `fn :: tls next nl String Int Int` | `Int` |
| `76` | `fn :: tls trim cr String` | `String` |
| `77` | `fn :: tls pem lines String Int Int [String]` | `[String]` |
| `78` | `fn :: tls pem group [String] Bool [String] [String]` | `[String]` |
| `79` | `fn :: tls pem b64 blocks String` | `[String]` |
| `80` | `fn :: tls b64 pattern String Int` | `String` |
| `81` | `fn :: tls pem may hold String String String String` | `Bool` |
| `82` | `fn :: tls roots decode String String` | `[X509Cert]` |
| `83` | `fn :: tls find roots [String] String String String String [X509Cert]` | `[X509Cert]` |
| `84` | `fn :: tls roots for [String] String` | `[X509Cert]` |
| `85` | `fn :: tls same cert X509Cert X509Cert` | `Bool` |
| `86` | `fn :: tls pick anchor X509Cert [X509Cert]` | `Bool X509Cert` |
| `87` | `fn :: tls pick issuer X509Cert [X509Cert]` | `Bool X509Cert` |
| `88` | `fn :: tls path step X509Cert [X509Cert] [String] Int [X509Cert] Bool X509Cert` | `Bool String [X509Cert]` |
| `89` | `fn :: tls build path X509Cert [X509Cert] [String] Int [X509Cert]` | `Bool String [X509Cert]` |
| `90` | `fn :: tls parse ders [String] [X509Cert]` | `Bool [X509Cert]` |
| `91` | `fn :: tls reverse certs [X509Cert] [X509Cert]` | `[X509Cert]` |
| `92` | `fn :: tls first expired [X509Cert] Int` | `String` |
| `93` | `fn :: tls now sec TlsConfig` | `Int` |
| `94` | `fn :: tls root pem text TlsConfig` | `String` |
| `95` | `fn :: tls check path Bool String [X509Cert] X509Cert String TlsConfig` | `Bool TlsError` |
| `96` | `fn :: tls verify parsed Bool [X509Cert] String TlsConfig` | `Bool TlsError` |
| `97` | `fn :: tls no certs [X509Cert]` | `Bool` |
| `98` | `fn :: c nth cert [X509Cert] Int` | `X509Cert` |
| `99` | `fn :: tls verify chain [String] String TlsConfig` | `Bool TlsError` |
| `100` | `fn :: tls scheme alg Int` | `String` |
| `101` | `fn :: tls scheme fits Int String Bool` | `Bool` |
| `102` | `fn :: tls verify scheme String Int String String Bool` | `Bool` |
| `103` | `fn :: tls13 hs secret String` | `String` |
| `104` | `fn :: tls13 master secret String` | `String` |
| `105` | `fn :: tls13 key String Int` | `String` |
| `106` | `fn :: tls13 iv String` | `String` |
| `107` | `fn :: tls13 finished mac String String` | `String` |
| `108` | `fn :: tls13 cv content String` | `String` |
| `109` | `fn :: tls13 cert entries String Int Int [String]` | `[String]` |
| `110` | `fn :: tls13 cert list String` | `[String]` |
| `111` | `fn :: tls12 cert entries String Int Int [String]` | `[String]` |
| `112` | `fn :: tls12 cert list String` | `[String]` |
| `113` | `fn :: tls hrr random` | `String` |
| `114` | `fn :: tls ecdh TlsHs Int String` | `String` |
| `115` | `fn :: tls13 setup TlsHs String String Int TlsConfig` | `TlsHs` |
| `116` | `fn :: tls13 keys TlsHs Int String` | `TlsHs` |
| `117` | `fn :: tls12 setup TlsHs String String Int TlsConfig` | `TlsHs` |
| `118` | `fn :: tls on server hello TlsHs Int String String TlsConfig` | `TlsHs` |
| `119` | `fn :: tls read server hello TlsHs String TlsConfig` | `TlsHs` |
| `120` | `fn :: tls on hrr TlsHs String String String TlsConfig` | `TlsHs` |
| `121` | `fn :: tls retry hello TlsHs String String String TlsConfig` | `TlsHs` |
| `122` | `fn :: tls13 on ee TlsHs Int String` | `TlsHs` |
| `123` | `fn :: tls13 read ee TlsHs` | `TlsHs` |
| `124` | `fn :: tls13 on cert TlsHs Int String String TlsConfig` | `TlsHs` |
| `125` | `fn :: tls13 read cert TlsHs String TlsConfig` | `TlsHs` |
| `126` | `fn :: tls13 on cv TlsHs Int String` | `TlsHs` |
| `127` | `fn :: tls13 read cv TlsHs` | `TlsHs` |
| `128` | `fn :: tls13 on fin TlsHs Int String` | `TlsHs` |
| `129` | `fn :: tls13 read fin TlsHs` | `TlsHs` |
| `130` | `fn :: tls13 client cert msg TlsHs` | `String` |
| `131` | `fn :: tls13 send fin TlsHs` | `TlsHs` |
| `132` | `fn :: tls13 seal opt TlsHs String` | `TlsHs String` |
| `133` | `fn :: tls12 prf loop String String Int String String` | `String` |
| `134` | `fn :: tls12 prf String String String Int` | `String` |
| `135` | `fn :: tls12 on cert TlsHs Int String String TlsConfig` | `TlsHs` |
| `136` | `fn :: tls12 read cert TlsHs String TlsConfig` | `TlsHs` |
| `137` | `fn :: tls12 key fits Int String` | `Bool` |
| `138` | `fn :: tls12 on ske TlsHs Int String` | `TlsHs` |
| `139` | `fn :: tls12 read ske TlsHs` | `TlsHs` |
| `140` | `fn :: tls12 on done TlsHs Int String` | `TlsHs` |
| `141` | `fn :: tls12 read done TlsHs` | `TlsHs` |
| `142` | `fn :: tls12 our pub TlsHs` | `String` |
| `143` | `fn :: tls12 send keys TlsHs` | `TlsHs` |
| `144` | `fn :: tls12 send keys with TlsHs String` | `TlsHs` |
| `145` | `fn :: tls12 on ccs TlsHs Int Int String` | `TlsHs` |
| `146` | `fn :: tls12 read ccs TlsHs` | `TlsHs` |
| `147` | `fn :: tls12 on fin TlsHs Int String` | `TlsHs` |
| `148` | `fn :: tls12 read fin TlsHs` | `TlsHs` |
| `149` | `fn :: tls valid sni char Int` | `Bool` |
| `150` | `fn :: tls valid sni loop String Int Int Bool` | `Bool` |
| `151` | `fn :: tls valid sni String` | `Bool` |
| `152` | `fn :: tls new hs Int TlsConfig` | `TlsHs` |
| `153` | `fn :: tls finish TlsHs String` | `TlsResult` |
| `154` | `fn :: tls run handshake TlsHs String TlsConfig` | `TlsHs` |
| `155` | `fn :: tls connect fd Int String TlsConfig` | `TlsResult` |
| `156` | `fn :: tls connect opened Int Int String TlsConfig` | `TlsResult` |
| `157` | `fn :: tls close on error TlsResult Int` | `TlsResult` |
| `158` | `fn :: tls connect addr String Int String TlsConfig` | `TlsResult` |
| `159` | `fn :: tls connect host String Int TlsConfig` | `TlsResult` |
| `160` | `fn :: tls connect Socket String TlsConfig` | `TlsResult` |
| `161` | `fn :: tls get Tensor[U64 * 16] Int` | `Int` |
| `162` | `fn :: tls send chunks TlsConn String Int Int` | `Int` |
| `163` | `fn :: tls send TlsConn String` | `Int` |
| `164` | `fn :: tls buf store loop Tensor[U64 * 65536] String Int Int` | `Int` |
| `165` | `fn :: tls buf take loop CT16 Tensor[U64 * 65536] Int Int String String String String` | `String` |
| `166` | `fn :: tls take buffered TlsConn Int` | `String` |
| `167` | `fn :: tls deliver TlsConn String Int` | `String` |
| `168` | `fn :: tls mark closed TlsConn` | `String` |
| `169` | `fn :: tls on app record TlsConn Int Int Int String` | `String` |
| `170` | `fn :: tls on raw record TlsConn Int Int Int String` | `String` |
| `171` | `fn :: tls recv TlsConn Int` | `String` |
| `172` | `fn :: tls close TlsConn` | `()` |
| `173` | `fn :: tls send close notify TlsConn Int Int` | `Bool` |
| `174` | `fn :: tls is ok TlsResult` | `Bool` |
| `175` | `fn :: tls closed conn` | `TlsConn` |
| `176` | `fn :: tls unwrap TlsResult` | `TlsConn` |
| `177` | `fn :: tls error kind TlsResult` | `String` |
| `178` | `fn :: tls error reason TlsResult` | `String` |
| `179` | `fn :: rfc8448 hex String` | `String` |
| `180` | `fn :: rfc8448 v String` | `String` |
| `181` | `fn :: tls check [String] String Bool` | `[String]` |
| `182` | `fn :: rfc8448 open String String String Int` | `Int Int String` |
| `183` | `fn :: tls13 rfc8448 checks` | `[String]` |
| `184` | `fn :: tls13 rfc8448 self test` | `Bool` |
| `185` | `fn :: tls no names [String]` | `Bool` |

---

## 37.3. Explorant `tls` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `tls` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test tls.ridgun`.

### 37.3.1. Exemple 1: Flux principal en estil tabular amb `tls`

Observa com en Ridgun els signes `=` i els passos de transformació amb `tls` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import tls

fn :: leer cabecera TlsResult String => String
      leer cabecera r host =
        | tls is ok r = pedir cabecera (tls unwrap r) host
        | otherwise   = (tls error kind r) + ": " + (tls error reason r)

fn :: pedir cabecera TlsConn String => String
      pedir cabecera conn host =
        tls send conn ("HEAD / HTTP/1.1\r\nHost: " + host + "\r\nConnection: close\r\n\r\n") -> enviados
        tls recv conn 4096 -> respuesta
        tls close conn
        respuesta

fn :: cabecera https String => String
      cabecera https host =
        leer cabecera (tls connect host host 443 (tls defaults)) host
```

### 37.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `tls` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 38 libs de `ridgun-libs`:

```ridgun
import tls

fn :: conviene reintentar TlsResult => Bool
      conviene reintentar r =
        | tls is ok r                        = False
        | (tls error kind r) == "TlsTimeout" = True
        | (tls error kind r) == "TlsIoError" = True
        | otherwise                          = False
```

### 37.3.3. Exemple 3: RFC 8448 §3: la planificació de claus de TLS 1.3 i la protecció de registres contra la traça publicada

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `tls` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test rfc8448 vectors => ()
      test rfc8448 vectors =
        failures = tls13 rfc8448 checks
        print failures failures
        assert true (tls13 rfc8448 self test) "RFC 8448 §3 TLS 1.3 trace" -> ()
```

### 37.3.4. Exemple 4: El vector de la PRF de TLS 1.2, l'estructura del ClientHello i les regles de SNI

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `tls` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test tls12 prf and hello => ()
      test tls12 prf and hello =
        prf = tls12 prf (hex to byte str "9bbe436ba940f017b17652849a71db35") "test label" (hex to byte str "a0ba9f936cda311827a6f796ffd5198c") 100
        assert str eq (bytes to hex str prf) ("e3f229ba727be17b8d122620557cd453c2aab21d07c3d495329b52d4e61edb5a6b301791e90d35c9c9a46b4e14baf9af0fa022f7077def17abfd3797c0564bab4fbc91666e9def9b97fce34f796789baa48082d122ee42c5a72e5a5110fff70187347b66") "TLS 1.2 PRF SHA-256" -> ()
        ch = tls client hello "example.com" (c repeat byte 7 32) (c repeat byte 9 32) ((tls be2 29) + (tls vec2 (c repeat byte 1 32))) "" (tls defaults)
        assert eq (tls u8 ch 0) 1 -> ()
        assert eq ((tls u24 ch 1) + 4) (str len ch) -> ()
        assert true (str contains ch "example.com") "ClientHello carries SNI" -> ()
        assert true (tls valid sni "mail.example.com") "SNI accepts DNS names" -> ()
        assert false (tls valid sni "192.168.1.1") "SNI rejects IPv4 literals" -> ()
        assert false (tls valid sni "") "SNI rejects empty names" -> ()
        bad = tls connect host "127.0.0.1" 443 (tls defaults)
        assert str eq (tls error kind bad) "TlsIoError" "connect rejects IP literal as server name" -> ()
```

### 37.3.5. Exemple 5: Validació de cadenes: intermedis en qualsevol ordre, un intermedi absent, arrels no fiables, caducitat i hostnames

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `tls` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test chain verification String => ()
      test chain verification dir    =
        leaf_ec  = pem ders (dir + "/ec.pem")
        inter    = pem ders (dir + "/int.pem")
        chain    = leaf_ec :: inter
        cfg      = tls with root pem (tls defaults) (read file (dir + "/ca.pem"))
        now      = (sys wall time ms) / 1000
        assert str eq (chain kind chain "localhost" cfg) "" "leaf + intermediate -> root verifies" -> ()
        noise    = pem ders (dir + "/other.pem")
        assert str eq (chain kind (leaf_ec :: noise :: inter) "localhost" cfg) "" "leaf first, extra and unordered certificates after it" -> ()
        assert str eq (chain kind leaf_ec "localhost" cfg) "TlsInvalidChain" "missing intermediate is rejected" -> ()
        assert str eq (chain kind chain "example.com" cfg) "TlsHostnameMismatch" "wrong host is rejected" -> ()
        assert str eq (chain kind chain "localhost" (tls with verify time cfg (now + (10 * 86400)))) "TlsCertExpired" "expired chain is rejected" -> ()
        assert str eq (chain kind chain "localhost" (tls with verify time cfg 1000)) "TlsCertExpired" "not-yet-valid chain is rejected" -> ()
        other    = tls with root pem (tls defaults) (read file (dir + "/other.pem"))
        assert str eq (chain kind chain "localhost" other) "TlsInvalidChain" "untrusted root is rejected" -> ()
        self     = pem ders (dir + "/self.pem")
        assert str eq (chain kind self "localhost" cfg) "TlsInvalidChain" "self-signed leaf is rejected" -> ()
        self_cfg = tls with root pem (tls defaults) (read file (dir + "/self.pem"))
        assert str eq (chain kind self "localhost" self_cfg) "" "explicitly trusted self-signed leaf verifies" -> ()
        empty    = tls with roots (tls defaults) "/nonexistent/ca.pem"
        assert str eq (chain kind chain "localhost" empty) "TlsInvalidChain" "no roots means no trust (no bypass, AC4)" -> ()
        assert str eq (chain kind [] "localhost" cfg) "TlsInvalidChain" "empty certificate list is rejected" -> ()
        assert str eq (chain kind ["garbage"] "localhost" cfg) "TlsInvalidChain" "malformed certificate is rejected" -> ()
```

### 37.3.6. Exemple 6: Handshakes locals contra `openssl s_server`: TLS 1.3 i 1.2, AES-128-GCM i ChaCha20-Poly1305, ECDSA i RSA

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `tls` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test local handshakes String => ()
      test local handshakes dir    =
        p   = base port
        cfg = roots cfg dir
        ec  = "-cert ec.pem -key ec.key -cert_chain int.pem"
        rsa = "-cert rsa.pem -key rsa.key -cert_chain int.pem"
        v1, s1, _ = local roundtrip dir p (ec + " -tls1_3 -ciphersuites TLS_AES_128_GCM_SHA256") cfg "TLS 1.3 AES-128-GCM / ECDSA"
        assert eq v1 772 -> ()
        assert eq s1 4865 -> ()
        v2, s2, _ = local roundtrip dir (p + 1) (rsa + " -tls1_3 -ciphersuites TLS_CHACHA20_POLY1305_SHA256") cfg "TLS 1.3 ChaCha20-Poly1305 / RSA-PSS"
        assert eq v2 772 -> ()
        assert eq s2 4867 -> ()
        v3, s3, _ = local roundtrip dir (p + 2) (ec + " -tls1_3 -groups P-256") cfg "TLS 1.3 HelloRetryRequest to P-256"
        assert eq v3 772 -> ()
        v4, s4, _ = local roundtrip dir (p + 3) (rsa + " -tls1_2 -cipher ECDHE-RSA-AES128-GCM-SHA256") cfg "TLS 1.2 ECDHE-RSA-AES128-GCM"
        assert eq v4 771 -> ()
        assert eq s4 49199 -> ()
        v5, s5, _ = local roundtrip dir (p + 4) (ec + " -tls1_2 -cipher ECDHE-ECDSA-CHACHA20-POLY1305") cfg "TLS 1.2 ECDHE-ECDSA-ChaCha20"
        assert eq v5 771 -> ()
        assert eq s5 52393 -> ()
        v6, s6, _ = local roundtrip dir (p + 5) (ec + " -tls1_2 -cipher ECDHE-ECDSA-AES128-GCM-SHA256 -groups P-256") cfg "TLS 1.2 ECDHE P-256 / ECDSA"
        assert eq s6 49195 -> ()
        _, _, a7  = local roundtrip dir (p + 6) (ec + " -alpn h2,http/1.1") (tls with alpn cfg ["http/1.1"]) "ALPN"
        assert str eq a7 "http/1.1" "ALPN selection" -> ()
```

### 37.3.7. Exemple 7: Handshakes que han de fallar: discrepància de versions, arrel no fiable i errors tipats

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `tls` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test local failures String => ()
      test local failures dir    =
        p   = (base port) + 10
        cfg = roots cfg dir
        ec  = "-cert ec.pem -key ec.key -cert_chain int.pem"
        assert true (start server dir p (ec + " -tls1_2")) "s_server (TLS 1.2 only)" -> ()
        r1  = tls connect host "localhost" p (tls with versions cfg 772 772)
        assert str eq (tls error kind r1) "TlsUnsupportedVersion" "TLS 1.3-only client vs TLS 1.2-only server" -> ()
        assert true (start server dir (p + 1) ec) "s_server (untrusted)" -> ()
        r2  = tls connect host "localhost" (p + 1) (tls with root pem cfg (read file (dir + "/other.pem")))
        assert str eq (tls error kind r2) "TlsInvalidChain" "server chain under an untrusted root" -> ()
        lrc, lfd = sys tcp listen "127.0.0.1" 0 8
        assert eq lrc 0 -> ()
        r3  = tls connect host "localhost" (sys local port lfd) (tls with timeout cfg 300)
        assert str eq (tls error kind r3) "TlsTimeout" "silent server times out" -> ()
        sys close lfd -> ()
```

### 37.3.8. Exemple 8: Servidors en viu: llocs públics i els casos de fallada de `badssl.com`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `tls` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test live servers => ()
      test live servers =
        live "www.debian.org" 443 "" "HEAD / HTTP/1.1\r\nHost: www.debian.org\r\nConnection: close\r\n\r\n"
        live "smtp.gmail.com" 465 "" "QUIT\r\n"
        live "tls-v1-2.badssl.com" 1012 "" "HEAD / HTTP/1.1\r\nHost: tls-v1-2.badssl.com\r\nConnection: close\r\n\r\n"
        live "expired.badssl.com" 443 "TlsCertExpired" ""
        live "wrong.host.badssl.com" 443 "TlsHostnameMismatch" ""
        live "self-signed.badssl.com" 443 "TlsInvalidChain" ""
        live "untrusted-root.badssl.com" 443 "TlsInvalidChain" ""
        live "tls-v1-0.badssl.com" 1010 "TlsUnsupportedVersion TlsServerAlert" ""
```

---

## 37.4. Sota el capó: com està construïda `tls` en Ridgun pur (`src/main/ridgun/lib/tls.ridgun`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/tls.ridgun` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 37.4.1. Implementació interna: Configuration (API-TLS-001)

Fixa't en com `tls.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: tls defaults => TlsConfig
      tls defaults =  TlsConfig "/etc/ssl/certs/ca-certificates.crt" "" [] 771 772 10000 0

fn :: tls with roots TlsConfig String => TlsConfig
      tls with roots cfg       path   =  cfg with root_certs_path = path, root_certs_pem = ""

fn :: tls with root pem TlsConfig String => TlsConfig
      tls with root pem cfg       pem    =  cfg with root_certs_pem = pem

fn :: tls with alpn TlsConfig [String] => TlsConfig
      tls with alpn cfg       protos   =  cfg with alpn_protocols = protos

fn :: tls with timeout TlsConfig Int => TlsConfig
      tls with timeout cfg       ms  =  cfg with timeout_ms = ms

fn :: tls with verify time TlsConfig Int => TlsConfig
      tls with verify time cfg       sec =  cfg with verify_time_sec = sec

fn :: tls with versions TlsConfig Int Int => TlsConfig
      tls with versions cfg       lo  hi  =  cfg with min_version = lo, max_version = hi
```

### 37.4.2. Implementació interna: Record layer: AEAD, TLS 1.3 and TLS 1.2 record protection

Fixa't en com `tls.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: tls aead seal Int String String String String => String
      tls aead seal suite key   nonce  aad    pt     =
        | tls suite is chacha suite = aead seal key nonce aad pt
        | otherwise                 = aes128 gcm seal key nonce aad pt

fn :: tls aead open Int String String String String => Int String
      tls aead open suite key   nonce  aad    ct     =
        | (str len ct) < 16         = (0 - 12, "")
        | tls suite is chacha suite = aead open key nonce aad ct
        | otherwise                 = aes128 gcm open key nonce aad ct

-- TLSInnerPlaintext = content || type || zeros; AAD = record header (RFC 8446 §5.2).
fn :: tls13 seal record Int String String Int Int String => String
      tls13 seal record suite key   iv     seq ctype content =
        inner = content + (byte str ctype)
        hdr   = (byte str 23) + (tls be2 771) + (tls be2 ((str len inner) + 16))
        hdr + (tls aead seal suite key (tls nonce iv seq) hdr inner)

fn :: tls13 strip inner String Int => Int Int String
      tls13 strip inner pt     i   =
        | i < 0                = (0 - 7, 0, "")
        | (tls u8 pt i) == 0   = tls13 strip inner pt (i - 1)
        | otherwise            = (0, tls u8 pt i, str slice pt 0 i)

fn :: tls13 open after Int String => Int Int String
      tls13 open after rc  pt     =
        | rc != 0   = (rc, 0, "")
        | otherwise = tls13 strip inner pt ((str len pt) - 1)

fn :: tls13 open record Int String String Int String => Int Int String
      tls13 open record suite key   iv     seq payload =
        hdr    = (byte str 23) + (tls be2 771) + (tls be2 (str len payload))
        rc, pt = tls aead open suite key (tls nonce iv seq) hdr payload
        tls13 open after rc pt

-- GCM: nonce = salt(4) || explicit(8), explicit sent in the record. ChaCha20: RFC 7905 nonce.
-- AAD = seq(8) || type || version || plaintext length (RFC 5246 §6.2.3.3).
fn :: tls12 seal record Int String String Int Int String => String
      tls12 seal record suite key   iv     seq ctype content =
        aad  = (tls be8 seq) + (byte str ctype) + (tls be2 771) + (tls be2 (str len content))
        body =
          | tls suite is chacha suite = aead seal key (tls nonce iv seq) aad content
          | otherwise                 = (tls be8 seq) + (aes128 gcm seal key (iv + (tls be8 seq)) aad content)
        (byte str ctype) + (tls be2 771) + (tls vec2 body)

fn :: tls12 open record Int String String Int Int String => Int Int String
      tls12 open record suite key   iv     seq ctype payload =
        | tls suite is chacha suite =
          aad    = (tls be8 seq) + (byte str ctype) + (tls be2 771) + (tls be2 ((str len payload) - 16))
          rc, pt = tls aead open suite key (tls nonce iv seq) aad payload
          (rc, ctype, pt)
        | (str len payload) < 24 = (0 - 12, ctype, "")
        | otherwise =
          explicit = str slice payload 0 8
          aad      = (tls be8 seq) + (byte str ctype) + (tls be2 771) + (tls be2 ((str len payload) - 24))
          rc, pt   = aes128 gcm open key (iv + explicit) aad (tls rest payload 8)
          (rc, ctype, pt)

fn :: tls seal record Int Int String String Int Int String => String
      tls seal record ver suite key   iv     seq ctype content =
        | ver == 772 = tls13 seal record suite key iv seq ctype content
        | otherwise  = tls12 seal record suite key iv seq ctype content

fn :: tls open record Int Int String String Int Int String => Int Int String
      tls open record ver suite key   iv     seq ctype payload =
        | ver == 772 and ctype != 23 = (0 - 7, 0, "")
        | ver == 772                 = tls13 open record suite key iv seq payload
        | otherwise                  = tls12 open record suite key iv seq ctype payload

fn :: tls plain record Int Int String => String
      tls plain record ctype ver   body =  (byte str ctype) + (tls be2 ver) + (tls vec2 body)
```

### 37.4.3. Implementació interna: Certificate chain validation (FR-TLS-001 AC2/AC3/AC4)

Fixa't en com `tls.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
-- PEM bundle -> list of base64 bodies (one per CERTIFICATE block), without decoding them.
fn :: tls next nl String Int Int => Int
      tls next nl s      idx slen =
        | idx >= slen                = slen
        | (str char at s idx) == 10  = idx
        | otherwise                  = tls next nl s (idx + 1) slen

fn :: tls trim cr String => String
      tls trim cr line   =
        | (str len line) > 0 and (str char at line ((str len line) - 1)) == 13 = str slice line 0 ((str len line) - 1)
        | otherwise                                                           = line

fn :: tls pem lines String Int Int [String] => [String]
      tls pem lines s      idx slen acc      =
        | idx >= slen = tls reverse acc []
        | otherwise   =
          e = tls next nl s idx slen
          tls pem lines s (e + 1) slen ([tls trim cr (str slice s idx e)] :: acc)

fn :: tls pem group [String] Bool [String] [String] => [String]
      tls pem group []         _     _   blocks =  tls reverse blocks []
      tls pem group (ln:rest) inside cur blocks =
        | ln == "-----BEGIN CERTIFICATE-----"     = tls pem group rest True [] blocks
        | ln == "-----END CERTIFICATE-----" and inside = tls pem group rest False [] ([tls join (tls reverse cur []) ""] :: blocks)
        | inside                                  = tls pem group rest True ([ln] :: cur) blocks
        | otherwise                               = tls pem group rest False cur blocks

fn :: tls pem b64 blocks String => [String]
      tls pem b64 blocks pem    =  tls pem group (tls pem lines pem 0 (str len pem) []) False [] []

-- The base64 text of `der` at the three possible byte alignments, trimmed to the characters
-- that depend only on `der`. A root whose PEM contains one of them may hold that DER.
fn :: tls b64 pattern String Int => String
      tls b64 pattern der    k   =
        enc   = c b64 encode ((c repeat byte 0 k) + der)
        full  = ((k + (str len der)) / 3) * 4
        start =
          | k == 0    = 0
          | k == 1    = 2
          | otherwise = 3
        tls sub enc start (full - start)

fn :: tls pem may hold String String String String => Bool
      tls pem may hold b64    p0     p1     p2     =
        ((str len p0) > 0 and (str contains b64 p0)) or ((str len p1) > 0 and (str contains b64 p1)) or ((str len p2) > 0 and (str contains b64 p2))

fn :: tls roots decode String String => [X509Cert]
      tls roots decode b64    subject =
        ok_d, der  = c b64 decode b64
        ok_c, cert = x509 parse cert der
        res        =
          | ok_d and ok_c and (subject_der cert) == subject = [cert]
          | otherwise                                       = []
        res

-- Trusted roots whose subject equals `subject`.
fn :: tls find roots [String] String String String String [X509Cert] => [X509Cert]
      tls find roots []        _       _  _  _  acc =  acc
      tls find roots (b:rest) subject p0 p1 p2 acc =
        | tls pem may hold b p0 p1 p2 = tls find roots rest subject p0 p1 p2 ((tls roots decode b subject) :: acc)
        | otherwise                   = tls find roots rest subject p0 p1 p2 acc

fn :: tls roots for [String] String => [X509Cert]
      tls roots for roots    subject =  tls find roots roots subject (tls b64 pattern subject 0) (tls b64 pattern subject 1) (tls b64 pattern subject 2) []

fn :: tls same cert X509Cert X509Cert => Bool
      tls same cert a        b        =  ((tbs_der a) == (tbs_der b)) and ((sig_bytes a) == (sig_bytes b))

-- First anchor that signed `cur` (or that is `cur` itself).
fn :: tls pick anchor X509Cert [X509Cert] => Bool X509Cert
      tls pick anchor _   []       =  (False, x509 empty cert)
      tls pick anchor cur (a:rest) =
        | tls same cert cur a                                 = (True, a)
        | (issuer_der cur) == (subject_der a) and (x509 verify cert sig cur a) = (True, a)
        | otherwise                                           = tls pick anchor cur rest

-- First intermediate from the server's list that is a CA and signed `cur`.
fn :: tls pick issuer X509Cert [X509Cert] => Bool X509Cert
      tls pick issuer _   []       =  (False, x509 empty cert)
      tls pick issuer cur (c:rest) =
        | not (tls same cert cur c) and (is_ca c) and (issuer_der cur) == (subject_der c) and (x509 verify cert sig cur c) = (True, c)
        | otherwise = tls pick issuer cur rest

fn :: tls path step X509Cert [X509Cert] [String] Int [X509Cert] Bool X509Cert => Bool String [X509Cert]
      tls path step cur      pool       roots    depth acc        ok_a anchor   =
        | ok_a and (tls same cert cur anchor) = (True, "", acc)
        | ok_a                                = (True, "", acc :: [anchor])
        | otherwise                           =
          ok_i, inter = tls pick issuer cur pool
          res         =
            | ok_i                                 = tls build path inter pool roots (depth + 1) (acc :: [inter])
            | (issuer_der cur) == (subject_der cur) = (False, "self-signed certificate is not trusted", acc)
            | otherwise                            = (False, "certificate chain does not lead to a trusted root", acc)
          res

-- Build leaf -> ... -> trust anchor. Returns (ok, reason, path).
fn :: tls build path X509Cert [X509Cert] [String] Int [X509Cert] => Bool String [X509Cert]
      tls build path cur      pool       roots    depth acc        =
        | depth > 8 = (False, "certificate chain is too long", acc)
        | otherwise =
          ok_a, anchor = tls pick anchor cur (tls roots for roots (issuer_der cur))
          tls path step cur pool roots depth acc ok_a anchor

fn :: tls parse ders [String] [X509Cert] => Bool [X509Cert]
      tls parse ders []       acc =  (True, tls reverse certs acc [])
      tls parse ders (d:rest) acc =
        ok, cert = x509 parse cert d
        res      =
          | ok        = tls parse ders rest ([cert] :: acc)
          | otherwise = (False, [])
        res

fn :: tls reverse certs [X509Cert] [X509Cert] => [X509Cert]
      tls reverse certs []       acc =  acc
      tls reverse certs (x:rest) acc =  tls reverse certs rest ([x] :: acc)

fn :: tls first expired [X509Cert] Int => String
      tls first expired []       _   =  ""
      tls first expired (c:rest) now =
        | now < (not_before_at c) = "certificate is not yet valid: " + (subject_cn c)
        | now > (not_after_at c)  = "certificate has expired: " + (subject_cn c)
        | otherwise               = tls first expired rest now

fn :: tls now sec TlsConfig => Int
      tls now sec cfg       =
        | (verify_time_sec cfg) > 0 = verify_time_sec cfg
        | otherwise                 = (sys wall time ms) / 1000

fn :: tls root pem text TlsConfig => String
      tls root pem text cfg       =
        | (root_certs_pem cfg) != ""         = root_certs_pem cfg
        | file exists (root_certs_path cfg) = read file (root_certs_path cfg)
        | otherwise                          = ""

fn :: tls check path Bool String [X509Cert] X509Cert String TlsConfig => Bool TlsError
      tls check path ok_p reason path       leaf     server cfg       =
        expired = tls first expired path (tls now sec cfg)
        res     =
          | not ok_p                         = (False, TlsInvalidChain reason)
          | expired != ""                    = (False, TlsCertExpired expired)
          | not (x509 match hostname leaf server) = (False, TlsHostnameMismatch ("certificate does not match host " + server))
          | otherwise                        = (True, TlsIoError "")
        res

fn :: tls verify parsed Bool [X509Cert] String TlsConfig => Bool TlsError
      tls verify parsed ok_c certs       server cfg       =
        | not ok_c      = (False, TlsInvalidChain "malformed certificate")
        | tls no certs certs = (False, TlsInvalidChain "server sent no certificate")
        | otherwise     =
          leaf                = c nth cert certs 0
          roots               = tls pem b64 blocks (tls root pem text cfg)
          ok_p, reason, path  = tls build path leaf certs roots 0 [leaf]
          tls check path ok_p reason path leaf server cfg

fn :: tls no certs [X509Cert] => Bool
      tls no certs []    =  True
      tls no certs (_:_) =  False

fn :: c nth cert [X509Cert] Int => X509Cert
      c nth cert []       _   =  x509 empty cert
      c nth cert (x:rest) idx =
        | idx <= 0  = x
        | otherwise = c nth cert rest (idx - 1)

-- Verify a server certificate list (leaf first, DER) for `server`.
fn :: tls verify chain [String] String TlsConfig => Bool TlsError
      tls verify chain ders     server cfg       =
        ok_c, certs = tls parse ders ders []
        tls verify parsed ok_c certs server cfg
```

### 37.4.4. Implementació interna: TLS 1.3 key schedule (RFC 8446 §7.1, SHA-256 suites)

Fixa't en com `tls.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: tls13 hs secret String => String
      tls13 hs secret shared =
        early = hkdf extract "" (c repeat byte 0 32)
        hkdf extract (derive secret early "derived" "") shared

fn :: tls13 master secret String => String
      tls13 master secret hsec   =  hkdf extract (derive secret hsec "derived" "") (c repeat byte 0 32)

fn :: tls13 key String Int => String
      tls13 key secret klen =  hkdf expand label secret "key" "" klen

fn :: tls13 iv String => String
      tls13 iv secret =  hkdf expand label secret "iv" "" 12

fn :: tls13 finished mac String String => String
      tls13 finished mac secret transcript =  hmac sha256 (hkdf expand label secret "finished" "" 32) (sha256 bytes transcript)

fn :: tls13 cv content String => String
      tls13 cv content transcript =  (c repeat byte 32 64) + "TLS 1.3, server CertificateVerify" + (byte str 0) + (sha256 bytes transcript)

-- Certificate message (RFC 8446 §4.4.2): context, then entries of cert_data + extensions.
fn :: tls13 cert entries String Int Int [String] => [String]
      tls13 cert entries msg    pos end acc      =
        | (pos + 3) > end                           = tls reverse acc []
        | (pos + 3 + (tls u24 msg pos) + 2) > end   = []
        | otherwise                                 =
          clen = tls u24 msg pos
          elen = tls u16 msg (pos + 3 + clen)
          tls13 cert entries msg (pos + 3 + clen + 2 + elen) end ([tls sub msg (pos + 3) clen] :: acc)

fn :: tls13 cert list String => [String]
      tls13 cert list msg    =
        | (str len msg) < 8 = []
        | otherwise         =
          ctx_len = tls u8 msg 4
          lpos    = 5 + ctx_len
          tls13 cert entries msg (lpos + 3) (lpos + 3 + (tls u24 msg lpos)) []

fn :: tls12 cert entries String Int Int [String] => [String]
      tls12 cert entries msg    pos end acc      =
        | (pos + 3) > end                     = tls reverse acc []
        | (pos + 3 + (tls u24 msg pos)) > end = []
        | otherwise                           = tls12 cert entries msg (pos + 3 + (tls u24 msg pos)) end ([tls sub msg (pos + 3) (tls u24 msg pos)] :: acc)

fn :: tls12 cert list String => [String]
      tls12 cert list msg    =
        | (str len msg) < 7 = []
        | otherwise         = tls12 cert entries msg 7 (7 + (tls u24 msg 4)) []
```

---

## 37.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `tls`

- **Garantia algorísmica i de seguretat**: Cada handshake verifica la cadena fins a una arrel de confiança, les dates de validesa, la signatura del handshake i el hostname, i només s'ofereixen suites AEAD amb intercanvi de claus efímer: no hi ha cap opció que desactivi una comprovació (`FR-TLS-001` AC4).
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/tls.ridgun` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test tls.ridgun`.

### Les 5 Regles d'Or en programar amb `tls`

1. **Declara `import tls` a l'inici del fitxer** i crida les seves funcions amb espais, tal com estan declarades, perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `tls` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `tls` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `tls` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 38** passarem a explorar en profunditat la lib **`mail`** (La lib `mail` — Missatges RFC 5322 i Enviament SMTP sobre TLS).
