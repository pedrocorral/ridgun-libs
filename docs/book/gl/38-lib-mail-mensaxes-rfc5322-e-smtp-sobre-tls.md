# Capítulo 38: A lib `mail` — Mensaxes RFC 5322 e Envío SMTP sobre TLS

## 38.1. Por que existe a lib `mail`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `mail` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `mail`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: enviar o correo que verifica unha conta parece unha soa liña, ata que un asunto con acento chega convertido en signos de interrogación, desaparece unha liña que comeza por un punto, ou un campo de formulario cun salto de liña engade unha cabeceira `Bcc:` á elección do atacante.

A lib **`mail`** constrúe e renderiza mensaxes **RFC 5322** (encoded-words RFC 2047 para cabeceiras non ASCII, corpos quoted-printable con liñas de 76 bytes como máximo, `multipart/alternative` cando hai texto e HTML) e envíaas cun cliente **SMTP** (RFC 5321, RFC 6409) sobre TLS: TLS implícito no porto 465 (RFC 8314) ou STARTTLS (RFC 3207), con `AUTH PLAIN` ou `AUTH LOGIN` (RFC 4954) enviados só despois do handshake TLS. A inxección de cabeceiras rexéitase ao renderizar a mensaxe, e cada fallo é un `SmtpError` tipado que indica se ten sentido reintentalo.

Nun ecosistema tradicional, resolver as tarefas do dominio **`MAIL`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`mail`** (`src/main/ridgun/lib/mail.ridgun`) aborda o problema con catro principios innegociables:

