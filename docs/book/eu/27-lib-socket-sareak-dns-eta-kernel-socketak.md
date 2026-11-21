# 27. kapitulua: `socket` lib-a — TCP, UDP, AF_UNIX, Framing, RFC 1035 DNS eta Kernel Socketak (`RGF-001`)

## 27.1. Zergatik existitzen da `socket` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `socket` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `socket`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: C-n BSD socketak `struct sockaddr_in`, `htons`, `inet_pton` eta `getaddrinfo`-rekin programatzea (`glibc`-ren `libnss` arrastaka dakarrena gainera) 80ko hamarkadako erritu arkano bat da.

**`socket`** lib-ak bi geruza osagarri eskaintzen ditu C lerro bakar bat gabe: (1) **Solstice** bezalako ekoizpen-zerbitzarietarako **`RGF-001`** nukleoko deskribatzaileen APIa (`sys tcp listen`, `sys tcp listen reuseport`, `sys accept`, `sys tcp connect`, `sys send`, `sys recv`, `sys resolve ipv4` `/etc/hosts` + 53 atakako RFC 1035 UDP DNS paketeen bidez) eta (2) `Socket` egoera-makina funtzional aldaezina luzera-aurrizkidun framing, CRLF lerro eta CIDR azpisareekin.

Ekosistema tradizional batean, **`SOCK`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`socket`** lib-ak (`src/main/ridgun/lib/socket.ridgun`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import socket` (edo `import socket as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: socket` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `socket`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 27.2. Artefaktu natiboak, inportazioa eta `socket` APIaren katalogo osoa

`ridgun-libs`-en, **`socket`** lehen mailako **lib** bat da, `src/main/ridgun/lib/socket.ridgun` bidean kokatua (`SOCK` domeinua). `stable bundle`-ekin konpilatzean, formatu natibo bakarrean paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/socket.ridgunlib` | Banaketa eta inportazio zuzena `import socket` bidez |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: socket` bidez: nahikoa da goiburuan `import socket` (edo `import socket as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 27.2.1. `socket`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `sys tcp listen / sys tcp listen reuseport / sys unix listen` | IPv4 TCP (`SO_REUSEADDR` / `SO_REUSEPORT`) edo `AF_UNIX` entzuten jartzen du |
| `sys accept / sys tcp connect / sys unix connect` | Timeout bidez mugatutako `accept` eta `connect`, `(rc, fd)` / `(rc, fd, ip)` itzuliz |
| `sys send / sys recv / sys shutdown write` | Timeout bidezko socket bidalketa, harrera eta idazketa-itxiera (`SHUT_WR`) |
| `sys resolve ipv4 / sock resolve host` | Ridgun hutseko IPv4 ebazpena `/etc/hosts` eta RFC 1035 UDP DNS kontsulten bidez |
| `sock send frame / sock recv frame / ip in cidr` | Luzera-aurrizkidun (`N:payload`) framinga eta IPv4 CIDR azpisareen bat-etortzea |

### 27.2.2. `src/main/ridgun/lib/socket.ridgun`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/socket.ridgun` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`10` mota, `0` eragile eta `194` funtzio):

**`socket`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type SockAddr = family: String, host: String, port: Int, path: String
type SockOpts = reuse_addr: Bool, keep_alive: Bool, non_blocking: Bool, tcp_nodelay: Bool, broadcast: Bool, timeout_ms: Int, rcvbuf: Int, sndbuf: Int
type SockPoll = readable: Bool, writable: Bool, has_error: Bool
type Socket   = family: String, sock_id: Int, sock_type: String, local_addr: SockAddr, remote_addr: SockAddr, opts: SockOpts, is_open: Bool, is_listening: Bool, is_connected: Bool, can_read: Bool, can_write: Bool, rx_buf: Tensor[U8], tx_buf: Tensor[U8], dgram_sender: SockAddr
type SockAddrRes      = SockAddrOk SockAddr | SockAddrErr String
type SockRes          = SockOk Socket | SockErr String
type SockPairRes      = SockPairOk Socket Socket | SockPairErr String
type SockRecvBytesRes = SockBytesOk Socket Tensor[U8] | SockBytesErr String
type SockRecvStrRes   = SockStrOk Socket String | SockStrErr String
type SockRecvFromRes  = SockFromOk Socket Tensor[U8] SockAddr | SockFromErr String
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: str list len [String]` | `Int` |
| `2` | `fn :: nth str [String] Int` | `String` |
| `3` | `fn :: sk no bytes` | `Tensor[U8]` |
| `4` | `fn :: sk bytes len Tensor[U8]` | `Int` |
| `5` | `fn :: sk bytes join Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `6` | `fn :: sk bytes range Tensor[U8] Int Int` | `Tensor[U8]` |
| `7` | `fn :: sk bytes cut Tensor[U8] Int Int` | `Tensor[U8]` |
| `8` | `fn :: sk clamp to Int Int Int` | `Int` |
| `9` | `fn :: sk bytes take Tensor[U8] Int` | `Tensor[U8]` |
| `10` | `fn :: sk bytes drop Tensor[U8] Int` | `Tensor[U8]` |
| `11` | `fn :: find sub at String String Int Int Int` | `Int` |
| `12` | `fn :: find str index String String` | `Int` |
| `13` | `fn :: split by char loop String Int Int Int Int` | `[String]` |
| `14` | `fn :: split by char String Int` | `[String]` |
| `15` | `fn :: is valid port Int` | `Bool` |
| `16` | `fn :: is ascii digit Int` | `Bool` |
| `17` | `fn :: is digit range String Int Int` | `Bool` |
| `18` | `fn :: is all digits String` | `Bool` |
| `19` | `fn :: check octet range Int` | `Bool` |
| `20` | `fn :: is valid octet String` | `Bool` |
| `21` | `fn :: all valid octets [String]` | `Bool` |
| `22` | `fn :: is valid ipv4 parts [String]` | `Bool` |
| `23` | `fn :: is valid ipv4 String` | `Bool` |
| `24` | `fn :: is hex colon Int` | `Bool` |
| `25` | `fn :: check ipv6 chars String Int Int` | `Bool` |
| `26` | `fn :: is valid ipv6 String` | `Bool` |
| `27` | `fn :: is hostname char Int` | `Bool` |
| `28` | `fn :: check hostname chars String Int Int` | `Bool` |
| `29` | `fn :: is valid hostname String` | `Bool` |
| `30` | `fn :: sk lower char String Int Int` | `String` |
| `31` | `fn :: sk to lower loop String Int Int` | `String` |
| `32` | `fn :: sk to lower String` | `String` |
| `33` | `fn :: sk is ws Int` | `Bool` |
| `34` | `fn :: sk split ws loop String Int Int Int Bool` | `[String]` |
| `35` | `fn :: sk strip comment String Int` | `String` |
| `36` | `fn :: sk list has host [String] String` | `Bool` |
| `37` | `fn :: sk match hosts tokens [String] String` | `String` |
| `38` | `fn :: sk search hosts after found String [String] String` | `String` |
| `39` | `fn :: sk search hosts lines [String] String` | `String` |
| `40` | `fn :: sk file exists (Bool String Int Int Int String String Int String)` | `Bool` |
| `41` | `fn :: sk lookup etc hosts String` | `String` |
| `42` | `fn :: sk check valid ipv4 String` | `String` |
| `43` | `fn :: sk match resolv tokens [String]` | `String` |
| `44` | `fn :: sk search resolv after found String [String]` | `String` |
| `45` | `fn :: sk search resolv lines [String]` | `String` |
| `46` | `fn :: sk system nameserver` | `String` |
| `47` | `fn :: sk encode qname label String Int [String]` | `String` |
| `48` | `fn :: sk encode qname [String]` | `String` |
| `49` | `fn :: sk build dns query String` | `String` |
| `50` | `fn :: sk skip dns name step String Int Int Int` | `Int` |
| `51` | `fn :: sk skip dns name String Int Int` | `Int` |
| `52` | `fn :: sk check dns rdata String Int Int Int Int Int Int` | `String` |
| `53` | `fn :: sk parse dns after name String Int Int Int` | `String` |
| `54` | `fn :: sk parse dns answers String Int Int Int` | `String` |
| `55` | `fn :: sk extract dns after ancount String Int Int` | `String` |
| `56` | `fn :: sk extract dns after len String Int` | `String` |
| `57` | `fn :: sk extract dns ipv4 String` | `String` |
| `58` | `fn :: sk read dns after poll Int Int` | `String` |
| `59` | `fn :: sk udp dns query String String Int` | `String` |
| `60` | `fn :: sk resolve after dns String` | `Int String` |
| `61` | `fn :: sk resolve after hosts String String` | `Int String` |
| `62` | `fn :: sk use pal net` | `Bool` |
| `63` | `fn :: sk resolved String` | `Int String` |
| `64` | `fn :: sys resolve ipv4 String` | `Int String` |
| `65` | `fn :: sk wrap resolved host (Int String) Int` | `SockAddrRes` |
| `66` | `fn :: sock resolve host String Int` | `SockAddrRes` |
| `67` | `fn :: ipv4 to u32 String` | `Int` |
| `68` | `fn :: pow2 Int` | `Int` |
| `69` | `fn :: match cidr prefix String String Int` | `Bool` |
| `70` | `fn :: ip in cidr at String String Int` | `Bool` |
| `71` | `fn :: ip in cidr String String` | `Bool` |
| `72` | `fn :: has unsafe path char String` | `Bool` |
| `73` | `fn :: is safe unix path String` | `Bool` |
| `74` | `fn :: sock addr ipv4 String Int` | `SockAddrRes` |
| `75` | `fn :: sock addr ipv6 String Int` | `SockAddrRes` |
| `76` | `fn :: sock addr unix String` | `SockAddrRes` |
| `77` | `fn :: parse port str String` | `Int` |
| `78` | `fn :: parse bracketed ipv6 at String Int` | `SockAddrRes` |
| `79` | `fn :: parse bracketed ipv6 String` | `SockAddrRes` |
| `80` | `fn :: parse host port ipv4 at String Int` | `SockAddrRes` |
| `81` | `fn :: parse host port ipv4 String` | `SockAddrRes` |
| `82` | `fn :: sock parse addr String` | `SockAddrRes` |
| `83` | `fn :: empty addr` | `SockAddr` |
| `84` | `fn :: default sock opts` | `SockOpts` |
| `85` | `fn :: new socket Int String String` | `Socket` |
| `86` | `fn :: sock tcp` | `Socket` |
| `87` | `fn :: sock tcp6` | `Socket` |
| `88` | `fn :: sock udp` | `Socket` |
| `89` | `fn :: sock udp6` | `Socket` |
| `90` | `fn :: sock unix stream` | `Socket` |
| `91` | `fn :: sock unix dgram` | `Socket` |
| `92` | `fn :: sock set options Socket SockOpts` | `SockRes` |
| `93` | `fn :: sock set timeout Socket Int` | `SockRes` |
| `94` | `fn :: sock set tcp nodelay Socket Bool` | `SockRes` |
| `95` | `fn :: sock set broadcast Socket Bool` | `SockRes` |
| `96` | `fn :: sock set buf sizes Socket Int Int` | `SockRes` |
| `97` | `fn :: sock local addr Socket` | `SockAddrRes` |
| `98` | `fn :: sock peer addr Socket` | `SockAddrRes` |
| `99` | `fn :: sock shutdown Socket String` | `SockRes` |
| `100` | `fn :: sock poll Socket` | `SockPoll` |
| `101` | `fn :: bind unix marker SockAddr` | `()` |
| `102` | `fn :: sock bind Socket SockAddr` | `SockRes` |
| `103` | `fn :: sock listen Socket Int` | `SockRes` |
| `104` | `fn :: sock connect Socket SockAddr` | `SockRes` |
| `105` | `fn :: sock accept Socket` | `SockRes` |
| `106` | `fn :: sock connect pair Socket Socket` | `SockPairRes` |
| `107` | `fn :: sock close Socket` | `SockRes` |
| `108` | `fn :: sock send bytes Socket Tensor[U8]` | `SockRes` |
| `109` | `fn :: sock send all Socket Tensor[U8]` | `SockRes` |
| `110` | `fn :: sock pipe transfer Socket Socket` | `SockPairRes` |
| `111` | `fn :: sock recv bytes Socket Int` | `SockRecvBytesRes` |
| `112` | `fn :: sock recv exact Socket Int` | `SockRecvBytesRes` |
| `113` | `fn :: sock send str Socket String` | `SockRes` |
| `114` | `fn :: sock recv str from SockRecvBytesRes` | `SockRecvStrRes` |
| `115` | `fn :: sock recv str Socket Int` | `SockRecvStrRes` |
| `116` | `fn :: sock send to Socket Tensor[U8] SockAddr` | `SockRes` |
| `117` | `fn :: sock deliver dgram Socket Socket` | `SockPairRes` |
| `118` | `fn :: sock recv from Socket Int` | `SockRecvFromRes` |
| `119` | `fn :: encode be32 Int` | `Tensor[U8]` |
| `120` | `fn :: decode be32 Tensor[U8]` | `Int` |
| `121` | `fn :: sock send frame Socket Tensor[U8]` | `SockRes` |
| `122` | `fn :: unpack frame body Socket Tensor[U8] Int Int` | `SockRecvBytesRes` |
| `123` | `fn :: unpack frame buf Socket Tensor[U8] Int` | `SockRecvBytesRes` |
| `124` | `fn :: sock recv frame Socket Int` | `SockRecvBytesRes` |
| `125` | `fn :: find newline idx Tensor[U8] Int Int` | `Int` |
| `126` | `fn :: sock send line Socket String` | `SockRes` |
| `127` | `fn :: unpack line buf Socket Tensor[U8] Int Int` | `SockRecvStrRes` |
| `128` | `fn :: sock recv line Socket Int` | `SockRecvStrRes` |
| `129` | `fn :: sk raw byte Int` | `String` |
| `130` | `fn :: sk u64 le Int` | `String` |
| `131` | `fn :: sk decode u16 be String Int` | `Int` |
| `132` | `fn :: sk get u16 le Tensor[U8] Int` | `Int` |
| `133` | `fn :: sk get u16 be Tensor[U8] Int` | `Int` |
| `134` | `fn :: sk int opt Int` | `Tensor[U8]` |
| `135` | `fn :: is valid listen host String` | `Bool` |
| `136` | `fn :: sk ipv4 bytes String Bool` | `String` |
| `137` | `fn :: sk build sockaddr in String Int Bool` | `String` |
| `138` | `fn :: sk finish tcp listen Int Int Int` | `Int Int` |
| `139` | `fn :: sk apply reuseport Int Bool` | `Int` |
| `140` | `fn :: sk listen result Int` | `Int Int` |
| `141` | `fn :: sk listen ip String` | `String` |
| `142` | `fn :: sk exec tcp listen opt String Int Int Bool` | `Int Int` |
| `143` | `fn :: sk kernel tcp listen String Int Int Bool` | `Int Int` |
| `144` | `fn :: sk exec tcp listen String Int Int` | `Int Int` |
| `145` | `fn :: sk map setsockopt rc Int` | `Int` |
| `146` | `fn :: sys set reuseport Int Bool` | `Int` |
| `147` | `fn :: sys tcp listen opt String Int Int Bool` | `Int Int` |
| `148` | `fn :: sys tcp listen reuseport String Int Int` | `Int Int` |
| `149` | `fn :: sys tcp listen String Int Int` | `Int Int` |
| `150` | `fn :: sk finish unix listen Int Int Int` | `Int Int` |
| `151` | `fn :: sk exec unix listen String Int` | `Int Int` |
| `152` | `fn :: sk build sockaddr un String` | `Tensor[U8]` |
| `153` | `fn :: sys unix listen String Int` | `Int Int` |
| `154` | `fn :: sk extract local port Int Tensor[U8]` | `Int` |
| `155` | `fn :: sk socklen Int` | `Tensor[U8]` |
| `156` | `fn :: sk local port result Int` | `Int` |
| `157` | `fn :: sys local port Int` | `Int` |
| `158` | `fn :: sk finish connect Int Int` | `Int Int` |
| `159` | `fn :: sk exec tcp connect ip String Int` | `Int Int` |
| `160` | `fn :: sk connect result Int` | `Int Int` |
| `161` | `fn :: sk connect ip String` | `String` |
| `162` | `fn :: sk connect resolved (Int String) Int` | `Int Int` |
| `163` | `fn :: sys tcp connect String Int Int` | `Int Int` |
| `164` | `fn :: sys unix connect String Int` | `Int Int` |
| `165` | `fn :: sk decode acceptconn Int Tensor[U8]` | `Int` |
| `166` | `fn :: sk sock acceptconn Int` | `Int` |
| `167` | `fn :: sk format peer ip Tensor[U8]` | `String` |
| `168` | `fn :: sk finish accept Int Tensor[U8]` | `Int Int String` |
| `169` | `fn :: sk peer ip String` | `String` |
| `170` | `fn :: sk accept result Int` | `Int Int String` |
| `171` | `fn :: sk accept after poll Int Int` | `Int Int String` |
| `172` | `fn :: sys accept Int Int` | `Int Int String` |
| `173` | `fn :: sk clamp nonneg Int` | `Int` |
| `174` | `fn :: sk send rem ms Int Int` | `Int` |
| `175` | `fn :: sk send after rc Int Tensor[U8] String Int Int Int Int Int` | `Int Int` |
| `176` | `fn :: sk send after poll Int Tensor[U8] String Int Int Int Int Int` | `Int Int` |
| `177` | `fn :: sk send loop Int Tensor[U8] String Int Int Int Int` | `Int Int` |
| `178` | `fn :: sk send result Int Int` | `Int Int` |
| `179` | `fn :: sk net send Int String Int` | `Int Int` |
| `180` | `fn :: sk exec send Int String Int` | `Int Int` |
| `181` | `fn :: sys send Int String Int` | `Int Int` |
| `182` | `fn :: sys shutdown write Int` | `Int` |
| `183` | `fn :: sk wrap recv chunk String` | `Int String` |
| `184` | `fn :: sk recv result Tensor[U8] Int` | `Int String` |
| `185` | `fn :: sk net recv Int Int Int` | `Int String` |
| `186` | `fn :: sk recv after poll Int Int Int` | `Int String` |
| `187` | `fn :: sys recv Int Int Int` | `Int String` |
| `188` | `fn :: sock rc (Int Int)` | `Int` |
| `189` | `fn :: sock fd (Int Int)` | `Int` |
| `190` | `fn :: sock accept rc (Int Int String)` | `Int` |
| `191` | `fn :: sock accept fd (Int Int String)` | `Int` |
| `192` | `fn :: sock accept ip (Int Int String)` | `String` |
| `193` | `fn :: sock recv rc (Int String)` | `Int` |
| `194` | `fn :: sock recv data (Int String)` | `String` |

---

## 27.3. `socket` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `socket` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test socket.ridgun`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 27.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `socket` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `socket` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import socket

fn :: eco tcp local => String
      eco tcp local =
        sys tcp listen "127.0.0.1" 0 16 -> (_ +) -> lfd
        lfd sys local port -> port
        sys tcp connect "127.0.0.1" port 1000 -> (_ +) -> cfd
        sys accept lfd 1000 -> a_res
        a_res sock accept fd -> sfd
        sys send cfd "hola-solstice" 1000 -> ()
        sys recv sfd 64 1000 -> r_res
        r_res sock recv data -> datos
        sys close cfd -> ()
        sys close sfd -> ()
        sys close lfd -> ()
        datos
```

### 27.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`socket` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 38 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import socket

fn :: verificar ip interna String => Bool
      verificar ip interna ip =
        ip in cidr ip "10.0.0.0/8"
```

### 27.3.3. 3. adibidea: Helbide tipatuak (`IPv4`, `IPv6`, `Unix`), ataken baliozkotzea eta socket-en bizi-ziklo osoa (`sock listen`, `accept`, `connect`, `close`)

Adibide praktiko honetan `socket` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test sock address and lifecycle => ()
      test sock address and lifecycle =
        r_v4       = sock parse addr "127.0.0.1:8080"
        r_v6       = sock parse addr "[::1]:9090"
        r_ux       = sock parse addr "/tmp/ridgun_test.sock"
        b_ip       = sock parse addr "999.0.0.1:8080"
        b_prt      = sock addr ipv4 "127.0.0.1" 70000
        b_ux1      = sock parse addr "../unsafe.sock"
        b_ux2      = sock parse addr "/tmp/bad;rm.sock"
        is addr ok r_v4 -> assert ok
        is addr ok r_v6 -> assert ok
        is addr ok r_ux -> assert ok
        is addr ok b_ip -> assert eq False
        is addr ok b_prt -> assert eq False
        is addr ok b_ux1 -> assert eq False
        is addr ok b_ux2 -> assert eq False
        a_v4       = unwrap addr r_v4
        host a_v4 -> assert eq "127.0.0.1"
        port a_v4 -> assert eq 8080
        s0         = sock tcp
        s_to       = sock set timeout s0 2500
        s_neg      = sock set timeout s0 (-5)
        is sock ok s_to -> assert ok
        is sock ok s_neg -> assert eq False
        s1         = unwrap sock s_to
        timeout_ms (opts s1) -> assert eq 2500
        srv0       = unwrap sock (sock bind s1 a_v4)
        srv1       = unwrap sock (sock listen srv0 16)
        is_listening srv1 -> assert ok
        cli0       = unwrap sock (sock bind (sock tcp) (unwrap addr (sock parse addr "127.0.0.1:50000")))
        pair       = sock connect pair cli0 srv1
        cli1       = unwrap pair left pair
        peer1      = unwrap pair right pair
        is_connected cli1 -> assert ok
        is_connected peer1 -> assert ok
        closed_cli = unwrap sock (sock close cli1)
        is_open closed_cli -> assert eq False
        is sock ok (sock close closed_cli) -> assert eq False
        -- Additional family, option, and lifecycle negative edge cases
        is addr ok (sock parse addr "unix:/tmp/ridgun_prefixed.sock") -> assert ok
        is addr ok (sock addr ipv6 "::1" 8443) -> assert ok
        is addr ok (sock addr ipv6 "invalid_v6" 8443) -> assert eq False
        is addr ok (sock parse addr "/tmp/bad|pipe.sock") -> assert eq False
        is addr ok (sock parse addr "/tmp/bad$dollar.sock") -> assert eq False
        is addr ok (sock parse addr "/tmp/bad space.sock") -> assert eq False
        family (sock tcp6) -> assert eq "inet6"
        family (sock udp6) -> assert eq "inet6"
        family (sock unix stream) -> assert eq "unix"
        sock_type (sock unix dgram) -> assert eq "dgram"
        good_opts  = SockOpts True True True True False 1000 32768 32768
        bad_opts1  = SockOpts True False False False False (0 - 1) 32768 32768
        bad_opts2  = SockOpts True False False False False 1000 0 32768
        is sock ok (sock set options (sock tcp) good_opts) -> assert ok
        is sock ok (sock set options (sock tcp) bad_opts1) -> assert eq False
        is sock ok (sock set options (sock tcp) bad_opts2) -> assert eq False
        is sock ok (sock bind (sock tcp) (unwrap addr r_v6)) -> assert eq False
        is sock ok (sock listen (sock tcp) 8) -> assert eq False
        is sock ok (sock listen srv0 0) -> assert eq False
        is sock ok (sock listen (sock udp) 8) -> assert eq False
        is sock ok (sock accept srv0) -> assert eq False
        assert eq (is sock ok (sock connect (sock tcp) (unwrap addr r_ux))) False
```

### 27.3.4. 4. adibidea: Korronteen transferentzia (`sock send all`, `sock recv exact`), lerroak (`sock send line`, `sock recv line`), 32 biteko aurrizkidun bilbeak (`sock send frame`) eta UDP datagramak

Adibide praktiko honetan `socket` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test sock data transfer and framing => ()
      test sock data transfer and framing =
        srv_addr = unwrap addr (sock parse addr "127.0.0.1:8081")
        cli_addr = unwrap addr (sock parse addr "127.0.0.1:50001")
        srv      = unwrap sock (sock listen (unwrap sock (sock bind (sock tcp) srv_addr)) 8)
        cli      = unwrap sock (sock bind (sock tcp) cli_addr)
        pair0    = sock connect pair cli srv
        c0       = unwrap pair left pair0
        p0       = unwrap pair right pair0
        c1       = unwrap sock (sock send str c0 "hello ridgun")
        pair1    = sock pipe transfer c1 p0
        p1       = unwrap pair right pair1
        r_str    = sock recv str p1 64
        is recv str ok r_str -> assert ok
        unwrap recv str r_str -> assert eq "hello ridgun"
        p2       = unwrap recv str sock r_str
        c2       = unwrap sock (sock send frame (unwrap pair left pair1) (tb [10, 20, 30, 40]))
        pair2    = sock pipe transfer c2 p2
        p3       = unwrap pair right pair2
        r_frm_sm = sock recv frame p3 2
        is recv bytes ok r_frm_sm -> assert eq False
        r_frm_ok = sock recv frame p3 16
        is recv bytes ok r_frm_ok -> assert ok
        unwrap recv bytes r_frm_ok -> assert eq [10, 20, 30, 40]
        p4       = unwrap recv bytes sock r_frm_ok
        c3       = unwrap sock (sock send line (unwrap pair left pair2) "PING 1")
        pair3    = sock pipe transfer c3 p4
        p5       = unwrap pair right pair3
        r_line   = sock recv line p5 32
        is recv str ok r_line -> assert ok
        unwrap recv str r_line -> assert eq "PING 1"
        p6       = unwrap recv str sock r_line
        u_sender = unwrap sock (sock bind (sock udp) cli_addr)
        u_rcvr   = unwrap sock (sock bind (sock udp) srv_addr)
        u_sent   = unwrap sock (sock send to u_sender (tb [1, 2, 3]) srv_addr)
        d_pair   = sock deliver dgram u_sent u_rcvr
        u_rcvr2  = unwrap pair right d_pair
        d_res    = sock recv from u_rcvr2 16
        unwrap dgram payload d_res -> assert eq [1, 2, 3]
        port (unwrap dgram sender d_res) -> assert eq 50001
        -- Byte round trip through the in-memory stream: 0, 128 and 255 survive (ADR-0010)
        c_bin    = unwrap sock (sock send bytes c0 (tb [0, 128, 255, 10, 0]))
        p_bin    = unwrap pair right (sock pipe transfer c_bin p0)
        r_bin    = sock recv bytes p_bin 3
        is recv bytes ok r_bin -> assert ok
        unwrap recv bytes r_bin -> assert eq [0, 128, 255]
        r_bin2   = sock recv exact (unwrap recv bytes sock r_bin) 2
        unwrap recv bytes r_bin2 -> assert eq [10, 0]
        decode be32 (encode be32 4278255360) -> assert eq 4278255360
        tensor to list (encode be32 258) -> assert eq [0, 0, 1, 2]
        decode be32 (tb [1, 2]) -> assert eq (0 - 1)
        c_bfrm   = unwrap sock (sock send frame c0 (tb [255, 0, 128]))
        p_bfrm   = unwrap pair right (sock pipe transfer c_bfrm p0)
        unwrap recv bytes (sock recv frame p_bfrm 16) -> assert eq [255, 0, 128]
        -- Additional framing, line and datagram negative edge cases
        c_short  = unwrap sock (sock send bytes (unwrap pair left pair3) (tb [0, 1]))
        p_short  = unwrap pair right (sock pipe transfer c_short p6)
        is recv bytes ok (sock recv frame p_short 16) -> assert eq False
        is recv str ok (sock recv line p_short 16) -> assert eq False
        c_longl  = unwrap sock (sock send line (unwrap pair left pair3) "LINE_TOO_LONG_FOR_LIMIT")
        p_longl  = unwrap pair right (sock pipe transfer c_longl (unwrap recv bytes sock (sock recv bytes p_short 2)))
        is recv str ok (sock recv line p_longl 4) -> assert eq False
        assert eq (is sock ok (sock send to c0 (tb [1, 2]) srv_addr)) False
```

### 27.3.5. 5. adibidea: Socket-aukerak (`NODELAY`, `KEEPALIVE`), CIDR azpisareak (`ip in cidr`), DNS ebazpena (`sock resolve host`) eta `sock poll` multiplexazioa

Adibide praktiko honetan `socket` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test sock advanced ops dns cidr and polling => ()
      test sock advanced ops dns cidr and polling =
        srv_addr  = unwrap addr (sock resolve host "localhost" 8082)
        cli_addr  = unwrap addr (sock resolve host "api.example.com" 50002)
        bad_host  = sock resolve host "-bad..host" 8082
        host srv_addr -> assert eq "127.0.0.1"
        port srv_addr -> assert eq 8082
        is addr ok bad_host -> assert eq False
        ip in cidr "192.168.1.42" "192.168.1.0/24" -> assert ok
        ip in cidr "192.168.2.42" "192.168.1.0/24" -> assert eq False
        ip in cidr "10.20.30.40" "10.0.0.0/8" -> assert ok
        ip in cidr "10.20.30.40" "10.0.0.0/99" -> assert eq False
        s_nd      = sock set tcp nodelay (sock tcp) True
        s_bc      = sock set broadcast (sock udp) True
        s_buf_ok  = sock set buf sizes (sock tcp) 131072 131072
        s_buf_bad = sock set buf sizes (sock tcp) 0 1024
        is sock ok s_nd -> assert ok
        is sock ok s_bc -> assert ok
        is sock ok s_buf_ok -> assert ok
        is sock ok s_buf_bad -> assert eq False
        tcp_nodelay (opts (unwrap sock s_nd)) -> assert ok
        broadcast (opts (unwrap sock s_bc)) -> assert ok
        rcvbuf (opts (unwrap sock s_buf_ok)) -> assert eq 131072
        srv       = unwrap sock (sock listen (unwrap sock (sock bind (sock tcp) srv_addr)) 8)
        cli       = unwrap sock (sock bind (sock tcp) cli_addr)
        pair0     = sock connect pair cli srv
        c0        = unwrap pair left pair0
        p0        = unwrap pair right pair0
        port (unwrap addr (sock local addr c0)) -> assert eq 50002
        port (unwrap addr (sock peer addr c0)) -> assert eq 8082
        poll0     = sock poll p0
        readable poll0 -> assert eq False
        writable poll0 -> assert ok
        c1        = unwrap sock (sock send all c0 (tb [5, 6, 7, 8, 9]))
        pair1     = sock pipe transfer c1 p0
        p1        = unwrap pair right pair1
        poll1     = sock poll p1
        readable poll1 -> assert ok
        ex_fail   = sock recv exact p1 10
        is recv bytes ok ex_fail -> assert eq False
        ex_ok     = sock recv exact p1 5
        is recv bytes ok ex_ok -> assert ok
        unwrap recv bytes ex_ok -> assert eq [5, 6, 7, 8, 9]
        c_shut_wr = unwrap sock (sock shutdown (unwrap pair left pair1) "wr")
        is sock ok (sock send bytes c_shut_wr (tb [1])) -> assert eq False
        p_shut_rd = unwrap sock (sock shutdown p1 "rd")
        is recv bytes ok (sock recv bytes p_shut_rd 4) -> assert eq False
        c_shut_all = unwrap sock (sock shutdown p1 "rdwr")
        can_read c_shut_all -> assert eq False
        can_write c_shut_all -> assert eq False
        is sock ok (sock shutdown p1 "bad_mode") -> assert eq False
        is addr ok (sock resolve host "ip6-localhost" 9090) -> assert ok
        ip in cidr "203.0.113.5" "0.0.0.0/0" -> assert ok
        ip in cidr "192.168.1.1" "192.168.1.1/32" -> assert ok
        ip in cidr "192.168.1.2" "192.168.1.1/32" -> assert eq False
        is addr ok (sock local addr (sock tcp)) -> assert eq False
        assert eq (is addr ok (sock peer addr (sock tcp))) False
```

### 27.3.6. 6. adibidea: Linux x86_64 kerneleko benetako socket-ak (RGF-001): begizta lokaleko (`127.0.0.1`) TCP bezero/zerbitzaria eta Unix domeinuko socket-ak (`AF_UNIX`)

Adibide praktiko honetan `socket` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test sock rgf001 kernel tcp and unix => ()
      test sock rgf001 kernel tcp and unix =
        -- 1. Ephemeral TCP listen + sys_local_port + ADDR_IN_USE + invalid/permission checks
        tup2 fst (sys tcp listen "bad_host" 8080 16) -> assert int equals (0 - 7) "invalid host -> -7"
        tup2 fst (sys tcp listen "127.0.0.1" 70000 16) -> assert int equals (0 - 7) "invalid port -> -7"
        tup2 fst (sys tcp listen "127.0.0.1" 8080 0) -> assert int equals (0 - 7) "invalid backlog -> -7"
        tup2 fst (sys tcp listen "127.0.0.1" 80 16) -> assert int equals (0 - 6) "privileged port 80 -> -6"
        l_res  = sys tcp listen "127.0.0.1" 0 16
        tup2 fst l_res -> assert int equals 0 "sys_tcp_listen status"
        lfd    = tup2 snd l_res
        lfd >= 0 -> assert true "lfd >= 0"
        (sys call (nr fcntl) lfd 1 0 0 0 0) >= 0 -> assert true "lfd is real kernel fd (fcntl F_GETFD >= 0)"
        lport  = sys local port lfd
        lport > 0 -> assert true "ephemeral port > 0"
        dup_l  = sys tcp listen "127.0.0.1" lport 8
        tup2 fst dup_l -> assert int equals (0 - 5) "dup sys_tcp_listen -> -5"

        -- 1b. Real DNS resolution (/etc/hosts + RFC 1035 wire packet parser + localhost + literal IP + hostname connect)
        r_loc  = sys resolve ipv4 "localhost"
        tup2 rc r_loc -> assert int equals 0 "sys_resolve_ipv4 localhost ok"
        tup2 str r_loc -> assert str eq "127.0.0.1" "sys_resolve_ipv4 localhost -> 127.0.0.1"
        r_bad  = sys resolve ipv4 "-bad..host"
        tup2 rc r_bad -> assert int equals (0 - 7) "sys_resolve_ipv4 invalid hostname -> -7"
        dns_q  = sk build dns query "example.com"
        str len dns_q -> assert int equals 29 "RFC 1035 DNS query length for example.com == 29"
        -- Construct an RFC 1035 DNS response packet with 1 A record (93.184.216.34) using 0xC00C name compression
        dns_hd = (sk raw byte 18) + (sk raw byte 52) + (sk raw byte 129) + (sk raw byte 128) + (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0)
        dns_qn = sk encode qname ["example", "com"]
        dns_qt = (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 1)
        dns_an = (sk raw byte 192) + (sk raw byte 12) + (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 60) + (sk raw byte 0) + (sk raw byte 4) + (sk raw byte 93) + (sk raw byte 184) + (sk raw byte 216) + (sk raw byte 34)
        dns_ip = sk extract dns ipv4 (dns_hd + dns_qn + dns_qt + dns_an)
        dns_ip -> assert str eq "93.184.216.34" "sk_extract_dns_ipv4 parses RFC 1035 A record (93.184.216.34)"
        c_host = sys tcp connect "localhost" lport 500
        tup2 fst c_host -> assert int equals 0 "sys_tcp_connect via hostname localhost ok"
        a_host = sys accept lfd 500
        tup3 rc a_host -> assert int equals 0 "sys_accept from hostname connect ok"
        sys close (tup2 snd c_host) -> assert int equals 0 "close c_host"
        sys close (tup3 fd a_host) -> assert int equals 0 "close a_host"

        -- 2. Accept timeout (-2) when no client pending + connect refused (-3) on unbound port
        acc_to = sys accept lfd 30
        tup3 rc acc_to -> assert int equals (0 - 2) "sys_accept timeout -> -2"
        ref_c  = sys tcp connect "127.0.0.1" 39999 100
        tup2 fst ref_c -> assert int equals (0 - 3) "sys_tcp_connect refused -> -3"

        -- 3. TCP multi-client queue, bidirectional I/O, chunked recv, recv timeout (-2), shutdown_write, send after shutdown (-4), EOF (-1)
        c_res  = sys tcp connect "127.0.0.1" lport 500
        c_res2 = sys tcp connect "127.0.0.1" lport 500
        tup2 fst c_res -> assert int equals 0 "sys_tcp_connect 1 ok"
        tup2 fst c_res2 -> assert int equals 0 "sys_tcp_connect 2 ok"
        cfd    = tup2 snd c_res
        cfd2   = tup2 snd c_res2
        a_res  = sys accept lfd 500
        a_res2 = sys accept lfd 500
        tup3 rc a_res -> assert int equals 0 "sys_accept 1 ok"
        tup3 rc a_res2 -> assert int equals 0 "sys_accept 2 ok"
        sfd    = tup3 fd a_res
        sfd2   = tup3 fd a_res2

        -- Empty recv with timeout=20 returns (-2, "")
        rcv_to = sys recv sfd 16 20
        tup2 rc rcv_to -> assert int equals (0 - 2) "sys_recv timeout on idle stream -> -2"

        -- Chunked recv: send 10 bytes, read 4 + 4 + 2 bytes, plus reverse direction sfd -> cfd
        snd1   = sys send cfd "0123456789" 500
        tup2 fst snd1 -> assert int equals 0 "sys_send status"
        tup2 snd snd1 -> assert int equals 10 "sys_send len 10"
        ch1    = sys recv sfd 4 500
        ch2    = sys recv sfd 4 500
        ch3    = sys recv sfd 4 500
        tup2 str ch1 -> assert str eq "0123" "chunk 1 (4B)"
        tup2 str ch2 -> assert str eq "4567" "chunk 2 (4B)"
        tup2 str ch3 -> assert str eq "89" "chunk 3 (2B)"
        tup2 fst (sys send sfd "pong" 500) -> assert int equals 0 "server->client send ok"
        tup2 str (sys recv cfd 16 500) -> assert str eq "pong" "client recv pong"

        -- Raw binary bytes (0, 1, 127, 128, 254, 255) + AEAD ciphertext over TCP sys_send/sys_recv
        raw_bin = bytes from list [0, 1, 127, 128, 254, 255]
        str len raw_bin -> assert int equals 6 "raw_bin len == 6"
        tup2 fst (sys send cfd2 raw_bin 500) -> assert int equals 0 "sys_send raw binary ok"
        r_bin   = tup2 str (sys recv sfd2 16 500)
        str len r_bin -> assert int equals 6 "raw binary recv len == 6"
        str char at r_bin 0 -> assert int equals 0 "raw binary byte[0] == 0"
        str char at r_bin 1 -> assert int equals 1 "raw binary byte[1] == 1"
        str char at r_bin 3 -> assert int equals 128 "raw binary byte[3] == 128"
        str char at r_bin 5 -> assert int equals 255 "raw binary byte[5] == 255"
        k32     = sha256 bytes "socket-session-key"
        n12     = "0123456789ab"
        ct_wire = aead seal k32 n12 "tcp-aad" "confidential-payload-over-tcp"
        tup2 fst (sys send cfd2 ct_wire 500) -> assert int equals 0 "sys_send AEAD ciphertext ok"
        rx_wire = tup2 str (sys recv sfd2 128 500)
        opened  = aead open k32 n12 "tcp-aad" rx_wire
        tup2 rc opened -> assert int equals 0 "aead_open over TCP socket ok"
        tup2 str opened -> assert str eq "confidential-payload-over-tcp" "decrypted TCP payload matches"

        -- Shutdown write -> subsequent send returns (-4, -1) RESET, peer recv returns (-1, "") EOF
        sys shutdown write cfd -> assert int equals 0 "sys_shutdown_write"
        tup2 fst (sys send cfd "after-shut" 100) -> assert int equals (0 - 4) "send after shutdown_write -> -4"
        rcv_ef = sys recv sfd 64 500
        tup2 rc rcv_ef -> assert int equals (0 - 1) "sys_recv EOF -> -1"
        sys close cfd -> assert int equals 0 "sys_close cfd"
        sys close sfd -> assert int equals 0 "sys_close sfd"
        sys close cfd2 -> assert int equals 0 "sys_close cfd2"
        sys close sfd2 -> assert int equals 0 "sys_close sfd2"
        sys close lfd -> assert int equals 0 "sys_close lfd"

        -- Operations on closed fd return -7 (INVALID)
        sys local port lfd -> assert int equals (0 - 7) "sys_local_port on closed lfd -> -7"
        tup3 rc (sys accept lfd 10) -> assert int equals (0 - 7) "sys_accept on closed lfd -> -7"
        tup2 fst (sys send cfd "x" 10) -> assert int equals (0 - 7) "sys_send on closed cfd -> -7"
        tup2 rc (sys recv sfd 16 10) -> assert int equals (0 - 7) "sys_recv on closed sfd -> -7"

        -- 4. AF_UNIX listen + connect + send + recv + path traversal (-7) + missing listener (-3)
        u_bad  = sys unix listen "../traversal.sock" 8
        tup2 fst u_bad -> assert int equals (0 - 7) "sys_unix_listen traversal -> -7"
        tup2 fst (sys unix connect "/tmp/rg_nonexistent_99999.sock" 50) -> assert int equals (0 - 3) "sys_unix_connect missing -> -3"
        pid    = sys getpid
        upath  = "/tmp/rg_sock_rgf001_{pid}.sock"
        ul_res = sys unix listen upath 8
        tup2 fst ul_res -> assert int equals 0 "sys_unix_listen ok"
        ulfd   = tup2 snd ul_res
        uc_res = sys unix connect upath 500
        tup2 fst uc_res -> assert int equals 0 "sys_unix_connect ok"
        ucfd   = tup2 snd uc_res
        ua_res = sys accept ulfd 500
        tup3 rc ua_res -> assert int equals 0 "sys_accept unix ok"
        usfd   = tup3 fd ua_res
        tup2 fst (sys send ucfd "unix-msg" 500) -> assert int equals 0 "sys_send unix ok"
        urcv   = sys recv usfd 64 500
        tup2 rc urcv -> assert int equals 0 "sys_recv unix ok"
        tup2 str urcv -> assert str eq "unix-msg" "AF_UNIX sys_recv"
        sys close ucfd -> assert int equals 0 "sys_close ucfd"
        sys close usfd -> assert int equals 0 "sys_close usfd"
        sys close ulfd -> assert int equals 0 "sys_close ulfd"
        shell exec "rm -f '{upath}'" -> assert int equals 0 "unlink AF_UNIX socket"

        -- 5. RG-049: sys_send honours timeout_ms when peer never reads (8 MiB send with timeout_ms=1000)
        tl_res = sys tcp listen "127.0.0.1" 0 8
        tlfd   = tup2 snd tl_res
        tlport = sys local port tlfd
        tc_res = sys tcp connect "127.0.0.1" tlport 500
        tcfd   = tup2 snd tc_res
        ta_res = sys accept tlfd 500
        tsfd   = tup3 fd ta_res
        big8m  = str repeat "x" 8000000
        ts0    = sys time ms
        tsnd   = sys send tsfd big8m 1000
        ts1    = sys time ms
        dt_ms  = ts1 - ts0
        tup2 fst tsnd -> assert int equals (0 - 2) "RG-049: sys_send 8 MiB to non-reading peer times out -> -2"
        (tup2 snd tsnd) > 0 -> assert true "RG-049: sys_send returns partial bytes sent > 0 on timeout"
        dt_ms >= 800 and dt_ms <= 2500 -> assert true "RG-049: sys_send timeout elapsed ~1000 ms"
        sys close tcfd -> assert int equals 0 "sys_close tcfd"
        sys close tsfd -> assert int equals 0 "sys_close tsfd"
        sys close tlfd -> assert int equals 0 "sys_close tlfd"

        -- 6. Wish (multi-core): SO_REUSEPORT allows two TCP listeners on the same (ip, port)
        rp1    = sys tcp listen reuseport "127.0.0.1" 0 16
        tup2 fst rp1 -> assert int equals 0 "sys_tcp_listen_reuseport 1 ok"
        rp_fd1 = tup2 snd rp1
        rp_prt = sys local port rp_fd1
        rp2    = sys tcp listen reuseport "127.0.0.1" rp_prt 16
        tup2 fst rp2 -> assert int equals 0 "sys_tcp_listen_reuseport 2 on same port ok"
        rp_fd2 = tup2 snd rp2
        sys close rp_fd1 -> assert int equals 0 "sys_close rp_fd1"
        sys close rp_fd2 -> assert int equals 0 "sys_close rp_fd2"
        ()
```

---

## 27.4. Kaputaren azpian: nola dagoen eraikia `socket` Ridgun hutsean (`src/main/ridgun/lib/socket.ridgun`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/socket.ridgun` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 27.4.1. Barne-inplementazioa: RGF-001 Tuple Accessor Helpers

Ikusi nola `socket.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
module :: socket

fn :: sock rc (Int Int) => Int
      sock rc (rc, _)   =  rc

fn :: sock fd (Int Int) => Int
      sock fd (_, fd)   =  fd

fn :: sock accept rc (Int Int String) => Int
      sock accept rc (rc, _, _)       =  rc

fn :: sock accept fd (Int Int String) => Int
      sock accept fd (_, fd, _)       =  fd

fn :: sock accept ip (Int Int String) => String
      sock accept ip (_, _, ip)       =  ip

fn :: sock recv rc (Int String) => Int
      sock recv rc (rc, _)      =  rc

fn :: sock recv data (Int String) => String
      sock recv data (_, data)    =  data
```

---

## 27.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `socket`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Erregistroen eguneratzea `s with field = val` sintaxi aldaezinarekin, `glibc`/`libnss` gabeko DNS ebazpena eta egoera-kode deterministak (`0` OK, `-1` EOF, `-2` TIMEOUT, `-3` REFUSED).
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/socket.ridgun`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test socket.ridgun` suite automatizatuaren bidez.

### `socket`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import socket` fitxategiaren hasieran** eta deitu bere funtzioei zuriuneekin, deklaratuta dauden bezala, zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `socket`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `socket`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `socket` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**28. kapituluan** **`http`** lib-a sakonki esploratuko dugu (`http` lib-a — RFC 3986 URIak, RFC 9112 HTTP/1.1 Kodeka eta Zuzeneko TCP Bezeroa).
