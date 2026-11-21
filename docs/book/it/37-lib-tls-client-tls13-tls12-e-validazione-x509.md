# Capitolo 37: La lib `tls` — Client TLS 1.3 e TLS 1.2, Validazione della Catena X.509 e Verifica dell'Hostname

## 37.1. Perché esiste la lib `tls`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `tls` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `tls`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: quasi ogni servizio con cui un programma parla oggi sta dietro TLS, e collegare OpenSSL per raggiungerlo porta con sé una dipendenza C da mezzo milione di righe, con il proprio allocatore e il proprio calendario di correzioni di sicurezza.

La lib **`tls`** è un client TLS in Ridgun puro: **RFC 8446 TLS 1.3** e **RFC 5246 TLS 1.2**, con scambio di chiavi ECDHE (X25519, secp256r1) e sole suite AEAD (AES-128-GCM, ChaCha20-Poly1305), validazione della catena **X.509** rispetto a un bundle di certificati radice, verifica dell'hostname **RFC 6125**, SNI e ALPN. Prende le primitive da `crypto` e le connessioni da `socket`, e non ha alcuna opzione che salti i controlli di catena, scadenza, firma o hostname.

In un ecosistema tradizionale, risolvere i compiti del dominio **`TLS`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`tls`** (`src/main/ridgun/lib/tls.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import tls` (o `import tls as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: tls` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `tls` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 37.2. Artefatti nativi, importazione e catalogo completo dell'API di `tls`

In `ridgun-libs`, **`tls`** è una **lib** di prima classe situata in `src/main/ridgun/lib/tls.ridgun` (dominio `TLS`). Compilando con `stable bundle`, viene impacchettata in un artefatto nativo:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tls.ridgunlib` | Distribuzione e importazione diretta con `import tls` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: tls`: basta scrivere `import tls` (o `import tls as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 37.2.1. Riepilogo delle famiglie funzionali di `tls`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `tls defaults / tls with roots / tls with root pem / tls with alpn / tls with timeout / tls with versions` | Configurazione: radici attendibili, protocolli ALPN, timeout e versioni accettate |
| `tls connect host / tls connect addr / tls connect` | Handshake su una nuova connessione per nome o per indirizzo, oppure su un `Socket` esistente, con restituzione di un `TlsResult` |
| `tls send / tls recv / tls close` | Invio cifrato, ricezione di al massimo `max` byte decifrati, e `close_notify` più chiusura |
| `tls is ok / tls unwrap / tls error kind / tls error reason` | Ispeziona il risultato: la connessione, oppure uno di sette errori tipizzati (`TlsCertExpired`, `TlsHostnameMismatch`, `TlsInvalidChain`, ...) |
| `tls verify chain / tls valid sni` | Valida una lista di certificati per un nome di server senza connettersi, e controlla un nome per SNI |

### 37.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/tls.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/tls.ridgun` (`5` tipi, `0` operatori e `185` funzioni):

**Tipi algebrici e record (`type`) di `tls`:**

```ridgun
type TlsConfig = root_certs_path: String, root_certs_pem: String, alpn_protocols: [String], min_version: Int, max_version: Int, timeout_ms: Int, verify_time_sec: Int
type TlsConn   = fd: Int, server_name: String, tls_version: Int, cipher_suite: Int, selected_alpn: String, c_key: String, c_iv: String, s_key: String, s_iv: String, io_timeout_ms: Int, state: Tensor[U64 * 16], rx_buf: Tensor[U64 * 65536]
type TlsError  = TlsCertExpired String | TlsHostnameMismatch String | TlsInvalidChain String | TlsUnsupportedVersion String | TlsServerAlert Int String | TlsTimeout String | TlsIoError String
type TlsResult = TlsOk TlsConn | TlsErr TlsError
type TlsHs = hs_fd: Int, hs_timeout: Int, hs_ver: Int, hs_suite: Int, hs_rkey: String, hs_riv: String, hs_rseq: Int, hs_wkey: String, hs_wiv: String, hs_wseq: Int, hs_pending: String, hs_transcript: String, hs_failed: Bool, hs_error: TlsError, hs_crand: String, hs_srand: String, hs_sid: String, hs_xpriv: String, hs_ppriv: String, hs_hsec: String, hs_csec: String, hs_ssec: String, hs_master: String, hs_leaf: String, hs_alpn: String, hs_cert_req: Bool, hs_cr_ctx: String, hs_ems: Bool, hs_group: Int, hs_peer_key: String, hs_next_rkey: String, hs_next_riv: String
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
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

## 37.3. Esplorare `tls` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `tls` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test tls.ridgun`.

### 37.3.1. Esempio 1: Flusso principale in stile tabulare con `tls`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `tls` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

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

### 37.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `tls` è progettata per comporsi con le guardie booleane `|` e con il resto delle 38 lib di `ridgun-libs`:

```ridgun
import tls

fn :: conviene reintentar TlsResult => Bool
      conviene reintentar r =
        | tls is ok r                        = False
        | (tls error kind r) == "TlsTimeout" = True
        | (tls error kind r) == "TlsIoError" = True
        | otherwise                          = False
```

### 37.3.3. Esempio 3: RFC 8448 §3: il key schedule di TLS 1.3 e la protezione dei record a confronto con la traccia pubblicata

In questo esempio pratico esploriamo in modo esaustivo come si comporta `tls` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test rfc8448 vectors => ()
      test rfc8448 vectors =
        failures = tls13 rfc8448 checks
        print failures failures
        assert true (tls13 rfc8448 self test) "RFC 8448 §3 TLS 1.3 trace" -> ()
```

### 37.3.4. Esempio 4: Il vettore della PRF di TLS 1.2, la struttura del ClientHello e le regole SNI

In questo esempio pratico esploriamo in modo esaustivo come si comporta `tls` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 37.3.5. Esempio 5: Validazione della catena: intermedi in qualsiasi ordine, un intermedio mancante, radici non attendibili, scadenza e hostname

In questo esempio pratico esploriamo in modo esaustivo come si comporta `tls` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 37.3.6. Esempio 6: Handshake locali contro `openssl s_server`: TLS 1.3 e 1.2, AES-128-GCM e ChaCha20-Poly1305, ECDSA e RSA

In questo esempio pratico esploriamo in modo esaustivo come si comporta `tls` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 37.3.7. Esempio 7: Handshake che devono fallire: versioni incompatibili, radice non attendibile ed errori tipizzati

In questo esempio pratico esploriamo in modo esaustivo come si comporta `tls` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 37.3.8. Esempio 8: Server reali: siti pubblici e i casi di errore di `badssl.com`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `tls` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

## 37.4. Sotto il cofano: come è costruita `tls` in Ridgun puro (`src/main/ridgun/lib/tls.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/tls.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 37.4.1. Implementazione interna: Configuration (API-TLS-001)

Nota come `tls.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 37.4.2. Implementazione interna: Record layer: AEAD, TLS 1.3 and TLS 1.2 record protection

Nota come `tls.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 37.4.3. Implementazione interna: Certificate chain validation (FR-TLS-001 AC2/AC3/AC4)

Nota come `tls.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 37.4.4. Implementazione interna: TLS 1.3 key schedule (RFC 8446 §7.1, SHA-256 suites)

Nota come `tls.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

## 37.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `tls`

- **Garanzia algoritmica e di sicurezza**: Ogni handshake verifica la catena fino a una radice attendibile, le date di validità, la firma dell'handshake e l'hostname, e vengono offerte solo suite AEAD con scambio di chiavi effimero: non esiste alcuna opzione che disattivi un controllo (`FR-TLS-001` AC4).
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/tls.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test tls.ridgun`.

### Le 5 Regole d'Oro quando programmi con `tls`

1. **Dichiara `import tls` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `tls` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `tls` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `tls` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 38** passeremo a esplorare in profondità la lib **`mail`** (La lib `mail` — Messaggi RFC 5322 e Invio SMTP su TLS).