1. **Declara `import mail` (ou `import mail as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: mail` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `mail` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 38.2. Artefactos nativos, importación e catálogo completo da API de `mail`

En `ridgun-libs`, **`mail`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/mail.ridgun` (dominio `MAIL`). Ao compilar con `stable bundle`, empaquétase nun formato nativo:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/mail.ridgunlib` | Distribución e importación directa con `import mail` |

> Cada lib declara o seu propio espazo de nomes con `module :: mail`: abonda con escribir `import mail` (ou `import mail as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 38.2.1. Resumo de familias funcionais de `mail`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `mail message / mail with html / mail with reply to / mail add to / mail with date / mail with message id` | Constrúe un `MailMessage` paso a paso: remitente, destinatarios, asunto, corpos de texto e HTML, data e identificador |
| `mail render / mail is ok / mail unwrap / mail error` | A mensaxe exactamente como se envía despois de `DATA` (CRLF, quoted-printable, con dot-stuffing), ou o motivo polo que foi rexeitada |
| `mail valid address / mail encode rfc2047 / mail qp encode / mail format date` | Validación de enderezos e os codificadores de cabeceiras, corpos e datas |
| `smtp config / smtp with tls / smtp with auth / smtp with timeout` | Servidor, porto, credenciais, `TlsConfig`, método de autenticación e tempo límite |
| `smtp send / smtp is ok / smtp is retryable / smtp error kind / smtp error reason` | Envía unha mensaxe e inspecciona o resultado tipado |

### 38.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/mail.ridgun`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/mail.ridgun` (`7` tipos, `0` operadores e `109` funcións):

**Tipos alxébricos e rexistros (`type`) de `mail`:**

```ridgun
type MailMessage = from_addr: String, to_addrs: [String], reply_to_addr: String, subject_line: String, text_body: String, html_body: String, message_id: String, date_sec: Int
type MailResult  = MailOk String | MailErr String
type SmtpConfig  = host: String, port: Int, smtp_user: String, smtp_password: String, auth_method: String, timeout_ms: Int, tls_config: TlsConfig
type SmtpError   = SmtpConnectionError String | SmtpTlsError String | SmtpAuthError Int String | SmtpRejectedRecipient Int String | SmtpTemporaryError Int String | SmtpProtocolError Int String | SmtpInvalidMessage String
type SmtpResult  = SmtpOk Int String | SmtpErr SmtpError
type SmtpIo = io_fd: Int, io_tls: Bool, io_conn: TlsConn, io_timeout: Int
type SmtpSt = ss_io: SmtpIo, ss_failed: Bool, ss_error: SmtpError, ss_code: Int, ss_text: String, ss_ehlo: [String]
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: m u8 String Int` | `Int` |
| `2` | `fn :: m index of String Int Int Int` | `Int` |
| `3` | `fn :: m last index of String Int Int` | `Int` |
| `4` | `fn :: m has crlf String` | `Bool` |
| `5` | `fn :: m upper hex Int` | `String` |
| `6` | `fn :: m pad2 Int` | `String` |
| `7` | `fn :: m pair join [String] [String]` | `[String]` |
| `8` | `fn :: m pair join with String [String] [String]` | `[String]` |
| `9` | `fn :: m join all [String]` | `String` |
| `10` | `fn :: m join all with String [String]` | `String` |
| `11` | `fn :: m interleave [String] String [String]` | `[String]` |
| `12` | `fn :: m interleave with String [String] String [String]` | `[String]` |
| `13` | `fn :: m join sep [String] String` | `String` |
| `14` | `fn :: m lines String Int Int [String]` | `[String]` |
| `15` | `fn :: m split lines String` | `[String]` |
| `16` | `fn :: mail message String String String String` | `MailMessage` |
| `17` | `fn :: mail with html MailMessage String` | `MailMessage` |
| `18` | `fn :: mail with reply to MailMessage String` | `MailMessage` |
| `19` | `fn :: mail add to MailMessage String` | `MailMessage` |
| `20` | `fn :: mail with to MailMessage [String]` | `MailMessage` |
| `21` | `fn :: mail with date MailMessage Int` | `MailMessage` |
| `22` | `fn :: mail with message id MailMessage String` | `MailMessage` |
| `23` | `fn :: m is atext Int` | `Bool` |
| `24` | `fn :: m valid local String Int Int Bool` | `Bool` |
| `25` | `fn :: m is ld Int` | `Bool` |
| `26` | `fn :: m valid domain String Int Int Int` | `Bool` |
| `27` | `fn :: mail valid address String` | `Bool` |
| `28` | `fn :: m trim String` | `String` |
| `29` | `fn :: mail split mailbox String` | `String String` |
| `30` | `fn :: m unquote String` | `String` |
| `31` | `fn :: mail address of String` | `String` |
| `32` | `fn :: m domain of String` | `String` |
| `33` | `fn :: m all valid [String]` | `Bool` |
| `34` | `fn :: m any crlf [String]` | `Bool` |
| `35` | `fn :: m no addrs [String]` | `Bool` |
| `36` | `fn :: m needs encoding String Int Int` | `Bool` |
| `37` | `fn :: m utf8 cut String Int` | `Int` |
| `38` | `fn :: m encoded words String [String]` | `[String]` |
| `39` | `fn :: mail encode rfc2047 String` | `String` |
| `40` | `fn :: m is special Int` | `Bool` |
| `41` | `fn :: m has special String Int Int` | `Bool` |
| `42` | `fn :: m quote escape String Int Int String` | `String` |
| `43` | `fn :: m display name String` | `String` |
| `44` | `fn :: m format mailbox String` | `String` |
| `45` | `fn :: m format list [String] [String]` | `[String]` |
| `46` | `fn :: m day name Int` | `String` |
| `47` | `fn :: m month name Int` | `String` |
| `48` | `fn :: mail format date Int` | `String` |
| `49` | `fn :: m qp token String Int Int` | `String` |
| `50` | `fn :: m qp line String Int Int String [String]` | `[String]` |
| `51` | `fn :: m qp lines [String] [String]` | `[String]` |
| `52` | `fn :: mail qp encode String` | `String` |
| `53` | `fn :: m stuff lines [String] [String]` | `[String]` |
| `54` | `fn :: smtp dot stuff String` | `String` |
| `55` | `fn :: m hex random Int` | `String` |
| `56` | `fn :: m header String String` | `String` |
| `57` | `fn :: m qp part String String` | `String` |
| `58` | `fn :: m body part MailMessage` | `String` |
| `59` | `fn :: m message id MailMessage` | `String` |
| `60` | `fn :: m date of MailMessage` | `Int` |
| `61` | `fn :: m render ok MailMessage` | `String` |
| `62` | `fn :: mail render MailMessage` | `MailResult` |
| `63` | `fn :: mail is ok MailResult` | `Bool` |
| `64` | `fn :: mail unwrap MailResult` | `String` |
| `65` | `fn :: mail error MailResult` | `String` |
| `66` | `fn :: smtp config String Int String String` | `SmtpConfig` |
| `67` | `fn :: smtp with tls SmtpConfig TlsConfig` | `SmtpConfig` |
| `68` | `fn :: smtp with auth SmtpConfig String` | `SmtpConfig` |
| `69` | `fn :: smtp with timeout SmtpConfig Int` | `SmtpConfig` |
| `70` | `fn :: m upper char Int` | `Int` |
| `71` | `fn :: m to upper String` | `String` |
| `72` | `fn :: m upper chars String Int Int [String]` | `[String]` |
| `73` | `fn :: m is digit Int` | `Bool` |
| `74` | `fn :: m reply line ok String` | `Bool` |
| `75` | `fn :: m reply loop String Int [String]` | `Int [String] String` |
| `76` | `fn :: m reply at String Int Int [String]` | `Int [String] String` |
| `77` | `fn :: m reply step String Int String [String]` | `Int [String] String` |
| `78` | `fn :: smtp parse response String` | `Int [String] String` |
| `79` | `fn :: m io send SmtpIo String` | `Bool` |
| `80` | `fn :: m io recv plain Int String` | `String` |
| `81` | `fn :: m io recv SmtpIo` | `String` |
| `82` | `fn :: m read reply SmtpIo String Int` | `Int [String]` |
| `83` | `fn :: m read reply more SmtpIo String Int String` | `Int [String]` |
| `84` | `fn :: m fail SmtpSt SmtpError` | `SmtpSt` |
| `85` | `fn :: m reply error String Int String` | `SmtpError` |
| `86` | `fn :: m code in Int [Int]` | `Bool` |
| `87` | `fn :: m on reply SmtpSt String [Int] Int [String]` | `SmtpSt` |
| `88` | `fn :: m expect SmtpSt String String [Int]` | `SmtpSt` |
| `89` | `fn :: m has starttls [String]` | `Bool` |
| `90` | `fn :: m start tls SmtpSt String SmtpConfig` | `SmtpSt` |
| `91` | `fn :: m on tls SmtpSt TlsResult` | `SmtpSt` |
| `92` | `fn :: m require starttls SmtpSt` | `SmtpSt` |
| `93` | `fn :: m auth SmtpSt SmtpConfig` | `SmtpSt` |
| `94` | `fn :: m rcpts SmtpSt [String]` | `SmtpSt` |
| `95` | `fn :: m session SmtpSt SmtpConfig MailMessage String Bool` | `SmtpSt` |
| `96` | `fn :: m finish SmtpSt` | `SmtpResult` |
| `97` | `fn :: m close SmtpSt` | `()` |
| `98` | `fn :: m close io SmtpIo Bool` | `()` |
| `99` | `fn :: m new st Int Int` | `SmtpSt` |
| `100` | `fn :: m run session Int Int SmtpConfig MailMessage String Bool` | `SmtpResult` |
| `101` | `fn :: smtp send mode SmtpConfig MailMessage Bool` | `SmtpResult` |
| `102` | `fn :: m connect and run SmtpConfig MailMessage String Bool` | `SmtpResult` |
| `103` | `fn :: smtp send SmtpConfig MailMessage` | `SmtpResult` |
| `104` | `fn :: smtp is ok SmtpResult` | `Bool` |
| `105` | `fn :: smtp is retryable SmtpResult` | `Bool` |
| `106` | `fn :: m error name SmtpError` | `String` |
| `107` | `fn :: m error text SmtpError` | `String` |
| `108` | `fn :: smtp error kind SmtpResult` | `String` |
| `109` | `fn :: smtp error reason SmtpResult` | `String` |

---

## 38.3. Explorando `mail` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `mail` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test mail.ridgun`.

### 38.3.1. Exemplo 1: Fluxo principal en estilo tabular con `mail`

Observa como en Ridgun os signos `=` e os pasos de transformación con `mail` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import mail

fn :: correo de verificacion String String => MailMessage
      correo de verificacion destino enlace =
        mail message "Ridgun <noreply@ridgun.com>" destino "Verifica tu cuenta" ("Abre este enlace: " + enlace) -> m
        mail with reply to m "soporte@ridgun.com"
```

### 38.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `mail` está deseñada para compoñerse con gardas booleanas `|` e co resto das 38 libs de `ridgun-libs`:

```ridgun
import mail

fn :: motivo de envio SmtpResult => String
      motivo de envio r =
        | smtp is ok r        = "enviado"
        | smtp is retryable r = "reintentar: " + (smtp error reason r)
        | otherwise           = (smtp error kind r) + ": " + (smtp error reason r)

fn :: enviar correo SmtpConfig MailMessage => String
      enviar correo cfg msg =
        motivo de envio (smtp send cfg msg)
```

### 38.3.3. Exemplo 3: Renderizado dunha mensaxe: orde das cabeceiras, destinatarios, a data RFC 5322 e `Message-ID`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `mail` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test render basics => ()
      test render basics =
        r = mail render ((sample msg) -> mail with message id "abc@ridgun.com" -> mail with reply to "support@ridgun.com")
        assert true (mail is ok r) ("render: " + (mail error r)) -> ()
        s = mail unwrap r
        assert true (str starts with s "From: Ridgun <noreply@ridgun.com>\r\n") "From header first" -> ()
        assert true (str contains s "\r\nTo: bob@example.org, Carol <carol@example.org>\r\n") "To header lists all recipients" -> ()
        assert true (str contains s "\r\nReply-To: support@ridgun.com\r\n") "Reply-To header" -> ()
        assert true (str contains s "\r\nSubject: Verify your account\r\n") "ASCII subject unchanged" -> ()
        assert true (str contains s "\r\nDate: Wed, 01 Jan 2025 00:00:00 +0000\r\n") "RFC 5322 date" -> ()
        assert true (str contains s "\r\nMessage-ID: <abc@ridgun.com>\r\n") "Message-ID wrapped in <>" -> ()
        assert true (str contains s "\r\nMIME-Version: 1.0\r\n") "MIME-Version" -> ()
        assert true (str contains s "\r\nContent-Type: text/plain; charset=UTF-8\r\n") "text/plain UTF-8" -> ()
        assert true (str contains s "\r\nContent-Transfer-Encoding: quoted-printable\r\n") "quoted-printable" -> ()
        assert true (str contains s "\r\n..hidden line\r\n") "dot-stuffing of body lines starting with ." -> ()
        assert false (bare lf s 0) "only CRLF line endings" -> ()
        gen = mail unwrap (mail render (sample msg))
        assert true (str contains gen "@ridgun.com>\r\n") "generated Message-ID uses the sender domain" -> ()
        assert str eq (mail format date 0) "Thu, 01 Jan 1970 00:00:00 +0000" "epoch date" -> ()
```

### 38.3.4. Exemplo 4: Encoded-words RFC 2047, nomes visibles entre comiñas, corpos quoted-printable e dot-stuffing

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `mail` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test render encoding => ()
      test render encoding =
        assert str eq (mail encode rfc2047 "Plain subject") "Plain subject" "ASCII is not encoded" -> ()
        assert str eq (mail encode rfc2047 "Größe") ("=?UTF-8?B?" + (c b64 encode "Größe") + "?=") "RFC 2047 B encoding" -> ()
        long = mail encode rfc2047 "Verificá tu cuenta en Ridgun — enlace de un solo uso válido durante veinticuatro horas ✓"
        assert true (str contains long "?=\r\n =?UTF-8?B?") "long subjects fold into several encoded-words" -> ()
        assert true ((max line (long + "\n") 0 0 0) <= 76) "each encoded-word line <= 76 bytes" -> ()
        r1 = mail unwrap (mail render (mail message "José <jose@example.com>" "bob@example.org" "Hola" "x"))
        assert true (str contains r1 ("From: =?UTF-8?B?" + (c b64 encode "José") + "?= <jose@example.com>\r\n")) "non-ASCII display name" -> ()
        r2 = mail unwrap (mail render (mail message "Doe, John <j@example.org>" "bob@example.org" "Hi" "x"))
        assert true (str contains r2 "From: \"Doe, John\" <j@example.org>\r\n") "display name with specials is quoted" -> ()
        body = mail unwrap (mail render (mail message "a@example.org" "b@example.org" "QP" ("café a=b " + (c repeat byte 97 2000))))
        assert true (str contains body "caf=C3=A9 a=3Db") "quoted-printable escapes" -> ()
        assert true ((max line body 0 0 0) <= 78) "all lines <= 998 bytes (QP keeps them <= 76 + CRLF)" -> ()
        html = mail unwrap (mail render (mail with html (sample msg) "<p>Hello <b>Bob</b></p>"))
        assert true (str contains html "Content-Type: multipart/alternative; boundary=\"=_ridgun_") "multipart/alternative" -> ()
        assert true (str contains html "Content-Type: text/html; charset=UTF-8") "HTML part" -> ()
        assert true (str contains html "Content-Type: text/plain; charset=UTF-8") "text part" -> ()
        assert str eq (smtp dot stuff ".a\nb\r\n.c") "..a\r\nb\r\n..c" "smtp dot stuff" -> ()
```

### 38.3.5. Exemplo 5: Inxección de cabeceiras e enderezos non válidos rexeitados ao renderizar

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `mail` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test render rejects => ()
      test render rejects =
        m0 = sample msg
        assert false (mail is ok (mail render (m0 with subject_line = "Hi\r\nBcc: evil@example.com"))) "CRLF in Subject" -> ()
        assert false (mail is ok (mail render (m0 with from_addr = "a@example.org\nBcc: x@y.org"))) "LF in From" -> ()
        assert false (mail is ok (mail render (mail add to m0 "c@example.org\r\nX: y"))) "CRLF in To" -> ()
        assert false (mail is ok (mail render (mail with reply to m0 "r@example.org\rX"))) "CR in Reply-To" -> ()
        assert false (mail is ok (mail render (mail with message id m0 "<a@b>\r\nX: y"))) "CRLF in Message-ID" -> ()
        assert str eq (mail error (mail render (m0 with subject_line = "a\nb"))) "header injection: CR or LF in Subject" "injection error text" -> ()
        assert false (mail is ok (mail render (mail with to m0 []))) "no recipients" -> ()
        assert false (mail is ok (mail render (mail message "not-an-address" "bob@example.org" "s" "b"))) "invalid From" -> ()
        assert true (mail valid address "first.last+tag@sub.example.co.uk") "valid dot-string address" -> ()
        assert true (mail valid address "user@localhost") "single-label domain" -> ()
        assert false (mail valid address "bob") "missing @" -> ()
        assert false (mail valid address "bob@") "missing domain" -> ()
        assert false (mail valid address "@example.org") "missing local part" -> ()
        assert false (mail valid address "a..b@example.org") "consecutive dots" -> ()
        assert false (mail valid address ".a@example.org") "leading dot" -> ()
        assert false (mail valid address "a b@example.org") "space in local part" -> ()
        assert false (mail valid address "a@-example.org") "label starts with hyphen" -> ()
        assert false (mail valid address "a@exa_mple.org") "underscore in domain" -> ()
        assert false (mail valid address "a@example..org") "empty label" -> ()
```

### 38.3.6. Exemplo 6: Análise de respostas SMTP de varias liñas (`smtp parse response`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `mail` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test parse response => ()
      test parse response =
        c1, l1, r1 = smtp parse response "250-mx.example.org\r\n250-STARTTLS\r\n250 8BITMIME\r\nNEXT"
        assert eq c1 250 -> ()
        assert eq (c str list len l1 0) 3 -> ()
        assert str eq (c nth str l1 1) "STARTTLS" "multi-line reply text" -> ()
        assert str eq r1 "NEXT" "remaining input" -> ()
        c2, _, _ = smtp parse response "250-partial\r\n"
        assert eq c2 (0 - 1) -> ()
        c3, _, _ = smtp parse response "hello\r\n"
        assert eq c3 (0 - 2) -> ()
        c4, l4, _ = smtp parse response "220\r\n"
        assert eq c4 220 -> ()
        assert str eq (c nth str l4 0) "" "bare code" -> ()
```

### 38.3.7. Exemplo 7: Un servidor SMTP local: STARTTLS antes de AUTH, TLS implícito, destinatarios rexeitados e erros de autenticación

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `mail` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test smtp local String => ()
      test smtp local dir    =
        p   = base port
        r1  = run local dir p "starttls" (client cfg dir p) (sample msg) False
        assert true (smtp is ok r1) ("STARTTLS + AUTH PLAIN: " + (smtp error kind r1) + " " + (smtp error reason r1)) -> ()
        log1 = smtp log dir p
        assert true ((index of log1 "C: STARTTLS") >= 0 and (index of log1 "TLS: established") > (index of log1 "C: STARTTLS")) "STARTTLS before TLS" -> ()
        assert true ((index of log1 "C: AUTH PLAIN") > (index of log1 "TLS: established")) "AUTH only after TLS" -> ()
        assert true (str contains log1 "C: MAIL FROM:<noreply@ridgun.com>") "envelope sender" -> ()
        assert true (str contains log1 "C: RCPT TO:<bob@example.org>") "first recipient" -> ()
        assert true (str contains log1 "C: RCPT TO:<carol@example.org>") "second recipient" -> ()
        assert true (str contains log1 "\r\n..hidden line\r\n") "DATA is dot-stuffed on the wire" -> ()
        assert true (str contains log1 "C: QUIT") "QUIT" -> ()

        r2  = run local dir (p + 1) "nostarttls" (client cfg dir (p + 1)) (sample msg) False
        assert str eq (smtp error kind r2) "SmtpTlsError" "no STARTTLS offered -> SmtpTlsError" -> ()
        log2 = smtp log dir (p + 1)
        assert false (str contains log2 "AUTH") "credentials never sent in cleartext" -> ()
        assert false (str contains log2 "MAIL FROM") "no cleartext transaction" -> ()

        r3  = run local dir (p + 2) "implicit" (smtp with auth (client cfg dir (p + 2)) "login") (sample msg) True
        assert true (smtp is ok r3) ("implicit TLS + AUTH LOGIN: " + (smtp error kind r3) + " " + (smtp error reason r3)) -> ()
        assert true (str contains (smtp log dir (p + 2)) "C: AUTH LOGIN") "AUTH LOGIN used" -> ()

        r4  = run local dir (p + 3) "badauth" (client cfg dir (p + 3)) (sample msg) False
        assert str eq (smtp error kind r4) "SmtpAuthError" "535 -> SmtpAuthError" -> ()
        assert true (str starts with (smtp error reason r4) "535") "auth error carries the code" -> ()
        assert false (smtp is retryable r4) "auth errors are not retryable" -> ()

        r5  = run local dir (p + 4) "starttls" (client cfg dir (p + 4)) (mail add to (sample msg) "reject-me@example.org") False
        assert str eq (smtp error kind r5) "SmtpRejectedRecipient" "550 on RCPT -> SmtpRejectedRecipient" -> ()

        r6  = run local dir (p + 5) "tempfail" (client cfg dir (p + 5)) (sample msg) False
        assert str eq (smtp error kind r6) "SmtpTemporaryError" "451 -> SmtpTemporaryError" -> ()
        assert true (smtp is retryable r6) "4xx is retryable" -> ()

        bad_roots = smtp with tls (client cfg dir (p + 6)) (tls with root pem (tls defaults) (read file (dir + "/other.pem")))
        r7  = run local dir (p + 6) "starttls" bad_roots (sample msg) False
        assert str eq (smtp error kind r7) "SmtpTlsError" "untrusted server certificate -> SmtpTlsError" -> ()
        assert false (str contains (smtp log dir (p + 6)) "AUTH") "no credentials after a failed handshake" -> ()

        r8  = smtp send (client cfg dir (p + 7)) (sample msg with subject_line = "x\r\nBcc: e@example.org")
        assert str eq (smtp error kind r8) "SmtpInvalidMessage" "invalid message is rejected before connecting" -> ()
        r9  = smtp send (client cfg dir 1) (sample msg)
        assert str eq (smtp error kind r9) "SmtpConnectionError" "refused connection -> SmtpConnectionError" -> ()
        assert true (smtp is retryable r9) "connection errors are retryable" -> ()
```

### 38.3.8. Exemplo 8: Servidores de envío en vivo nos portos 587 e 465

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `mail` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test smtp live => ()
      test smtp live =
        live smtp "smtp.gmail.com" 587 False
        live smtp "smtp.gmail.com" 465 True
```

---

## 38.4. Baixo o capó: como está construída `mail` en Ridgun puro (`src/main/ridgun/lib/mail.ridgun`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/mail.ridgun` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 38.4.1. Implementación interna: Message construction (API-MAIL-001)

Fíxate en como `mail.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: mail message String String String String => MailMessage
      mail message from_a to_a   subject text   =  MailMessage from_a [to_a] "" subject text "" "" 0

fn :: mail with html MailMessage String => MailMessage
      mail with html msg         html   =  msg with html_body = html

fn :: mail with reply to MailMessage String => MailMessage
      mail with reply to msg         addr   =  msg with reply_to_addr = addr

fn :: mail add to MailMessage String => MailMessage
      mail add to msg         addr   =  msg with to_addrs = (to_addrs msg) :: [addr]

fn :: mail with to MailMessage [String] => MailMessage
      mail with to msg         addrs    =  msg with to_addrs = addrs

fn :: mail with date MailMessage Int => MailMessage
      mail with date msg         sec =  msg with date_sec = sec

fn :: mail with message id MailMessage String => MailMessage
      mail with message id msg         mid    =  msg with message_id = mid
```

### 38.4.2. Implementación interna: Address validation (RFC 5321 §4.1.2 Mailbox = Dot-string "@" Domain)

Fíxate en como `mail.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: m is atext Int => Bool
      m is atext c   =
        (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or (c >= 48 and c <= 57) or c == 33 or (c >= 35 and c <= 39) or c == 42 or c == 43 or c == 45 or c == 47 or c == 61 or c == 63 or (c >= 94 and c <= 96) or (c >= 123 and c <= 126)

fn :: m valid local String Int Int Bool => Bool
      m valid local s      idx slen prev_dot =
        | idx >= slen              = not prev_dot
        | (m u8 s idx) == 46       = (not prev_dot) and idx > 0 and (m valid local s (idx + 1) slen True)
        | m is atext (m u8 s idx)  = m valid local s (idx + 1) slen False
        | otherwise                = False

fn :: m is ld Int => Bool
      m is ld c   =  (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or (c >= 48 and c <= 57)

-- Domain = sub-domain *("." sub-domain); sub-domain = Let-dig [Ldh-str] (max 63 per label).
fn :: m valid domain String Int Int Int => Bool
      m valid domain s      idx slen label_len =
        | idx >= slen =
          label_len > 0 and (m is ld (m u8 s (slen - 1)))
        | (m u8 s idx) == 46 =
          label_len > 0 and (m is ld (m u8 s (idx - 1))) and (m valid domain s (idx + 1) slen 0)
        | label_len == 0 and not (m is ld (m u8 s idx)) = False
        | (m is ld (m u8 s idx)) or (m u8 s idx) == 45  =
          label_len < 63 and (m valid domain s (idx + 1) slen (label_len + 1))
        | otherwise = False

fn :: mail valid address String => Bool
      mail valid address addr   =
        at  = m last index of addr 64 ((str len addr) - 1)
        lp  = str slice addr 0 at
        dom = tls rest addr (at + 1)
        res =
          | (str len addr) > 254 or at <= 0 or at > 64       = False
          | (str len dom) == 0 or (str len dom) > 253        = False
          | otherwise = (m valid local lp 0 (str len lp) False) and (m valid domain dom 0 (str len dom) 0)
        res

fn :: m trim String => String
      m trim s      =  c trim s

-- "Name <addr>" -> (name, addr); a bare address -> ("", addr).
fn :: mail split mailbox String => String String
      mail split mailbox s      =
        t   = m trim s
        lt  = m index of t 60 0 (str len t)
        res =
          | lt >= 0 and (str len t) > 0 and (m u8 t ((str len t) - 1)) == 62 =
            (m unquote (m trim (str slice t 0 lt)), m trim (str slice t (lt + 1) ((str len t) - 1)))
          | otherwise = ("", t)
        res

fn :: m unquote String => String
      m unquote s      =
        | (str len s) >= 2 and (m u8 s 0) == 34 and (m u8 s ((str len s) - 1)) == 34 = str slice s 1 ((str len s) - 1)
        | otherwise                                                                  = s

fn :: mail address of String => String
      mail address of s      =
        name, addr = mail split mailbox s
        addr

fn :: m domain of String => String
      m domain of addr   =  tls rest addr ((m last index of addr 64 ((str len addr) - 1)) + 1)

fn :: m all valid [String] => Bool
      m all valid []       =  True
      m all valid (a:rest) =  (mail valid address (mail address of a)) and (m all valid rest)

fn :: m any crlf [String] => Bool
      m any crlf []       =  False
      m any crlf (a:rest) =  (m has crlf a) or (m any crlf rest)

fn :: m no addrs [String] => Bool
      m no addrs []    =  True
      m no addrs (_:_) =  False
```

### 38.4.3. Implementación interna: Bodies: quoted-printable (RFC 2045 §6.7) and dot-stuffing

Fíxate en como `mail.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: m qp token String Int Int => String
      m qp token s      idx slen =
        | (m u8 s idx) == 61                                          = "=3D"
        | ((m u8 s idx) == 32 or (m u8 s idx) == 9) and idx == (slen - 1) = "=" + (m upper hex (m u8 s idx))
        | (m u8 s idx) == 32 or (m u8 s idx) == 9                     = str slice s idx (idx + 1)
        | (m u8 s idx) >= 33 and (m u8 s idx) <= 126                  = str slice s idx (idx + 1)
        | otherwise                                                   = "=" + (m upper hex (m u8 s idx))

-- Encode one source line into output lines of <= 76 chars using "=" soft breaks.
fn :: m qp line String Int Int String [String] => [String]
      m qp line s      idx slen cur    acc      =
        | idx >= slen = [cur] :: acc
        | otherwise   =
          tok = m qp token s idx slen
          res =
            | (str len cur) + (str len tok) > 75 = m qp line s (idx + 1) slen tok ([cur + "="] :: acc)
            | otherwise                          = m qp line s (idx + 1) slen (cur + tok) acc
          res

fn :: m qp lines [String] [String] => [String]
      m qp lines []       acc =  tls reverse acc []
      m qp lines (l:rest) acc =  m qp lines rest (m qp line l 0 (str len l) "" acc)

fn :: mail qp encode String => String
      mail qp encode body   =  m join sep (m qp lines (m split lines body) []) "\r\n"

fn :: m stuff lines [String] [String] => [String]
      m stuff lines []       acc =  tls reverse acc []
      m stuff lines (l:rest) acc =
        | (str len l) > 0 and (m u8 l 0) == 46 = m stuff lines rest (["." + l] :: acc)
        | otherwise                           = m stuff lines rest ([l] :: acc)

-- Normalise line endings to CRLF and prefix "." to lines that start with "." (RFC 5321 §4.5.2).
fn :: smtp dot stuff String => String
      smtp dot stuff data   =  m join sep (m stuff lines (m split lines data) []) "\r\n"
```

### 38.4.4. Implementación interna: Rendering (FR-MAIL-001 AC1)

Fíxate en como `mail.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: m hex random Int => String
      m hex random n   =  bytes to hex str (tls random "m" n)

fn :: m header String String => String
      m header name  value  =  name + ": " + value + "\r\n"

fn :: m qp part String String => String
      m qp part ctype  body   =  (m header "Content-Type" (ctype + "; charset=UTF-8")) + (m header "Content-Transfer-Encoding" "quoted-printable") + "\r\n" + (mail qp encode body) + "\r\n"

fn :: m body part MailMessage => String
      m body part msg         =
        | (html_body msg) == "" = m qp part "text/plain" (text_body msg)
        | otherwise             =
          b = "=_ridgun_" + (m hex random 12)
          (m header "Content-Type" ("multipart/alternative; boundary=\"" + b + "\"")) + "\r\n" + "--" + b + "\r\n" + (m qp part "text/plain" (text_body msg)) + "--" + b + "\r\n" + (m qp part "text/html" (html_body msg)) + "--" + b + "--\r\n"

fn :: m message id MailMessage => String
      m message id msg         =
        | (message_id msg) == ""                                       = "<" + (m hex random 16) + "@" + (m domain of (mail address of (from_addr msg))) + ">"
        | str starts with (message_id msg) "<"                         = message_id msg
        | otherwise                                                    = "<" + (message_id msg) + ">"

fn :: m date of MailMessage => Int
      m date of msg         =
        | (date_sec msg) > 0 = date_sec msg
        | otherwise          = (sys wall time ms) / 1000

fn :: m render ok MailMessage => String
      m render ok msg         =
        reply =
          | (reply_to_addr msg) == "" = ""
          | otherwise                 = m header "Reply-To" (m format mailbox (reply_to_addr msg))
        heads = (m header "From" (m format mailbox (from_addr msg))) + (m header "To" (m join sep (m format list (to_addrs msg) []) ", ")) + reply + (m header "Subject" (mail encode rfc2047 (subject_line msg))) + (m header "Date" (mail format date (m date of msg))) + (m header "Message-ID" (m message id msg)) + (m header "MIME-Version" "1.0")
        smtp dot stuff (heads + (m body part msg))

-- Render the message as sent after DATA (CRLF, quoted-printable, dot-stuffed).
fn :: mail render MailMessage => MailResult
      mail render msg         =
        | m has crlf (from_addr msg)                    = MailErr "header injection: CR or LF in From"
        | m any crlf (to_addrs msg)                     = MailErr "header injection: CR or LF in To"
        | m has crlf (reply_to_addr msg)                = MailErr "header injection: CR or LF in Reply-To"
        | m has crlf (subject_line msg)                 = MailErr "header injection: CR or LF in Subject"
        | m has crlf (message_id msg)                   = MailErr "header injection: CR or LF in Message-ID"
        | not (mail valid address (mail address of (from_addr msg))) = MailErr "invalid From address"
        | m no addrs (to_addrs msg)                     = MailErr "no recipients"
        | not (m all valid (to_addrs msg))              = MailErr "invalid To address"
        | (reply_to_addr msg) != "" and not (mail valid address (mail address of (reply_to_addr msg))) = MailErr "invalid Reply-To address"
        | otherwise                                     = MailOk (m render ok msg)

fn :: mail is ok MailResult => Bool
      mail is ok (MailOk _)  =  True
      mail is ok (MailErr _) =  False

fn :: mail unwrap MailResult => String
      mail unwrap (MailOk s)  =  s
      mail unwrap (MailErr _) =  ""

fn :: mail error MailResult => String
      mail error (MailOk _)  =  ""
      mail error (MailErr e) =  e
```

---

## 38.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `mail`

- **Garantía algorítmica e de seguridade**: `mail render` rexeita calquera valor de cabeceira que conteña CR ou LF, polo que a entrada do usuario non pode engadir cabeceiras, e `smtp send` nunca continúa en texto claro: sen TLS implícito o servidor debe ofrecer STARTTLS, e as credenciais envíanse só despois do handshake.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/mail.ridgun` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test mail.ridgun`.

### As 5 Regras de Ouro ao programar con `mail`

1. **Declara `import mail` ao inicio do ficheiro** e chama as súas funcións con espazos, tal como están declaradas, para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `mail` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `mail` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `mail` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

Completaches o percorrido polas **38 libs estándar de `ridgun-libs`**!
