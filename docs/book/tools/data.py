"""What the book shows, independent of the language: chapters, source sections, examples, table rows, corrected names.
The text in each language is in strings/<lang>.json, under the keys named here."""
DOMAIN={'hash':'HASH','hashmap':'HASHMAP','tls':'TLS','mail':'MAIL'}
NEW_CHAPTERS=[('35','hash'),('36','hashmap'),('37','tls'),('38','mail')]

# Internals: ('sec', banner title prefix) or ('rng', title, first line prefix, last definition prefix)
INTERNALS={
 'crypto':[('sec','RGF-019 Raw Byte Manipulation'),('sec','RFC 8439 ChaCha20 Stream Cipher'),('sec','RFC 8439 Poly1305 One-Time Authenticator'),
           ('rng','SHA-256 on Processor Operations: a Block, the HMAC Step of PBKDF2 and the Loops','arch :: sha256 block','fn :: sha256 absorb'),
           ('sec','AES on processor operations'),
           ('rng','Montgomery Multiplication for Odd Moduli (`bn mont mul`, `bn mont pow`, `bn mod exp`)','fn :: bn mont loop','fn :: bn mod exp ')],
 'argon2id':[('sec','Byte (Tensor[U8], ADR-0010)'),('sec','Pure-Ridgun RFC 7693 BLAKE2b-512'),
           ('rng','The Blamka Permutation on Whole Tensors and the Compression Function G (RFC 9106 §3.5-3.6)','fn :: a2 lane ids','fn :: a2 compress blk8 bxor'),
           ('sec','Presets, Salt Generation, Key Derivation')],
 'json':[('sec','Whitespace, Raw Byte & Character Helpers'),('sec','RFC 8259 §6 Number Parsing'),('sec','Serialization & Pretty-Printing'),('sec','Dot-Path Queries & Field Updates')],
 'jwt':[('sec','Tensor[U8] Byte & Base64url Helpers'),('sec','Constant-Time Equality'),('sec','HS256 (HMAC-SHA256) Signing & Verification'),('sec','Structured Claims Signing & Temporal Validation')],
 'ws':[('sec','Byte Helpers'),('sec','Tensor[U8] Byte Helpers'),('sec','Base64 for the RFC 6455 Handshake'),('sec','RFC 6455 XOR Masking & Frame Encoding / Decoding')],
 'posix':[('sec','Poll & Process Status ADTs'),('sec','Path Safety Validation'),('sec','RG-010 Filesystem & Process Operations'),('sec','Durable File Sync, Truncate, Lock & Positional Read'),('sec','Ridgun v0.9.5 Target OS / Arch & Process Probe Helpers')],
 'pool':[('sec','Worker pool (FR-POOL-001 AC1 to AC7)'),('sec','Routing by key over a list of agents')],
 'net_agent':[('sec','Accepting (AC1, AC2)'),('sec','Reading, sending and the limits (AC3, AC5, AC6, AC7, AC8)'),('sec','One turn (AC9)'),('sec','Stop (AC11)')],
 'hash':[('rng','SipRound on 32-Bit Halves: One Message Word per Turn','fn :: hs byte','fn :: siphash13 loop'),
         ('rng','Public API: `siphash13`, the Plain-Ridgun Reference, and Random Keys','fn :: siphash13 start','fn :: hs key of')],
 'hashmap':[('sec','Hash'),('sec','Slots'),('sec','Table')],
 'tls':[('sec','Configuration (API-TLS-001)'),('sec','Record layer: AEAD'),('sec','Certificate chain validation'),('sec','TLS 1.3 key schedule')],
 'mail':[('sec','Message construction'),('sec','Address validation'),('sec','Bodies: quoted-printable'),('sec','Rendering (FR-MAIL-001 AC1)')],
}
# Examples added for test functions the book did not show: (string key, start of the test signature)
NEW_EXAMPLES={
 'list':[('sort','fn :: test list sort by key '),('group','fn :: test list count and group by ')],
 'json':[('rg076','fn :: test rg076 '),('rg077','fn :: test rg077 '),('rg078','fn :: test rg078 '),('numbers','fn :: test json numbers utf8 and find field ')],
 'fmt':[('sig','fn :: test fmt signature aware fn and op highlighting ')],
 'posix':[('fork','fn :: test posix fork pipe dup2 execve waitpid '),('durable','fn :: test posix durable file ops '),('bridge','fn :: test posix kernel bridge ')],
 'crypto':[('sha1','fn :: test sha1 fips vectors '),('sha512','fn :: test sha512 fips vectors '),('ed25519','fn :: test ed25519 rfc8032 vectors and negatives '),
           ('minisign','fn :: test minisign roundtrip and tamper '),('tls13','fn :: test sha384 hkdf x25519 aes128gcm '),('p256','fn :: test p256 p384 rsa and x509 '),
           ('edge','fn :: test crypto006 edge cases and certs '),('md5','fn :: test md5 rfc1321 vectors '),
           ('cpusha','fn :: test sha256 and pbkdf2 on processor operations '),('cpuaes','fn :: test aes on processor operations ')],
 'linalg':[('sqrt','fn :: test sqrt and exp ')],
 'jwt':[('bytes','fn :: test jwt bytes and utf8 round trip '),('vectors','fn :: test jwt standard vectors ')],
 'ws':[('large','fn :: test ws large frame round trip ')],
 'pool':[('routing','fn :: test pool routing by key '),('jobs','fn :: test pool takes jobs and refuses when full '),('limits','fn :: test pool size limits '),('edges','fn :: test pool routing edge cases ')],
 'net_agent':[('accept','fn :: test reactor accepts and refuses '),('messages','fn :: test reactor input messages and state '),('slow','fn :: test reactor output and the peer that does not read '),('limits','fn :: test reactor time limits '),('wait','fn :: test reactor waits on everything at once '),('stop','fn :: test reactor stop ')],
 'hash':[('vectors','fn :: test siphash13 vectors '),('native','fn :: test native matches reference ')],
 'hashmap':[('basics','fn :: test hashmap basics '),('add','fn :: test hashmap add '),('keys','fn :: test hashmap unusual keys '),('records','fn :: test hashmap record values '),('growth','fn :: test hashmap growth ')],
 'tls':[('rfc8448','fn :: test rfc8448 vectors '),('prf','fn :: test tls12 prf and hello '),('chain','fn :: test chain verification '),('local','fn :: test local handshakes '),('failures','fn :: test local failures '),('live','fn :: test live servers ')],
 'mail':[('basics','fn :: test render basics '),('encoding','fn :: test render encoding '),('rejects','fn :: test render rejects '),('parse','fn :: test parse response '),('local','fn :: test smtp local '),('live','fn :: test smtp live ')],
}
# Rows of the functional-families table: code column here, purpose in strings as fam.<lib>.<key>
FAMILIES={
 'hash':[('siphash13','`siphash13`'),('range','`siphash13 range / siphash13 range low`'),('reference','`siphash13 reference`'),('newkey','`siphash new key`')],
 'hashmap':[('empty','`hashmap empty`'),('put','`hashmap put / hashmap get / hashmap has`'),('add','`hashmap add`'),('pairs','`hashmap size / hashmap pairs`')],
 'tls':[('config','`tls defaults / tls with roots / tls with root pem / tls with alpn / tls with timeout / tls with versions`'),('connect','`tls connect host / tls connect addr / tls connect`'),
        ('io','`tls send / tls recv / tls close`'),('result','`tls is ok / tls unwrap / tls error kind / tls error reason`'),('verify','`tls verify chain / tls valid sni`')],
 'mail':[('build','`mail message / mail with html / mail with reply to / mail add to / mail with date / mail with message id`'),('render','`mail render / mail is ok / mail unwrap / mail error`'),
         ('encode','`mail valid address / mail encode rfc2047 / mail qp encode / mail format date`'),('config','`smtp config / smtp with tls / smtp with auth / smtp with timeout`'),
         ('send','`smtp send / smtp is ok / smtp is retryable / smtp error kind / smtp error reason`')],
}
# Rows appended to the families table of chapters that already exist
FAMILIES_ADD={
 'crypto':[('sha1md5','`sha1 bytes / sha1 hex / md5 bytes / md5 hex`'),('hkdf','`sha384 bytes / hmac sha384 / hkdf extract / hkdf expand / hkdf expand label`'),('x25519','`x25519 / x25519 public key`'),
           ('aesgcm','`aes128 gcm seal / aes128 gcm open / aes256 gcm seal / aes256 gcm open`'),('ecrsa','`p256 public key / p256 ecdh / ecdsa p256 verify / ecdsa p384 verify / rsa verify pkcs1 / rsa verify pss`'),
           ('x509','`x509 parse cert / x509 match hostname / x509 verify cert sig`')],
 'posix':[('mkdirall','`posix mkdir all`'),('durable','`posix fsync / posix fdatasync / posix ftruncate / posix lock exclusive / posix pread`'),('process','`posix fork / posix pipe / posix dup2 / posix execve / posix waitpid`')],
 'list':[('sortgroup','`list sort by int / list sort by text / list count by / list group by`')],
}
HAND={
 'hash':['''import hash

fn :: cubo de clave String String Int => Int
      cubo de clave semilla clave cubos =
        siphash13 range low semilla clave 0 (str len clave) -> h
        h % cubos
''','''import hash

fn :: huella segura String String => Int
      huella segura semilla dato =
        | (str len semilla) != 16 = 0
        | otherwise               = siphash13 semilla dato
'''],
 'hashmap':['''import hashmap

fn :: contar visitas [String]     (HashMap Int) => HashMap Int
      contar visitas []           m             =  m
      contar visitas (ruta:resto) m             =  contar visitas resto (hashmap add m ruta 1)
''','''import hashmap

fn :: visitas de (HashMap Int) String => Int
      visitas de m ruta =
        | hashmap has m ruta = hashmap get m ruta 0
        | otherwise          = 0
'''],
 'tls':['''import tls

fn :: leer cabecera TlsResult String => String
      leer cabecera r host =
        | tls is ok r = pedir cabecera (tls unwrap r) host
        | otherwise   = (tls error kind r) + ": " + (tls error reason r)

fn :: pedir cabecera TlsConn String => String
      pedir cabecera conn host =
        tls send conn ("HEAD / HTTP/1.1\\r\\nHost: " + host + "\\r\\nConnection: close\\r\\n\\r\\n") -> enviados
        tls recv conn 4096 -> respuesta
        tls close conn
        respuesta

fn :: cabecera https String => String
      cabecera https host =
        leer cabecera (tls connect host host 443 (tls defaults)) host
''','''import tls

fn :: conviene reintentar TlsResult => Bool
      conviene reintentar r =
        | tls is ok r                        = False
        | (tls error kind r) == "TlsTimeout" = True
        | (tls error kind r) == "TlsIoError" = True
        | otherwise                          = False
'''],
 'mail':['''import mail

fn :: correo de verificacion String String => MailMessage
      correo de verificacion destino enlace =
        mail message "Ridgun <noreply@ridgun.com>" destino "Verifica tu cuenta" ("Abre este enlace: " + enlace) -> m
        mail with reply to m "soporte@ridgun.com"
''','''import mail

fn :: motivo de envio SmtpResult => String
      motivo de envio r =
        | smtp is ok r        = "enviado"
        | smtp is retryable r = "reintentar: " + (smtp error reason r)
        | otherwise           = (smtp error kind r) + ": " + (smtp error reason r)

fn :: enviar correo SmtpConfig MailMessage => String
      enviar correo cfg msg =
        motivo de envio (smtp send cfg msg)
'''],
}
# Phrases repeated in every chapter that no longer hold (per language): (regex, replacement)
COMMON={
 'en':[(r'it compiles into three native artifacts:','it compiles into one native artifact:'),
       (r'and take advantage of space/underscore equivalence so your code reads like natural prose\.','and call its functions with spaces, exactly as they are declared, so your code reads like natural prose.')],
 'es':[(r'se empaqueta en tres artefactos nativos:','se empaqueta en un artefacto nativo:'),
       (r'y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa\.','y llama a sus funciones con espacios, tal como están declaradas, para que tu código se lea como prosa.')],
 'ca':[(r"s'empaqueta en tres formats natius:","s'empaqueta en un format natiu:"),
       (r"i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa\.","i crida les seves funcions amb espais, tal com estan declarades, perquè el teu codi es llegeixi com a prosa.")],
 'gl':[(r'empaquétase en tres formatos nativos:','empaquétase nun formato nativo:'),
       (r'e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa\.','e chama as súas funcións con espazos, tal como están declaradas, para que o teu código se lea coma prosa.')],
 'eu':[(r'hiru formatu natibotan paketatzen da:','formatu natibo bakarrean paketatzen da:'),
       (r'eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin\.','eta deitu bere funtzioei zuriuneekin, deklaratuta dauden bezala, zure kodea prosa bezala irakur dadin.')],
 'pt':[(r'é empacotada em três formatos nativos:','é empacotada num formato nativo:'),
       (r'e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa\.','e chame as suas funções com espaços, tal como estão declaradas, para que o seu código se leia como prosa.')],
 'sv':[(r'paketeras den i tre inbyggda format:','paketeras den i ett inbyggt format:'),
       (r'och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa\.','och anropa dess funktioner med mellanslag, precis som de är deklarerade, så att koden läses som naturlig prosa.')],
 'it':[(r'viene impacchettata in tre artefatti nativi:','viene impacchettata in un artefatto nativo:')],
}

