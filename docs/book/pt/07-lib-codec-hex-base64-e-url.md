# Capítulo 07: A lib `codec` — Hex, Base64, Base64url, URL Percent-Encoding e JSON Leve

## 07.1. Por que existe a lib `codec`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `codec` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `codec`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: nada quebra mais depressa uma integração web do que confundir Base64 padrão (`+/=`) com Base64url (`-_` sem preenchimento) num token JWT, ou construir uma query string sem escapar caracteres.

A lib **`codec`** implementa as normas **RFC 4648** (Hex, Base64 e Base64url), **RFC 3986** (codificação percentual de URLs e `query encode` / `query decode`) e construtores/extratores rápidos de **JSON leve (RFC 8259)**.

Num ecossistema tradicional, resolver as tarefas do domínio **`CODEC`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`codec`** (`src/main/ridgun/lib/codec.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import codec` (ou `import codec as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: codec` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `codec` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 07.2. Artefactos nativos, importação e catálogo completo da API de `codec`

No `ridgun-libs`, **`codec`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/codec.rg` (domínio `CODEC`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/codec.rglib` | Distribuição e importação direta com `import codec` |
| **Ficheiro compilado** | `target/codec.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libcodec.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Cada lib declara o seu próprio espaço de nomes com `module :: codec`: basta escrever `import codec` (ou `import codec as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 07.2.1. Resumo das famílias funcionais da `codec`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `hex encode / hex decode / hex is valid` | Codificação hexadecimal RFC 4648 em minúsculas e descodificação validada |
| `base64 encode / base64 decode` | Base64 padrão RFC 4648 §4 com preenchimento `=` |
| `base64url encode / base64url decode` | Base64url seguro para URLs RFC 4648 §5 (`-`, `_`, sem preenchimento) |
| `url encode / url decode / query encode / query decode` | Codificação percentual RFC 3986 e dicionários de query string `k=v&...` |
| `json quote / json object / json get str / json get int` | Serialização JSON rápida sem AST e extração de chaves de primeiro nível |

### 07.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/codec.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/codec.rg` (`0` tipos, `0` operadores e `121` funções):

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: cd raw byte ub Int` | `String` |
| `2` | `fn :: cd raw byte Int` | `String` |
| `3` | `fn :: cd sb append3 String String` | `String String String String` |
| `4` | `fn :: cd sb append2 String String String` | `String String String String` |
| `5` | `fn :: cd sb append1 String String String String` | `String String String String` |
| `6` | `fn :: cd sb append String String String String String` | `String String String String` |
| `7` | `fn :: cd sb finish String String String String` | `String` |
| `8` | `fn :: cd lb append2 [String] [String] Int` | `[String] [String] [String] Int` |
| `9` | `fn :: cd lb append1 [String] [String] [String] Int` | `[String] [String] [String] Int` |
| `10` | `fn :: cd lb append String [String] [String] [String] Int` | `[String] [String] [String] Int` |
| `11` | `fn :: cd lb finish [String] [String] [String]` | `[String]` |
| `12` | `fn :: cd hex lut Int` | `String` |
| `13` | `fn :: cd hex up lut Int` | `String` |
| `14` | `fn :: cd b64 lut Int` | `String` |
| `15` | `fn :: cd b64url lut Int` | `String` |
| `16` | `fn :: cd match sub at String String Int Int Int` | `Bool` |
| `17` | `fn :: cd index of loop String String Int Int Int Int` | `Int` |
| `18` | `fn :: cd index of String String` | `Int` |
| `19` | `fn :: cd scan b end String Int` | `Int` |
| `20` | `fn :: cd scan b prev String Int` | `Int` |
| `21` | `fn :: cd scan ascii end String Int Int` | `Int` |
| `22` | `fn :: cd byte slice step String Int Int Int String String String String` | `String` |
| `23` | `fn :: cd byte slice loop String Int Int String String String String` | `String` |
| `24` | `fn :: cd byte slice check String Int Int Int Int` | `String` |
| `25` | `fn :: cd byte slice String Int Int` | `String` |
| `26` | `fn :: cd split char loop String String Int Int Int Int [String] [String] [String] Int` | `[String]` |
| `27` | `fn :: cd hex val Int` | `Int` |
| `28` | `fn :: cd valid hex loop String Int Int` | `Bool` |
| `29` | `fn :: cd is valid hex len String Int` | `Bool` |
| `30` | `fn :: is valid hex String` | `Bool` |
| `31` | `fn :: cd hex enc byte Int` | `String` |
| `32` | `fn :: cd hex enc loop String Int Int String String String String` | `String` |
| `33` | `fn :: hex encode String` | `String` |
| `34` | `fn :: cd hex dec loop String Int Int String String String String` | `String` |
| `35` | `fn :: hex decode String` | `String` |
| `36` | `fn :: cd b64 char String Int` | `String` |
| `37` | `fn :: cd b64 pad suffix String Bool` | `String` |
| `38` | `fn :: cd b64 enc step String Int String Bool Int String String String String` | `String` |
| `39` | `fn :: cd b64 enc rem String Int String Bool` | `String` |
| `40` | `fn :: base64 encode String` | `String` |
| `41` | `fn :: base64url encode String` | `String` |
| `42` | `fn :: cd b64 val Int` | `Int` |
| `43` | `fn :: cd strip one b64 pad String Int` | `String` |
| `44` | `fn :: cd strip b64 pad String Int` | `String` |
| `45` | `fn :: cd valid b64 body String Int Int` | `Bool` |
| `46` | `fn :: cd valid b64 raw String Int` | `Bool` |
| `47` | `fn :: is valid base64 String` | `Bool` |
| `48` | `fn :: cd b64 dec step String Int Int Int String String String String` | `String` |
| `49` | `fn :: cd b64 dec loop String Int Int` | `String` |
| `50` | `fn :: base64 decode String` | `String` |
| `51` | `fn :: base64url decode String` | `String` |
| `52` | `fn :: cd is unreserved Int` | `Bool` |
| `53` | `fn :: cd scan unres String String Int Int` | `Int` |
| `54` | `fn :: cd pct byte lut String Int` | `String` |
| `55` | `fn :: cd url enc step String String String Int Int Int String String String String` | `String` |
| `56` | `fn :: cd url enc loop String String String Int Int String String String String` | `String` |
| `57` | `fn :: url encode String` | `String` |
| `58` | `fn :: cd scan url plain String Int Int` | `Int` |
| `59` | `fn :: cd url dec pct String Int Int Int Int String String String String String` | `String` |
| `60` | `fn :: cd url dec step String Int Int Int String String String String` | `String` |
| `61` | `fn :: cd url dec loop String Int Int String String String String` | `String` |
| `62` | `fn :: url decode String` | `String` |
| `63` | `fn :: cd pair key (String String)` | `String` |
| `64` | `fn :: cd pair val (String String)` | `String` |
| `65` | `fn :: cd qs enc loop [String String] String String String String` | `String` |
| `66` | `fn :: query string encode [String String]` | `String` |
| `67` | `fn :: cd parse kv at String Int` | `String String` |
| `68` | `fn :: cd parse kv item String` | `String String` |
| `69` | `fn :: cd kv lb append2 [String String] [String String] Int` | `[String String] [String String] [String String] Int` |
| `70` | `fn :: cd kv lb append1 [String String] [String String] [String String] Int` | `[String String] [String String] [String String] Int` |
| `71` | `fn :: cd kv lb append (String String) [String String] [String String] [String String] Int` | `[String String] [String String] [String String] Int` |
| `72` | `fn :: cd parse qs list [String] [String String] [String String] [String String] Int` | `[String String]` |
| `73` | `fn :: cd strip leading q String` | `String` |
| `74` | `fn :: cd decode clean qs String` | `[String String]` |
| `75` | `fn :: query string decode String` | `[String String]` |
| `76` | `fn :: cd is json esc Int` | `Bool` |
| `77` | `fn :: cd scan json plain String Int Int` | `Int` |
| `78` | `fn :: cd json esc hex2 Int` | `String` |
| `79` | `fn :: cd json esc code ub Int` | `String` |
| `80` | `fn :: cd json esc code Int` | `String` |
| `81` | `fn :: cd json esc step String Int Int Int String String String String` | `String` |
| `82` | `fn :: cd json esc loop String Int Int String String String String` | `String` |
| `83` | `fn :: json escape String` | `String` |
| `84` | `fn :: cd json unesc char String Int Int` | `String` |
| `85` | `fn :: cd scan no backslash String Int Int` | `Int` |
| `86` | `fn :: cd json unesc cp Int Int` | `String Int` |
| `87` | `fn :: cd json unesc u4 Int Int Int Int Int` | `String Int` |
| `88` | `fn :: cd json unesc step String Int Int Int String String String String` | `String` |
| `89` | `fn :: cd json unesc loop String Int Int String String String String` | `String` |
| `90` | `fn :: json unescape String` | `String` |
| `91` | `fn :: json quote String` | `String` |
| `92` | `fn :: json int Int` | `String` |
| `93` | `fn :: json bool Bool` | `String` |
| `94` | `fn :: json null` | `String` |
| `95` | `fn :: cd join json loop [String] String String String String` | `String` |
| `96` | `fn :: cd join json items [String]` | `String` |
| `97` | `fn :: json array [String]` | `String` |
| `98` | `fn :: cd join json pairs loop [String String] String String String String` | `String` |
| `99` | `fn :: cd join json pairs [String String]` | `String` |
| `100` | `fn :: json object [String String]` | `String` |
| `101` | `fn :: cd quote pair vals [String String] [String String] [String String] [String String] Int` | `[String String]` |
| `102` | `fn :: json str object [String String]` | `String` |
| `103` | `fn :: cd is json ws Int` | `Bool` |
| `104` | `fn :: cd skip key sep String Int Int` | `Int` |
| `105` | `fn :: cd scan json str end String Int Int` | `Int` |
| `106` | `fn :: cd is tok delim Int` | `Bool` |
| `107` | `fn :: cd scan json tok end String Int Int` | `Int` |
| `108` | `fn :: cd extract json str vend String Int Int` | `String` |
| `109` | `fn :: cd extract json str vstart String Int` | `String` |
| `110` | `fn :: cd extract json str kpos String String Int` | `String` |
| `111` | `fn :: codec json get str String String` | `String` |
| `112` | `fn :: cd is signed int loop String Int Int` | `Bool` |
| `113` | `fn :: cd is valid int len String Int` | `Bool` |
| `114` | `fn :: cd is valid int str String` | `Bool` |
| `115` | `fn :: cd raw tok vstart String Int` | `String` |
| `116` | `fn :: cd raw tok kpos String String Int` | `String` |
| `117` | `fn :: cd raw json token String String` | `String` |
| `118` | `fn :: cd parse tok int String Int` | `Int` |
| `119` | `fn :: codec json get int String String Int` | `Int` |
| `120` | `fn :: cd parse tok bool String Bool` | `Bool` |
| `121` | `fn :: codec json get bool String String Bool` | `Bool` |

---

## 07.3. Explorando a `codec` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `codec` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test codec.rg`.

### 07.3.1. Exemplo 1: Fluxo principal em estilo tabular com `codec`

Repare como em Ridgun os sinais `=` e os passos de transformação com `codec` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import codec

fn :: empaquetar parametros String String => String
      empaquetar parametros usuario redir =
        usuario base64url encode -> token_b64
        query encode [("token", token_b64), ("next", redir)]
```

### 07.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `codec` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import codec

fn :: construir respuesta rapida Int String => String Int
      construir respuesta rapida id nombre =
        json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)] -> doc
        json get int doc "id" 0 -> leido
        (doc, leido)
```

### 07.3.3. Exemplo 3: Codificação e descodificação RFC 4648 Hexadecimal, Base64 padrão e Base64url seguro para URLs

Neste exemplo prático exploramos de forma exaustiva como a `codec` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test rfc4648 hex and base64 => ()
      test rfc4648 hex and base64 =
        -- 1. Hexadecimal RFC 4648 test vectors & negative validation
        assert str eq (hex encode "") "" "hex_encode empty"
        assert str eq (hex encode "foobar") "666f6f626172" "hex_encode foobar"
        assert str eq (hex decode "666f6f626172") "foobar" "hex_decode lowercase"
        assert str eq (hex decode "666F6F626172") "foobar" "hex_decode uppercase"
        assert true (is valid hex "deadBEEF09") "is_valid_hex valid"
        assert false (is valid hex "abc") "is_valid_hex odd length"
        assert false (is valid hex "deadZZ") "is_valid_hex invalid chars"
        assert str eq (hex decode "abc") "" "hex_decode odd -> empty"

        -- 2. Base64 & Base64url RFC 4648 test vectors
        assert str eq (base64 encode "") "" "b64 empty"
        assert str eq (base64 encode "f") "Zg==" "b64 f"
        assert str eq (base64 encode "fo") "Zm8=" "b64 fo"
        assert str eq (base64 encode "foo") "Zm9v" "b64 foo"
        assert str eq (base64 encode "foob") "Zm9vYg==" "b64 foob"
        assert str eq (base64 encode "fooba") "Zm9vYmE=" "b64 fooba"
        assert str eq (base64 encode "foobar") "Zm9vYmFy" "b64 foobar"
        assert str eq (base64 decode "Zg==") "f" "b64 dec f"
        assert str eq (base64 decode "Zm8=") "fo" "b64 dec fo"
        assert str eq (base64 decode "Zm9v") "foo" "b64 dec foo"
        assert str eq (base64 decode "Zm9vYg==") "foob" "b64 dec foob"
        assert str eq (base64 decode "Zm9vYmE=") "fooba" "b64 dec fooba"
        assert str eq (base64 decode "Zm9vYmFy") "foobar" "b64 dec foobar"
        assert str eq (base64url encode "foob") "Zm9vYg" "b64url nopad"
        assert str eq (base64url decode "Zm9vYg") "foob" "b64url dec"
        assert false (is valid base64 "A") "invalid base64 len%4==1"
        assert false (is valid base64 "Zm$v") "invalid base64 char"
        assert str eq (base64 decode "Zm$v") "" "invalid base64 -> empty"

        -- 3. LIB-8: Binary-safe decoding for raw octets >= 0x80 and 0x00
        raw4 = hex decode "c800ff41"
        assert int equals (str len raw4) 4 "str_len (hex_decode c800ff41) == 4"
        assert int equals (str char at raw4 0) 200 "raw4[0] == 0xc8"
        assert int equals (str char at raw4 1) 0 "raw4[1] == 0x00"
        assert int equals (str char at raw4 2) 255 "raw4[2] == 0xff"
        assert int equals (str char at raw4 3) 65 "raw4[3] == 0x41"
        assert str eq (hex encode raw4) "c800ff41" "hex_encode raw4 == c800ff41"
        check binary roundtrip loop 10 -> ()
        ()
```

### 07.3.4. Exemplo 4: Codificação percentual RFC 3986 (`url encode`, `url decode`) e strings de consulta (`query encode`, `query get`)

Neste exemplo prático exploramos de forma exaustiva como a `codec` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test rfc3986 url and query strings => ()
      test rfc3986 url and query strings =
        raw = "hello world&x=1+2%"
        enc = url encode raw
        assert str eq enc "hello%20world%26x%3D1%2B2%25" "url_encode"
        assert str eq (url decode enc) raw "url_decode roundtrip"
        assert str eq (url decode "a+b%20c") "a b c" "url_decode plus as space"
        qs  = query string encode [("q", "ridgun libs"), ("page", "2")]
        assert str eq qs "q=ridgun%20libs&page=2" "query_string_encode"
        dec = query string decode ("?" + qs)
        assert eq dec [("q", "ridgun libs"), ("page", "2")]
        ()
```

### 07.3.5. Exemplo 5: Escape e formatação JSON leve RFC 8259 (`json escape`, `json unescape`, `json encode kv`, `json get str/int/bool`)

Neste exemplo prático exploramos de forma exaustiva como a `codec` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test rfc8259 lightweight json => ()
      test rfc8259 lightweight json =
        esc = json escape "line1\n\"quoted\"\\tab\t"
        assert str eq esc "line1\\n\\\"quoted\\\"\\\\tab\\t" "json_escape"
        assert str eq (json unescape esc) "line1\n\"quoted\"\\tab\t" "json_unescape"
        doc = json object [("service", json quote "solstice"), ("port", json int 8443), ("tls", json bool True), ("extra", json null)]
        assert str eq doc "{\"service\":\"solstice\",\"port\":8443,\"tls\":true,\"extra\":null}" "json_object"
        assert str eq (json get str doc "service") "solstice" "json_get_str"
        assert str eq (json get str doc "missing") "" "json_get_str missing"
        assert int equals (json get int doc "port" 80) 8443 "json_get_int"
        assert int equals (json get int doc "missing" 80) 80 "json_get_int fallback"
        assert int equals (json get int doc "service" 80) 80 "json_get_int non-int fallback"
        assert true (json get bool doc "tls" False) "json_get_bool"
        assert false (json get bool doc "missing" False) "json_get_bool fallback"
        arr = json array [json int 1, json int 2, json quote "three"]
        assert str eq arr "[1,2,\"three\"]" "json_array"
        s_o = json str object [("k1", "v1"), ("k2", "v\"2")]
        assert str eq (json get str s_o "k2") "v\"2" "json_str_object escaped roundtrip"
        ()
```

---

## 07.4. Debaixo do capô: como a `codec` é construída em Ridgun puro (`src/main/ridgun/lib/codec.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/codec.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 07.4.1. Implementação interna: RFC 4648 Hexadecimal Encoding & Decoding

Observe como `codec.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
module :: codec

fn :: cd hex val Int => Int
      cd hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 65 and c <= 70  = (c - 65) + 10
        | c >= 97 and c <= 102 = (c - 97) + 10
        | otherwise            = 0 - 1

fn :: cd valid hex loop String Int Int => Bool
      cd valid hex loop s idx len =
        | idx >= len                           = True
        | (cd hex val (str char at s idx)) < 0 = False
        | otherwise                            = cd valid hex loop s (idx + 1) len

fn :: cd is valid hex len String Int => Bool
      cd is valid hex len s n =
        | (n % 2) != 0 = False
        | otherwise    = cd valid hex loop s 0 n

fn :: is valid hex String => Bool
      is valid hex s      =  cd is valid hex len s (str len s)

fn :: cd hex enc byte Int => String
      cd hex enc byte b   =
        ub  = ((b % 256) + 256) % 256
        hi  = ub / 16
        lo  = ub % 16
        tbl = "0123456789abcdef"
        (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd hex enc loop String Int Int String String String String => String
      cd hex enc loop s idx len c0 c1 c2 c3 =
        | idx >= len = cd sb finish c0 c1 c2 c3
        | otherwise  =
          n0, n1, n2, n3 = cd sb append (cd hex enc byte (str char at s idx)) c0 c1 c2 c3
          cd hex enc loop s (idx + 1) len n0 n1 n2 n3

fn :: hex encode String => String
      hex encode s      =  cd hex enc loop s 0 (str len s) "" "" "" ""

fn :: cd hex dec loop String Int Int String String String String => String
      cd hex dec loop s idx len c0 c1 c2 c3 =
        | idx >= len = cd sb finish c0 c1 c2 c3
        | otherwise =
          hi = cd hex val (str char at s idx)
          lo = cd hex val (str char at s (idx + 1))
          b  = cd raw byte ub ((hi * 16) + lo)
          n0, n1, n2, n3 = cd sb append b c0 c1 c2 c3
          cd hex dec loop s (idx + 2) len n0 n1 n2 n3

fn :: hex decode String => String
      hex decode s      =
        | not (is valid hex s) = ""
        | otherwise            = cd hex dec loop s 0 (str len s) "" "" "" ""
```

### 07.4.2. Implementação interna: RFC 4648 Standard Base64 & URL-Safe Base64url

Observe como `codec.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: cd b64 char String Int => String
      cd b64 char tbl    idx =
        i = idx % 64
        str slice tbl i (i + 1)

fn :: cd b64 pad suffix String Bool => String
      cd b64 pad suffix suffix True = suffix
      cd b64 pad suffix _ False = ""

fn :: cd b64 enc step String Int String Bool Int String String String String => String
      cd b64 enc step s idx tbl pad rem c0 c1 c2 c3 =
        | rem <= 0 = cd sb finish c0 c1 c2 c3
        | rem == 1 =
          b0   = str char at s idx
          out2 = (cd b64 char tbl (b0 / 4)) + (cd b64 char tbl ((b0 % 4) * 16)) + (cd b64 pad suffix "==" pad)
          cd sb finish (c0 + out2) c1 c2 c3
        | rem == 2 =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          n    = (b0 * 256) + b1
          out3 = (cd b64 char tbl (n / 1024)) + (cd b64 char tbl ((n / 16) % 64)) + (cd b64 char tbl ((n % 16) * 4)) + (cd b64 pad suffix "=" pad)
          cd sb finish (c0 + out3) c1 c2 c3
        | otherwise =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          b2   = str char at s (idx + 2)
          n    = (b0 * 65536) + (b1 * 256) + b2
          out4 = (cd b64 char tbl (n / 262144)) + (cd b64 char tbl ((n / 4096) % 64)) + (cd b64 char tbl ((n / 64) % 64)) + (cd b64 char tbl (n % 64))
          n0, n1, n2, n3 = cd sb append out4 c0 c1 c2 c3
          cd b64 enc step s (idx + 3) tbl pad (rem - 3) n0 n1 n2 n3

fn :: cd b64 enc rem String Int String Bool => String
      cd b64 enc rem s idx tbl pad = cd b64 enc step s idx tbl pad ((str len s) - idx) "" "" "" ""

fn :: base64 encode String => String
      base64 encode s      =  cd b64 enc rem s 0 (cd b64 lut 0) True

fn :: base64url encode String => String
      base64url encode s      =  cd b64 enc rem s 0 (cd b64url lut 0) False

fn :: cd b64 val Int => Int
      cd b64 val c   =
        | c >= 65 and c <= 90  = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57  = (c - 48) + 52
        | c == 43 or c == 45   = 62
        | c == 47 or c == 95   = 63
        | otherwise            = 0 - 1

fn :: cd strip one b64 pad String Int => String
      cd strip one b64 pad s n =
        | n <= 0                        = ""
        | (str char at s (n - 1)) == 61 = str slice s 0 (n - 1)
        | otherwise                     = s

fn :: cd strip b64 pad String Int => String
      cd strip b64 pad s n =
        | (n % 4) != 0 = s
        | otherwise =
          s1 = cd strip one b64 pad s n
          cd strip one b64 pad s1 (str len s1)

fn :: cd valid b64 body String Int Int => Bool
      cd valid b64 body s idx len =
        | idx >= len                           = True
        | (cd b64 val (str char at s idx)) < 0 = False
        | otherwise                            = cd valid b64 body s (idx + 1) len

fn :: cd valid b64 raw String Int => Bool
      cd valid b64 raw raw n =
        | (n % 4) == 1 = False
        | otherwise    = cd valid b64 body raw 0 n

fn :: is valid base64 String => Bool
      is valid base64 s      =
        cd strip b64 pad s (str len s) -> raw
        cd valid b64 raw raw (str len raw)

fn :: cd b64 dec step String Int Int Int String String String String => String
      cd b64 dec step s idx len rem c0 c1 c2 c3 =
        | rem <= 1 = cd sb finish c0 c1 c2 c3
        | rem == 2 =
          v0 = cd b64 val (str char at s idx)
          v1 = cd b64 val (str char at s (idx + 1))
          b0 = cd raw byte ub (((v0 * 4) + (v1 / 16)) % 256)
          cd sb finish (c0 + b0) c1 c2 c3
        | rem == 3 =
          v0 = cd b64 val (str char at s idx)
          v1 = cd b64 val (str char at s (idx + 1))
          v2 = cd b64 val (str char at s (idx + 2))
          n  = (v0 * 1024) + (v1 * 16) + (v2 / 4)
          b01 = (cd raw byte ub ((n / 256) % 256)) + (cd raw byte ub (n % 256))
          cd sb finish (c0 + b01) c1 c2 c3
        | otherwise =
          v0 = cd b64 val (str char at s idx)
          v1 = cd b64 val (str char at s (idx + 1))
          v2 = cd b64 val (str char at s (idx + 2))
          v3 = cd b64 val (str char at s (idx + 3))
          n  = (v0 * 262144) + (v1 * 4096) + (v2 * 64) + v3
          b0 = (n / 65536) % 256
          b1 = (n / 256) % 256
          b2 = n % 256
          chunk = (cd raw byte ub b0) + (cd raw byte ub b1) + (cd raw byte ub b2)
          n0, n1, n2, n3 = cd sb append chunk c0 c1 c2 c3
          cd b64 dec step s (idx + 4) len (rem - 4) n0 n1 n2 n3

fn :: cd b64 dec loop String Int Int => String
      cd b64 dec loop s idx len = cd b64 dec step s idx len (len - idx) "" "" "" ""

fn :: base64 decode String => String
      base64 decode s      =
        | not (is valid base64 s) = ""
        | otherwise =
          raw = cd strip b64 pad s (str len s)
          cd b64 dec loop raw 0 (str len raw)

fn :: base64url decode String => String
      base64url decode s      =  base64 decode s
```

### 07.4.3. Implementação interna: RFC 3986 URL Percent-Encoding & Query Strings

Observe como `codec.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: cd is unreserved Int => Bool
      cd is unreserved c   =
        | c >= 65 and c <= 90                        = True
        | c >= 97 and c <= 122                       = True
        | c >= 48 and c <= 57                        = True
        | c == 45 or c == 95 or c == 46 or c == 126  = True
        | otherwise                                  = False

fn :: cd scan unres String String Int Int => Int
      cd scan unres s umap idx len =
        | idx >= len = len
        | (str char at umap ((str char at s idx) % 256)) == 49 =
          cd scan unres s umap (idx + 1) len
        | otherwise = idx

fn :: cd pct byte lut String Int => String
      cd pct byte lut lut b =
        ub = ((b % 256) + 256) % 256
        hi = ub / 16
        lo = ub % 16
        "%" + (str slice lut hi (hi + 1)) + (str slice lut lo (lo + 1))

fn :: cd url enc step String String String Int Int Int String String String String => String
      cd url enc step s umap lut run_start next_idx len c0 c1 c2 c3 =
        | next_idx >= len =
          | run_start == 0 = s
          | otherwise      = cd sb finish (c0 + (str slice s run_start len)) c1 c2 c3 |.
        | otherwise =
          piece = (str slice s run_start next_idx) + (cd pct byte lut lut (str char at s next_idx))
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd url enc loop s umap lut (next_idx + 1) len n0 n1 n2 n3

fn :: cd url enc loop String String String Int Int String String String String => String
      cd url enc loop s umap lut run_start len c0 c1 c2 c3 =
        | run_start >= len = cd sb finish c0 c1 c2 c3
        | otherwise        = cd url enc step s umap lut run_start (cd scan unres s umap run_start len) len c0 c1 c2 c3

fn :: url encode String => String
      url encode s      =
        umap = "0000000000000000000000000000000000000000000001101111111111000000011111111111111111111111111000010111111111111111111111111110001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        cd url enc loop s umap "0123456789ABCDEF" 0 (str len s) "" "" "" ""

fn :: cd scan url plain String Int Int => Int
      cd scan url plain s idx len =
        | idx >= len = len
        | (str char at s idx) == 37 or (str char at s idx) == 43 = idx
        | otherwise = cd scan url plain s (idx + 1) len

fn :: cd url dec pct String Int Int Int Int String String String String String => String
      cd url dec pct s next_idx len hi lo prefix c0 c1 c2 c3 =
        | hi >= 0 and lo >= 0 =
          piece = prefix + (cd raw byte ub ((hi * 16) + lo))
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd url dec loop s (next_idx + 3) len n0 n1 n2 n3
        | otherwise =
          piece = prefix + "%"
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd url dec loop s (next_idx + 1) len n0 n1 n2 n3

fn :: cd url dec step String Int Int Int String String String String => String
      cd url dec step s run_start next_idx len c0 c1 c2 c3 =
        | next_idx >= len =
          | run_start == 0 = s
          | otherwise      = cd sb finish (c0 + (cd byte slice s run_start len)) c1 c2 c3 |.
        | (str char at s next_idx) == 43 =
          piece = (cd byte slice s run_start next_idx) + " "
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd url dec loop s (next_idx + 1) len n0 n1 n2 n3
        | (next_idx + 2) < len =
          prefix = cd byte slice s run_start next_idx
          hi = cd hex val (str char at s (next_idx + 1))
          lo = cd hex val (str char at s (next_idx + 2))
          cd url dec pct s next_idx len hi lo prefix c0 c1 c2 c3
        | otherwise =
          piece = (cd byte slice s run_start next_idx) + "%"
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd url dec loop s (next_idx + 1) len n0 n1 n2 n3

fn :: cd url dec loop String Int Int String String String String => String
      cd url dec loop s run_start len c0 c1 c2 c3 =
        | run_start >= len = cd sb finish c0 c1 c2 c3
        | otherwise        = cd url dec step s run_start (cd scan url plain s run_start len) len c0 c1 c2 c3

fn :: url decode String => String
      url decode s      =  cd url dec loop s 0 (str len s) "" "" "" ""

fn :: cd pair key (String String) => String
      cd pair key (k, _)          =  k

fn :: cd pair val (String String) => String
      cd pair val (_, v)          =  v

fn :: cd qs enc loop [String String] String String String String => String
      cd qs enc loop []          c0 c1 c2 c3 =  cd sb finish c0 c1 c2 c3
      cd qs enc loop (pair:rest) c0 c1 c2 c3 =
        piece = "&" + (url encode (cd pair key pair)) + "=" + (url encode (cd pair val pair))
        n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
        cd qs enc loop rest n0 n1 n2 n3

fn :: query string encode [String String] => String
      query string encode []              =  ""
      query string encode (pair:rest)     =
        first = (url encode (cd pair key pair)) + "=" + (url encode (cd pair val pair))
        cd qs enc loop rest first "" "" ""

fn :: cd parse kv at String Int => String String
      cd parse kv at item eq_idx =
        | eq_idx < 0 = (url decode item, "")
        | otherwise  = (url decode (cd byte slice item 0 eq_idx), url decode (cd byte slice item (eq_idx + 1) (str len item)))

fn :: cd parse kv item String => String String
      cd parse kv item item   =  cd parse kv at item (cd index of item "=")

fn :: cd kv lb append2 [String String] [String String] Int => [String String] [String String] [String String] Int
      cd kv lb append2 n1 l2 cnt =
        | (cnt % 1024) == 0 = ([], [], l2 :: n1, cnt)
        | otherwise         = ([], n1, l2, cnt)

fn :: cd kv lb append1 [String String] [String String] [String String] Int => [String String] [String String] [String String] Int
      cd kv lb append1 n0 l1 l2 cnt =
        | (cnt % 32) == 0 = cd kv lb append2 (l1 :: n0) l2 cnt
        | otherwise       = (n0, l1, l2, cnt)

fn :: cd kv lb append (String String) [String String] [String String] [String String] Int => [String String] [String String] [String String] Int
      cd kv lb append item l0 l1 l2 cnt =
        cd kv lb append1 (l0 :: [item]) l1 l2 (cnt + 1)

fn :: cd parse qs list [String] [String String] [String String] [String String] Int => [String String]
      cd parse qs list []       l0 l1 l2 _   =  l2 :: (l1 :: l0)
      cd parse qs list (x:rest) l0 l1 l2 cnt =
        | (str len x) == 0 = cd parse qs list rest l0 l1 l2 cnt
        | otherwise        =
          n0, n1, n2, ncnt = cd kv lb append (cd parse kv item x) l0 l1 l2 cnt
          cd parse qs list rest n0 n1 n2 ncnt

fn :: cd strip leading q String => String
      cd strip leading q qs     =
        | str starts with qs "?" = str slice qs 1 (str len qs)
        | otherwise              = qs

fn :: cd decode clean qs String => [String String]
      cd decode clean qs clean  =
        | (str len clean) == 0 = []
        | otherwise            = cd parse qs list (cd split char loop clean "&" 38 0 0 (str len clean) [] [] [] 0) [] [] [] 0

fn :: query string decode String => [String String]
      query string decode qs     =  cd decode clean qs (cd strip leading q qs)
```

### 07.4.4. Implementação interna: RFC 8259 Lightweight JSON Formatting & Field Extraction

Observe como `codec.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: cd is json esc Int => Bool
      cd is json esc c =
        ub = ((c % 256) + 256) % 256
        ub < 32 or ub == 34 or ub == 92

fn :: cd scan json plain String Int Int => Int
      cd scan json plain s idx len =
        | idx >= len = len
        | cd is json esc (str char at s idx) = idx
        | otherwise = cd scan json plain s (idx + 1) len

fn :: cd json esc hex2 Int => String
      cd json esc hex2 ub =
        hi  = (ub / 16) % 16
        lo  = ub % 16
        tbl = "0123456789abcdef"
        "\\u00" + (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd json esc code ub Int => String
      cd json esc code ub ub =
        | ub == 34  = "\\\""
        | ub == 92  = "\\\\"
        | ub == 8   = "\\b"
        | ub == 12  = "\\f"
        | ub == 10  = "\\n"
        | ub == 13  = "\\r"
        | ub == 9   = "\\t"
        | otherwise = cd json esc hex2 ub

fn :: cd json esc code Int => String
      cd json esc code c =
        cd json esc code ub (((c % 256) + 256) % 256)

fn :: cd json esc step String Int Int Int String String String String => String
      cd json esc step s idx next_idx len c0 c1 c2 c3 =
        | next_idx >= len =
          | idx == 0  = s
          | otherwise = cd sb finish (c0 + (cd byte slice s idx len)) c1 c2 c3 |.
        | otherwise =
          piece = (cd byte slice s idx next_idx) + (cd json esc code (str char at s next_idx))
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd json esc loop s (next_idx + 1) len n0 n1 n2 n3

fn :: cd json esc loop String Int Int String String String String => String
      cd json esc loop s idx len c0 c1 c2 c3 =
        | idx >= len = cd sb finish c0 c1 c2 c3
        | otherwise  = cd json esc step s idx (cd scan json plain s idx len) len c0 c1 c2 c3

fn :: json escape String => String
      json escape s      =  cd json esc loop s 0 (str len s) "" "" "" ""

fn :: cd json unesc char String Int Int => String
      cd json unesc char s idx nc =
        | nc == 34  = "\""
        | nc == 92  = "\\"
        | nc == 47  = "/"
        | nc == 98  = char from code 8
        | nc == 102 = char from code 12
        | nc == 110 = "\n"
        | nc == 114 = "\r"
        | nc == 116 = "\t"
        | otherwise = str slice s (idx + 1) (idx + 2)

fn :: cd scan no backslash String Int Int => Int
      cd scan no backslash s idx len =
        | idx >= len = len
        | (str char at s idx) == 92 = idx
        | otherwise = cd scan no backslash s (idx + 1) len

fn :: cd json unesc cp Int Int => String Int
      cd json unesc cp next_idx cp =
        | cp <= 255 = (cd raw byte ub cp, next_idx + 6)
        | otherwise = (char from code cp, next_idx + 6)

fn :: cd json unesc u4 Int Int Int Int Int => String Int
      cd json unesc u4 next_idx d0 d1 d2 d3 =
        | d0 < 0 or d1 < 0 or d2 < 0 or d3 < 0 = ("\\u", next_idx + 2)
        | otherwise = cd json unesc cp next_idx ((((d0 * 16) + d1) * 256) + (d2 * 16) + d3)

fn :: cd json unesc step String Int Int Int String String String String => String
      cd json unesc step s idx next_idx len c0 c1 c2 c3 =
        | next_idx >= len =
          | idx == 0  = s
          | otherwise = cd sb finish (c0 + (cd byte slice s idx len)) c1 c2 c3 |.
        | (next_idx + 5) < len and (str char at s (next_idx + 1)) == 117 =
          d0 = cd hex val (str char at s (next_idx + 2))
          d1 = cd hex val (str char at s (next_idx + 3))
          d2 = cd hex val (str char at s (next_idx + 4))
          d3 = cd hex val (str char at s (next_idx + 5))
          rep, adv = cd json unesc u4 next_idx d0 d1 d2 d3
          piece = (cd byte slice s idx next_idx) + rep
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd json unesc loop s adv len n0 n1 n2 n3
        | (next_idx + 1) < len =
          piece = (cd byte slice s idx next_idx) + (cd json unesc char s next_idx (str char at s (next_idx + 1)))
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd json unesc loop s (next_idx + 2) len n0 n1 n2 n3
        | otherwise =
          cd sb finish (c0 + (cd byte slice s idx len)) c1 c2 c3

fn :: cd json unesc loop String Int Int String String String String => String
      cd json unesc loop s idx len c0 c1 c2 c3 =
        | idx >= len = cd sb finish c0 c1 c2 c3
        | otherwise  = cd json unesc step s idx (cd scan no backslash s idx len) len c0 c1 c2 c3

fn :: json unescape String => String
      json unescape s      =
        | not (str contains s "\\") = s
        | otherwise                 = cd json unesc loop s 0 (str len s) "" "" "" ""

fn :: json quote String => String
      json quote s      =  "\"" + (json escape s) + "\""

fn :: json int Int => String
      json int n   =  int to str n

fn :: json bool Bool  => String
      json bool True  =  "true"
      json bool False =  "false"

fn :: json null => String
      json null =  "null"

fn :: cd join json loop [String] String String String String => String
      cd join json loop []       c0 c1 c2 c3 =  cd sb finish c0 c1 c2 c3
      cd join json loop (x:rest) c0 c1 c2 c3 =
        n0, n1, n2, n3 = cd sb append ("," + x) c0 c1 c2 c3
        cd join json loop rest n0 n1 n2 n3

fn :: cd join json items [String] => String
      cd join json items []       =  ""
      cd join json items (x:rest) =  cd join json loop rest x "" "" ""

fn :: json array [String] => String
      json array items    =  "[" + (cd join json items items) + "]"

fn :: cd join json pairs loop [String String] String String String String => String
      cd join json pairs loop []          c0 c1 c2 c3 =  cd sb finish c0 c1 c2 c3
      cd join json pairs loop (pair:rest) c0 c1 c2 c3 =
        piece = "," + (json quote (cd pair key pair)) + ":" + (cd pair val pair)
        n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
        cd join json pairs loop rest n0 n1 n2 n3

fn :: cd join json pairs [String String] => String
      cd join json pairs []              =  ""
      cd join json pairs (pair:rest)     =
        first = (json quote (cd pair key pair)) + ":" + (cd pair val pair)
        cd join json pairs loop rest first "" "" ""

fn :: json object [String String] => String
      json object pairs           =  "{" + (cd join json pairs pairs) + "}"

fn :: cd quote pair vals [String String] [String String] [String String] [String String] Int => [String String]
      cd quote pair vals []          l0 l1 l2 _   =  l2 :: (l1 :: l0)
      cd quote pair vals (pair:rest) l0 l1 l2 cnt =
        n0, n1, n2, ncnt = cd kv lb append (cd pair key pair, json quote (cd pair val pair)) l0 l1 l2 cnt
        cd quote pair vals rest n0 n1 n2 ncnt

fn :: json str object [String String] => String
      json str object pairs           =  json object (cd quote pair vals pairs [] [] [] 0)

fn :: cd is json ws Int => Bool
      cd is json ws c   =  c == 32 or c == 9 or c == 10 or c == 13 or c == 58

fn :: cd skip key sep String Int Int => Int
      cd skip key sep s idx len =
        | idx >= len                        = idx
        | cd is json ws (str char at s idx) = cd skip key sep s (idx + 1) len
        | otherwise                         = idx

fn :: cd scan json str end String Int Int => Int
      cd scan json str end s idx len =
        | idx >= len                = 0 - 1
        | (str char at s idx) == 92 = cd scan json str end s (idx + 2) len
        | (str char at s idx) == 34 = idx
        | otherwise                 = cd scan json str end s (idx + 1) len

fn :: cd is tok delim Int => Bool
      cd is tok delim c   =  c == 44 or c == 125 or c == 93 or c == 32 or c == 9 or c == 10 or c == 13

fn :: cd scan json tok end String Int Int => Int
      cd scan json tok end s idx len =
        | idx >= len                           = len
        | cd is tok delim (str char at s idx)  = idx
        | otherwise                            = cd scan json tok end s (idx + 1) len

fn :: cd extract json str vend String Int Int => String
      cd extract json str vend doc vstart vend =
        | vend < 0  = ""
        | otherwise = json unescape (str slice doc (vstart + 1) vend)

fn :: cd extract json str vstart String Int => String
      cd extract json str vstart doc vstart =
        | vstart >= (str len doc)        = ""
        | (str char at doc vstart) != 34 = ""
        | otherwise                      = cd extract json str vend doc vstart (cd scan json str end doc (vstart + 1) (str len doc))

fn :: cd extract json str kpos String String Int => String
      cd extract json str kpos doc pat kpos =
        | kpos < 0  = ""
        | otherwise = cd extract json str vstart doc (cd skip key sep doc (kpos + (str len pat)) (str len doc))

fn :: codec json get str String String => String
      codec json get str doc    key    =
        pat = "\"" + (json escape key) + "\""
        cd extract json str kpos doc pat (cd index of doc pat)

fn :: cd is signed int loop String Int Int => Bool
      cd is signed int loop s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = cd is signed int loop s (idx + 1) len

fn :: cd is valid int len String Int => Bool
      cd is valid int len s n =
        | n == 0                  = False
        | (str char at s 0) == 45 =
          | n <= 1    = False
          | otherwise = cd is signed int loop s 1 n |.
        | otherwise               = cd is signed int loop s 0 n

fn :: cd is valid int str String => Bool
      cd is valid int str s = cd is valid int len s (str len s)

fn :: cd raw tok vstart String Int => String
      cd raw tok vstart doc vstart =
        | vstart >= (str len doc) = ""
        | otherwise =
          vend = cd scan json tok end doc vstart (str len doc)
          str slice doc vstart vend

fn :: cd raw tok kpos String String Int => String
      cd raw tok kpos doc pat kpos =
        | kpos < 0  = ""
        | otherwise = cd raw tok vstart doc (cd skip key sep doc (kpos + (str len pat)) (str len doc))

fn :: cd raw json token String String => String
      cd raw json token doc key =
        pat = "\"" + (json escape key) + "\""
        cd raw tok kpos doc pat (cd index of doc pat)

fn :: cd parse tok int String Int => Int
      cd parse tok int tok fallback =
        | not (cd is valid int str tok) = fallback
        | otherwise                     = str to int tok

fn :: codec json get int String String Int => Int
      codec json get int doc key fallback = cd parse tok int (cd raw json token doc key) fallback

fn :: cd parse tok bool String Bool => Bool
      cd parse tok bool tok fallback =
        | tok == "true"  = True
        | tok == "false" = False
        | otherwise      = fallback

fn :: codec json get bool String String Bool => Bool
      codec json get bool doc key fallback = cd parse tok bool (cd raw json token doc key) fallback
```

---

## 07.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `codec`

- **Garantia algorítmica e de segurança**: Rejeição determinística de entradas hexadecimais ou Base64 malformadas (devolvendo `""` sem leituras fora de limites) e reversibilidade exata $decode(encode(x)) == x$.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/codec.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test codec.rg`.

### As 5 Regras de Ouro ao programar com a `codec`

1. **Declare `import codec` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `codec` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `codec` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `codec` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 08** passaremos a explorar em profundidade a lib **`json`** (A lib `json` — Árvore AST Recursiva RFC 8259, Pretty-Printer e Consultas por Caminho).