# Whole families table rewritten (the old one named functions that do not exist)
FAMILIES_REPLACE={
 'tensor':[('shape','`tensor rows / tensor cols / tensor shape`'),('rowcol','`tensor row / tensor col`'),('clone','`tensor clone`'),('matmul','`tensor matmul`'),
           ('blocks','`tensor bitxor blocks / tensor bitand blocks / tensor bitor blocks / tensor add blocks / tensor sub blocks / tensor mul blocks`')],
 'btree':[('map','`btree empty / btree put / btree get / btree get or / btree has / btree remove`'),('order','`btree size / btree keys / btree values / btree to list / btree from list`'),
          ('set','`bset empty / bset add / bset has / bset remove / bset union / bset intersect / bset diff`'),('heap','`heap empty / heap push / heap peek / heap pop / heap size`')],
 'fmt':[('source','`format ridgun source / fmt source with config`'),('config','`default fmt config / fmt config`'),
        ('targets','`fmt to tty / fmt to truecolor / fmt to html / fmt to html css / fmt to markdown / fmt to pango / fmt to latex / fmt to rtf`'),('highlight','`fmt highlight line / fmt highlight lines`')],
 'posix':[('flags','`o rdonly / o wronly / o rdwr / o creat / o trunc / o append / o nonblock / o cloexec`'),('wait','`wait fd`'),('clock','`sys monotonic ms / sys monotonic ns`'),
          ('signal','`sys signal watch / sys signal wait / posix notify signal`'),('random','`sys random bytes / sys random tensor`'),('fd','`posix open / posix read / posix write / posix close`'),
          ('fs','`posix mkdir / posix chmod / sys unlink / sys rename / sys rmdir / sys symlink / sys readlink`'),('mkdirall','`posix mkdir all`'),
          ('durable','`posix fsync / posix fdatasync / posix ftruncate / posix lock exclusive / posix pread`'),('process','`posix fork / posix pipe / posix dup2 / posix execve / posix waitpid`')],
 'io':[('types','`IoError / IoResult`'),('timeout','`io read with timeout / read fd N max M timeout T / write fd N data S timeout T`'),('exec','`io exec timeout / exec with timeout`'),
       ('meta','`file exists / is file / is dir / is symlink / file size / file mtime / file mode`'),('files','`io read file safe / io read lines / io write lines / append file`'),('format','`format io error / format io result`')],
 'agent':[('ask','`agent ask / agent try ask / ask int / ask str / ask int with timeout / ask str with timeout`'),('batch','`agent send batch / agent map batch / agent receive count / agent drain ready / relay int / relay str`'),
          ('life','`is agent alive / agent status / stop agent / agent stop all`'),('counter','`new counter agent / counter add / counter get / counter reset`'),('log','`new log agent / log append / log read / log clear`'),
          ('kv','`new kv agent / agent kv put / agent kv get / agent kv delete / agent kv has / agent kv count / agent kv keys / agent kv clear`')],
 'pool':[('start','`pool start / pool capacity / pool busy / pool idle`'),('submit','`pool submit / pool refused`'),('collect','`pool done fd / pool collect`'),('tagged','`pool tagged`'),('drainw','`pool drain`'),
         ('pool','`pool of / pool size / pool is empty / pool agents`'),('shard','`pool ask shard / pool ask shard or`'),('broadcast','`pool broadcast`'),('drain','`pool drain all / pool drain ready`'),('shutdown','`pool shutdown`')],
 'net_agent':[('config','`ReactorConfig / reactor defaults / reactor with ...`'),('loop','`reactor start / reactor turn / reactor stop`'),('turnleft','`reactor arrived / reactor ready / reactor left`'),('conn','`reactor input / reactor take / reactor send / reactor close after send / reactor peer`'),('state','`reactor state / reactor set state`'),('each','`ConnStep / reactor each`'),('stats','`ReactorStats / reactor stats`')],
}
# One row replaced: old code cell -> (new code cell, string key or None to keep the old purpose)
FAMILY_ROW={
 'template':{'`tmpl escape html / tmpl escape latex`':('`tmpl render with escape`','fam.template.escape')},
 'argon2id':{'`argon2id hash with preset / argon2id params preset`':('`default argon2 params / argon2 interactive params / argon2 moderate params / argon2 sensitive params / argon2 params`','fam.argon2id.presets')},
 'jwt':{'`type JwtResult`':('`JwtRes / JwtClaimsRes`',"`JwtOk` / `JwtErr`, `JwtClaimsOk` / `JwtClaimsErr`")},
}
# Names quoted in the prose that do not exist: item inside a backtick span -> real name (None removes the item)
RENAME={
 'str':{'to upper':'str to upper','to lower':'str to lower','pad left':'str pad left','pad right':'str pad right','trim left':'str trim left','trim right':'str trim right','str lines':None,'str words':'str split chars'},
 'math':{'div ceil':'math div ceil','div euclid':'math div euclid','div floor':'math div floor','mod euclid':'math mod euclid','mod inv':'math mod inv','mod pow':'math mod pow','is prime':'math is prime',
         'max list':'math max list','min list':'math min list','mean floor':'math mean','median floor':'math median','variance floor':None,'math mean floor':'math mean','math median floor':'math median','math variance floor':None},
 'list':{'count eq':'list count','head or':'list head','last or':'list last','nth or':'list nth','kv empty':'list kv empty','kv get':'list kv get','kv get or':'list kv get or','kv has':'list kv has','kv keys':'list kv keys',
         'kv len':'list kv len','kv merge':'list kv merge','kv put':'list kv put','kv remove':'list kv remove','kv values':'list kv values','list sort int':'list sort ints','list sort str':'list sort texts','list sort desc':None},
 'btree':{'min key':'btree keys','max key':None,'is subset':None,'btree insert':'btree put'},
 'linalg':{'from diag':None,'leaky relu':None,'linalg vec from list':None,'linalg mat from lists':None},
 'codec':{'hex is valid':None,'json encode kv':'json str object','query decode':'query string decode','query encode':'query string encode','query get':'query string decode','json get str/int/bool':'codec json get str/int/bool',
          'json get str':'codec json get str','json get int':'codec json get int'},
 'json':{'JnNull':'JsonNull','JnBool':'JsonBool','JnInt':'JsonInt','JnStr':'JsonStr','JnArr':'JsonArr','JnObj':'JsonObj','JnErr':'JsonErr','json is ok':'json parse with limits','json query':'json get path','json query str/int/bool':'json get str/int/bool'},
 'csv':{'csv parse with':'csv parse with delim','csv get cell':'csv get by header','csv row to kv':'csv row to map','csv table to kv list':None},
 'ini':{'get bool':'ini get bool','get int':'ini get int','get str':'ini get','ini section map':None},
 'regex':{'regex escape':None},
 'glob':{'glob has magic':None},
 'diff':{'DiffKeep':'"equal"','DiffAdd':'"insert"','DiffDel':'"delete"','DiffOp':'diff_op','DiffInsert':'"insert"','DiffDelete':'"delete"','diff patch':'diff apply','diff apply text':None,'diff format':None,'diff old line':'old_line_no','diff new line':'new_line_no'},
 'template':{'TmplPlain':'TmplEscapeNone','TmplHtml':'TmplEscapeHtml','TmplLatex':'TmplEscapeLatex','TmplErr':'tmpl render','tmpl escape latex':'tmpl render latex','tmpl escape html':'tmpl render html','tmpl extract vars':None,'tmpl has unclosed tags':None},
 'fmt':{'fmt ridgun':'format ridgun source','fmt ridgun with':'fmt source with config'},
 'cli':{'cli opt int':'cli get int opt','cli opt bool':'cli get opt','env str/int/bool or':'env get or / env get int or / env get bool or'},
 'path':{'replace ext':'path replace ext','path join all':'path join list','path is safe rel':'path is safe subpath','path resolve under':None},
 'time':{'time exp backoff ms':'time backoff ms','time format duration':'time format duration ms'},
 'uuid':{'crc32 hex':None,'uuid v7 timestamp ms':'uuid version'},
 'log':{'log enabled':'log should emit'},
 'posix':{'sys poll status':'wait fd','clock_gettime':'sys monotonic ns'},
 'io':{'io error message':'format io error','is regular file':'is file','copy file':None,'InvalidInput':None,'PermissionDenied':None,'PosixErrno':'SysErr'},
 'crypto':{'hmac sha256 hex':None},
 'argon2id':{'argon2id gen salt':'argon2id generate salt','blake2b hex':None,'owaspfirst':'default argon2 params','owaspsecond':'argon2 moderate params'},
 'jwt':{'jwt claims':'jwt sign claims','jwt get str':'jwt verify claims','jwt get int':None,'jwt validate claims':'jwt verify claims','token seal':'jwt seal aead','token open':'jwt open aead','JwtBadSignature':'JwtErr'},
 'socket':{'dns resolve a':'sock resolve host','ipv4 in cidr':'ip in cidr','recv exact':'sock recv exact','recv line':'sock recv line','resolve host':'sock resolve host','send all':'sock send all','send frame u32be':'sock send frame',
           'send line':'sock send line','sock select':'sock poll','tcp listen':'sock listen','SockFdResult':'(rc, fd)','SockAcceptResult':'(rc, fd, ip)'},
 'http':{'http get header':'http header get','http sanitize header':'http build request','http format request/response':'http build request/response'},
 'ws':{'ws text frame':'ws encode text','ws ping frame':'ws encode ping','ws pong frame':'ws encode pong','ws close frame':'ws encode close'},
 'agent':{'try ask':'agent try ask','send batch':'agent send batch','map batch':'agent map batch','drain ready':'agent drain ready','kv put':'agent kv put','kv get':'agent kv get','kv delete':'agent kv delete','kv has':'agent kv has',
          'kv count':'agent kv count','kv keys':'agent kv keys','kv clear':'agent kv clear'},
}
RENAME['pool']=dict(RENAME['agent']); RENAME['net_agent']=dict(RENAME['agent'])

# Examples that leave a chapter: start of the first line of their code
DROP_EXAMPLES={
 'pool':['fn :: test spec combinators pool and net agent ','fn :: test agent lifecycle and counter ','fn :: test log and kv agents '],
 'net_agent':['import agent','fn :: test spec combinators pool and net agent ','fn :: test agent lifecycle and counter ','fn :: test log and kv agents ','fn :: test net agent data path ','fn :: test net agent large reply and slow peer '],
}
# Test functions that changed their name: the example that showed the old one now shows the new one
RENAMED_TESTS={
 'agent':{'fn :: test spec combinators pool and net agent => ()':'fn :: test spec combinators and pool routing => ()'},
}
# New code for the hand-written examples 1 and 2 of a chapter that already exists
HAND_OVERRIDE={
 'net_agent':{1:'''import socket
import net_agent

fn :: fin de linea String Int => Int
      fin de linea s      i   =
        | i >= (str len s)        = 0 - 1
        | (str char at s i) == 10 = i
        | otherwise               = fin de linea s (i + 1)

-- El estado de cada conexión es cuántas líneas ha enviado.
fn :: responder Int String => ConnStep Int
      responder n   entrada =  linea vista n entrada (fin de linea entrada 0)

fn :: linea vista Int String  Int => ConnStep Int
      linea vista n   entrada fin =
        | fin < 0   = ConnStep n 0 "" False
        | otherwise = ConnStep (n + 1) (fin + 1) ("eco " + (str slice entrada 0 fin) + "\\n") False

fn :: primero ((Reactor Int) [Int]) => Reactor Int
      primero (r, _)                =  r

-- Cada vuelta espera como mucho 100 ms a que pase algo, y después responde a quien tenga una línea completa.
fn :: servir (Reactor Int) Int     => ReactorStats
      servir r             vueltas =
        | vueltas <= 0 = reactor stop r 1000
        | otherwise    = servir (reactor each (primero (reactor turn r [] 100)) 0 (responder)) (vueltas - 1)

fn :: main => ()
      main =
        r = reactor start (sock fd (sys tcp listen "127.0.0.1" 0 64)) (reactor defaults)
        echo (accepted_count (servir r 10))
''',2:'''import socket
import net_agent

-- Límites estrictos: 100 conexiones, 4 KB de entrada y 1 MB de salida por conexión,
-- 5 s para el primer mensaje y 60 s de inactividad.
fn :: limites => ReactorConfig
      limites =
        c1 = reactor with max conns (reactor defaults) 100
        c2 = reactor with input limit c1 4096
        c3 = reactor with output limit c2 1048576
        c4 = reactor with first message limit c3 5000
        reactor with idle limit c4 60000

-- A cada conexión nueva se le encola un saludo y se marca para cerrar cuando se haya enviado.
fn :: saludar (Reactor Int) [Int]      => Reactor Int
      saludar r             []         =  r
      saludar r             (id:resto) =  saludar (reactor close after send (reactor send r id ("hola " + (reactor peer r id) + "\\n")) id) resto

fn :: tras la vuelta ((Reactor Int) [Int]) => Reactor Int
      tras la vuelta (r, _)                =  saludar r (reactor arrived r)

fn :: una vuelta (Reactor Int) => Reactor Int
      una vuelta r             =  tras la vuelta (reactor turn r [] 100)

fn :: main => ()
      main =
        r0 = reactor start (sock fd (sys tcp listen "127.0.0.1" 0 64)) (limites)
        r1 = una vuelta (una vuelta r0)
        s  = reactor stats r1
        echo "abiertas {open_count s}, rechazadas {refused_count s}, cerradas por un límite {dropped_count s}"
        echo (accepted_count (reactor stop r1 500))
'''},
 'pool':{1:'''import pool

fn :: doblar Int Int => Int Int
      doblar hechos n =  (hechos + 1, n * 2)

fn :: enviar y recoger => Int
      enviar y recoger =
        p0          = pool start 4 (doblar) 0
        quien, p1   = pool submit p0 21 "cliente-a"
        hechos, p2  = pool collect p1 1000
        resto, p3   = pool drain p2 1000
        pool refused p3
''',2:'''import pool

fn :: entregado (Int (WorkerPool Int Int Int)) => String (WorkerPool Int Int Int)
      entregado (k, p) =  ("trabajador {k}", p)

fn :: aceptar o rechazar (WorkerPool Int Int Int) Int String => String (WorkerPool Int Int Int)
      aceptar o rechazar p trabajo cliente =
        | (pool tagged p cliente) >= 2 = ("demasiadas peticiones de " + cliente, p)
        | (pool idle p) == 0           = ("ocupado", p)
        | otherwise                    = entregado (pool submit p trabajo cliente)
'''},
}
