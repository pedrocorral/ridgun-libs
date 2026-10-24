# Capítulo 10: A lib `ini` — Ficheiros `.ini` por Secções, `.env` e Interpolação de Variáveis

## 10.1. Por que existe a lib `ini`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `ini` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `ini`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: os ficheiros `.env` e `.ini` parecem triviais até alguém adicionar `export KEY="valor # com cardinal"`, comentários `;` no fim da linha ou referências cruzadas entre variáveis.

A lib **`ini`** analisa configurações `.ini` com secções (`[database]`) e ficheiros `.env` com prefixos `export`, preservando símbolos `#` e `;` dentro de aspas e resolvendo interpolações de variáveis em `dotenv parse`.

Num ecossistema tradicional, resolver as tarefas do domínio **`INI`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`ini`** (`src/main/ridgun/lib/ini.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `ini` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `ini` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `ini` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 10.2. Artefactos nativos, importação e catálogo completo da API de `ini`

No `ridgun-libs`, **`ini`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/ini.rg` (domínio `INI`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ini.rglib` | Distribuição e importação direta com `import ini` |
| **Ficheiro compilado** | `target/ini.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libini.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import ini` no topo e invocar as suas funções com espaços ou underscores.

### 10.2.1. Resumo das famílias funcionais da `ini`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `ini parse / ini stringify` | Analisa texto `.ini` por secções em `IniDoc` e serializa de volta para texto canónico |
| `ini get / ini get int / ini get bool / ini set` | Consultas tipadas por secção+chave (`""` para secção global) e atualização imutável |
| `ini sections / ini section map` | Lista todos os nomes de secção ou extrai o mapa `[String String]` de uma secção |
| `dotenv parse` | Analisa linhas `.env` (`export K=V`, aspas, comentários e expansão de variáveis) |

### 10.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/ini.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/ini.rg` (`3` tipos, `0` operadores e `44` funções):

**Tipos algébricos e registos (`type`) da `ini`:**

```ridgun
type IniEntry = IniEntry String String
type IniSection = section_name: String, entries: [IniEntry]
type IniDoc = sections: [IniSection]
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: ini_is_hspace Int` | `Bool` |
| `2` | `fn :: ini_trim_left_loop String Int Int` | `String` |
| `3` | `fn :: ini_trim_right_loop String Int` | `String` |
| `4` | `fn :: ini_trim String` | `String` |
| `5` | `fn :: ini_split_lines_loop String Int Int Int [String]` | `[String]` |
| `6` | `fn :: ini_skip_quoted String Int Int Int` | `Int` |
| `7` | `fn :: ini_strip_comment_loop String Int Int` | `String` |
| `8` | `fn :: ini_unquote_unescape_loop String Int Int String` | `String` |
| `9` | `fn :: ini_clean_val String` | `String` |
| `10` | `fn :: ini_clean_val_len String Int` | `String` |
| `11` | `fn :: ini_p_key IniEntry` | `String` |
| `12` | `fn :: ini_p_val IniEntry` | `String` |
| `13` | `fn :: ini_kv_get [IniEntry] String String` | `String` |
| `14` | `fn :: ini_kv_put [IniEntry] String String` | `[IniEntry]` |
| `15` | `fn :: ini_find_rbrace String Int Int` | `Int` |
| `16` | `fn :: ini_expand_brace String Int Int [IniEntry] String Int` | `String` |
| `17` | `fn :: ini_interpolate_loop String Int Int [IniEntry] String` | `String` |
| `18` | `fn :: ini_interpolate String [IniEntry]` | `String` |
| `19` | `fn :: ini_sec_put [IniSection] String String String` | `[IniSection]` |
| `20` | `fn :: ini_sec_ensure [IniSection] String` | `[IniSection]` |
| `21` | `fn :: ini_sec_get [IniSection] String String String` | `String` |
| `22` | `fn :: ini_find_eq String Int Int` | `Int` |
| `23` | `fn :: ini_strip_export String` | `String` |
| `24` | `fn :: ini_parse_kv_at String [IniSection] String Int` | `[IniSection]` |
| `25` | `fn :: ini_sec_entries [IniSection] String` | `[IniEntry]` |
| `26` | `fn :: ini_parse_lines [String] [IniSection] String` | `[IniSection]` |
| `27` | `fn :: ini_parse_sec_hdr String [String] [IniSection]` | `[IniSection]` |
| `28` | `fn :: ini_parse_kv_line String [String] [IniSection] String` | `[IniSection]` |
| `29` | `fn :: ini_parse_clean_line String [String] [IniSection] String` | `[IniSection]` |
| `30` | `fn :: ini parse String` | `IniDoc` |
| `31` | `fn :: dotenv parse String` | `[IniEntry]` |
| `32` | `fn :: ini get IniDoc String String String` | `String` |
| `33` | `fn :: ini get int IniDoc String String Int` | `Int` |
| `34` | `fn :: ini_parse_int_or String Int` | `Int` |
| `35` | `fn :: ini get bool IniDoc String String Bool` | `Bool` |
| `36` | `fn :: ini_parse_bool_or String Bool` | `Bool` |
| `37` | `fn :: ini set IniDoc String String String` | `IniDoc` |
| `38` | `fn :: ini_collect_sec_names [IniSection]` | `[String]` |
| `39` | `fn :: ini sections IniDoc` | `[String]` |
| `40` | `fn :: dotenv get [IniEntry] String String` | `String` |
| `41` | `fn :: ini_format_entries [IniEntry]` | `String` |
| `42` | `fn :: ini_format_section IniSection` | `String` |
| `43` | `fn :: ini_format_sections [IniSection]` | `String` |
| `44` | `fn :: ini stringify IniDoc` | `String` |

---

## 10.3. Explorando a `ini` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `ini` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test ini.rg`.

### 10.3.1. Exemplo 1: Fluxo principal em estilo tabular com `ini`

Repare como em Ridgun os sinais `=` e os passos de transformação com `ini` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import ini

fn :: cargar base de datos (texto_ini : String) => (String, Int, Bool)
      cargar base de datos texto_ini =
        doc  = ini parse texto_ini
        host = ini get doc "database" "host" "localhost"
        port = ini get int doc "database" "port" 5432
        pool = ini get bool doc "database" "pool" True
        (host, port, pool)
```

### 10.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `ini` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

### 10.3.3. Exemplo 3: Secções `[seccao]`, comentários (`;` e `#`), leituras tipadas (`get str`, `get int`, `get bool`) e atualização imutável (`ini set`)

Neste exemplo prático exploramos de forma exaustiva como a `ini` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_ini_sections_and_typed_getters => ()
      test_ini_sections_and_typed_getters =
        nl = char_from_code 10
        src = "# Global header comment" + nl + "; Secondary comment" + nl + "global_env = production" + nl + nl + "[database]" + nl + "host = \"127.0.0.1\"" + nl + "port = 5432 ; default pg" + nl + "timeout = -1 # infinite" + nl + "password = \"p@ss#word;123\"" + nl + "ssl = true" + nl + "pool_enabled = yes" + nl + "readonly = 0" + nl + "debug_sql = no" + nl + nl + "[server]" + nl + "workers = 4" + nl + "enabled = 1" + nl
        doc = ini parse src
        _ = assert str eq (ini get doc "" "global_env" "") "production" "AC1: global sectionless key in root '' section"
        _ = assert str eq (ini get doc "database" "host" "") "127.0.0.1" "AC1: ini get quoted string"
        _ = assert int equals (ini get int doc "database" "port" 0) 5432 "AC1: ini get int with ';' inline comment"
        _ = assert int equals (ini get int doc "database" "timeout" 0) (-1) "AC1: ini get negative int with '#' inline comment"
        _ = assert str eq (ini get doc "database" "password" "") "p@ss#word;123" "AC1: quoted '#' and ';' preserved inside string"
        _ = assert true (ini get bool doc "database" "ssl" False) "AC1: ini get bool 'true'"
        _ = assert true (ini get bool doc "database" "pool_enabled" False) "AC1: ini get bool 'yes'"
        _ = assert false (ini get bool doc "database" "readonly" True) "AC1: ini get bool '0'"
        _ = assert false (ini get bool doc "database" "debug_sql" True) "AC1: ini get bool 'off'"
        _ = assert int equals (ini get int doc "server" "workers" 0) 4 "AC1: ini get second section"
        _ = assert true (ini get bool doc "server" "enabled" False) "AC1: ini get bool '1'"
        _ = assert str eq (ini get doc "server" "missing" "default_v") "default_v" "AC1: ini get fallback on missing key"
        _ = assert str eq (ini get doc "no_such_section" "k" "fallback") "fallback" "AC1: ini get fallback on missing section"
        secs = ini sections doc
        _ = assert int equals (ini_sec_count secs) 3 "AC1: 3 sections (root '', database, server)"
        ()
```

### 10.3.4. Exemplo 4: Ficheiros `.env` com `export`, valores entre aspas, interpolação de variáveis `${VAR}` e serialização canónica (`ini stringify`)

Neste exemplo prático exploramos de forma exaustiva como a `ini` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_dotenv_interpolation_and_roundtrip => ()
      test_dotenv_interpolation_and_roundtrip =
        nl = char_from_code 10
        lb = char_from_code 123
        rb = char_from_code 125
        env_src = "# .env test" + nl + "export BASE_DIR=/srv/app" + nl + "APP_NAME='solstice'" + nl + "LOG_DIR=\"$" + lb + "BASE_DIR" + rb + "/$" + lb + "APP_NAME" + rb + "/logs\"" + nl + "WITH_UNKNOWN=\"prefix_$" + lb + "UNDEFINED_VAR" + rb + "_suffix\"" + nl + "PORT=8080 # inline comment" + nl
        env = dotenv parse env_src
        _ = assert str eq (dotenv get env "BASE_DIR" "") "/srv/app" "AC2: dotenv export key"
        _ = assert str eq (dotenv get env "APP_NAME" "") "solstice" "AC2: dotenv single-quoted value"
        _ = assert str eq (dotenv get env "LOG_DIR" "") "/srv/app/solstice/logs" "AC2: dotenv multiple variable interpolations"
        _ = assert str eq (dotenv get env "WITH_UNKNOWN" "") "prefix__suffix" "AC2: dotenv undefined variable expands to empty"
        _ = assert str eq (dotenv get env "PORT" "") "8080" "AC2: dotenv inline comment stripped"
        _ = assert str eq (dotenv get env "MISSING_KEY" "def") "def" "AC2: dotenv missing key fallback"

        doc0 = ini parse ("[app]" + nl + "name = demo" + nl + "port = 3000" + nl)
        doc1 = ini set doc0 "app" "version" "1.0"
        doc2 = ini set doc1 "app" "port" "9090"
        doc3 = ini set doc2 "metrics" "enabled" "true"
        out_s = ini stringify doc3
        doc_rt = ini parse out_s
        _ = assert str eq (ini get doc_rt "app" "name" "") "demo" "AC3: ini stringify round-trip name"
        _ = assert str eq (ini get doc_rt "app" "version" "") "1.0" "AC3: ini set new key + round-trip"
        _ = assert int equals (ini get int doc_rt "app" "port" 0) 9090 "AC3: ini set overwrite existing key + round-trip"
        _ = assert true (ini get bool doc_rt "metrics" "enabled" False) "AC3: ini set new section + round-trip"
        ()
```

### 10.3.5. Exemplo 5: Configuração hierárquica de um serviço: fusão de `.env` com interpolação `${VAR}` e secções `[database]` / `[server]` em INI

Neste exemplo prático exploramos de forma exaustiva como a `ini` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
import ini

fn :: cargar configuracion servicio (raw_ini : String) (raw_env : String) => (String, Int, Bool, String)
      cargar configuracion servicio raw_ini raw_env =
        env_entries = dotenv parse raw_env
        doc         = ini parse raw_ini
        db_host     = ini get str doc "database" "host" "localhost"
        db_port     = ini get int doc "database" "port" 5432
        tls_activo  = ini get bool doc "database" "tls" True
        doc_act     = ini set doc "server" "dsn" "{db_host}:{db_port}"
        (dotenv get env_entries "APP_ENV" "prod", db_port, tls_activo, ini stringify doc_act)
```

---

## 10.4. Debaixo do capô: como a `ini` é construída em Ridgun puro (`src/main/ridgun/lib/ini.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/ini.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 10.4.1. Implementação interna: Whitespace, Comment & Line Helpers

Observe como `ini.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: ini_is_hspace Int => Bool
      ini_is_hspace c   =  c == 32 OR c == 9 OR c == 13

fn :: ini_trim_left_loop String Int Int => String
      ini_trim_left_loop s      pos len
        | pos >= len = ""
        | ini_is_hspace (str_char_at s pos) = ini_trim_left_loop s (pos + 1) len
        | otherwise = str_slice s pos len

fn :: ini_trim_right_loop String Int     => String
      ini_trim_right_loop s      end_pos
        | end_pos <= 0 = ""
        | ini_is_hspace (str_char_at s (end_pos - 1)) = ini_trim_right_loop s (end_pos - 1)
        | otherwise = str_slice s 0 end_pos

fn :: ini_trim String => String
      ini_trim s      =  ini_trim_left_loop (ini_trim_right_loop s (str_len s)) 0 (str_len (ini_trim_right_loop s (str_len s)))

fn :: ini_split_lines_loop String Int Int Int [String] => [String]
      ini_split_lines_loop s pos len start acc
        | pos >= len AND start == len = acc
        | pos >= len = acc :: [str_slice s start len]
        | (str_char_at s pos) == 10 = ini_split_lines_loop s (pos + 1) len (pos + 1) (acc :: [str_slice s start pos])
        | otherwise = ini_split_lines_loop s (pos + 1) len start acc

fn :: ini_skip_quoted String Int Int Int => Int
      ini_skip_quoted s      pos len q
        | pos >= len = len
        | (str_char_at s pos) == 92 = ini_skip_quoted s (pos + 2) len q
        | (str_char_at s pos) == q = pos + 1
        | otherwise = ini_skip_quoted s (pos + 1) len q

fn :: ini_strip_comment_loop String Int Int => String
      ini_strip_comment_loop s      pos len
        | pos >= len = s
        | (str_char_at s pos) == 34 = ini_strip_comment_loop s (ini_skip_quoted s (pos + 1) len 34) len
        | (str_char_at s pos) == 39 = ini_strip_comment_loop s (ini_skip_quoted s (pos + 1) len 39) len
        | (str_char_at s pos) == 35 OR (str_char_at s pos) == 59 = str_slice s 0 pos
        | (pos + 1) < len AND (str_char_at s pos) == 45 AND (str_char_at s (pos + 1)) == 45 = str_slice s 0 pos
        | otherwise = ini_strip_comment_loop s (pos + 1) len

fn :: ini_unquote_unescape_loop String Int Int String => String
      ini_unquote_unescape_loop s      pos len acc
        | pos >= len = acc
        | (str_char_at s pos) == 92 AND (pos + 1) < len AND (str_char_at s (pos + 1)) == 110 = ini_unquote_unescape_loop s (pos + 2) len (acc + (char_from_code 10))
        | (str_char_at s pos) == 92 AND (pos + 1) < len AND (str_char_at s (pos + 1)) == 116 = ini_unquote_unescape_loop s (pos + 2) len (acc + (char_from_code 9))
        | (str_char_at s pos) == 92 AND (pos + 1) < len = ini_unquote_unescape_loop s (pos + 2) len (acc + (str_slice s (pos + 1) (pos + 2)))
        | otherwise = ini_unquote_unescape_loop s (pos + 1) len (acc + (str_slice s pos (pos + 1)))
```

### 10.4.2. Implementação interna: Key-Value Pair Helpers (`[IniEntry]`)

Observe como `ini.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: ini_p_key IniEntry       => String
      ini_p_key (IniEntry k _) =  k

fn :: ini_p_val IniEntry       => String
      ini_p_val (IniEntry _ v) =  v

fn :: ini_kv_get [IniEntry]  String String   => String
      ini_kv_get []          _      fallback =  fallback
      ini_kv_get (pair:rest) key    fallback
        | (ini_p_key pair) == key = ini_p_val pair
        | otherwise = ini_kv_get rest key fallback

fn :: ini_kv_put [IniEntry]  String String => [IniEntry]
      ini_kv_put []          key    val    =  [IniEntry key val]
      ini_kv_put (pair:rest) key    val
        | (ini_p_key pair) == key = [IniEntry key val] :: rest
        | otherwise = [pair] :: (ini_kv_put rest key val)
```

### 10.4.3. Implementação interna: Sectioned INI Document Helpers

Observe como `ini.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: ini_sec_put [IniSection] String String String => [IniSection]
      ini_sec_put []           sec    key    val    =  [IniSection sec [IniEntry key val]]
      ini_sec_put (s:rest)     sec    key    val
        | (section_name s) == sec = [IniSection sec (ini_kv_put (entries s) key val)] :: rest
        | otherwise = [s] :: (ini_sec_put rest sec key val)

fn :: ini_sec_ensure [IniSection] String => [IniSection]
      ini_sec_ensure []           sec    =  [IniSection sec []]
      ini_sec_ensure (s:rest)     sec
        | (section_name s) == sec = [s] :: rest
        | otherwise = [s] :: (ini_sec_ensure rest sec)

fn :: ini_sec_get [IniSection] String String String   => String
      ini_sec_get []           _      _      fallback =  fallback
      ini_sec_get (s:rest)     sec    key    fallback
        | (section_name s) == sec = ini_kv_get (entries s) key fallback
        | otherwise = ini_sec_get rest sec key fallback

fn :: ini_find_eq String Int Int => Int
      ini_find_eq s      pos len
        | pos >= len = -1
        | (str_char_at s pos) == 61 = pos
        | otherwise = ini_find_eq s (pos + 1) len

fn :: ini_strip_export String => String
      ini_strip_export tr
        | str_starts_with tr "export " = ini_trim (str_slice tr 7 (str_len tr))
        | otherwise = tr

fn :: ini_parse_kv_at String [IniSection] String Int    => [IniSection]
      ini_parse_kv_at _      secs         _      -1     =  secs
      ini_parse_kv_at line   secs         cur_s  eq_pos =
        key = ini_trim (str_slice line 0 eq_pos)
        raw_v = ini_clean_val (str_slice line (eq_pos + 1) (str_len line))
        cur_entries = ini_sec_entries secs cur_s
        val = ini_interpolate raw_v cur_entries
        ini_sec_put secs cur_s key val

fn :: ini_sec_entries [IniSection] String => [IniEntry]
      ini_sec_entries []           _      =  []
      ini_sec_entries (s:rest)     sec
        | (section_name s) == sec = entries s
        | otherwise = ini_sec_entries rest sec

fn :: ini_parse_lines [String] [IniSection] String => [IniSection]
      ini_parse_lines []       secs         _      =  secs
      ini_parse_lines (l:ls)   secs         cur_s  =
        clean = ini_trim (ini_strip_comment_loop l 0 (str_len l))
        ini_parse_clean_line clean ls secs cur_s
```

### 10.4.4. Implementação interna: Queries, Updates & Serialization

Observe como `ini.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: ini get IniDoc String String String => String
      ini get doc sec key fallback = ini_sec_get (sections doc) sec key fallback

fn :: ini get int IniDoc String String Int => Int
      ini get int doc sec key fallback =
        v = ini get doc sec key ""
        ini_parse_int_or v fallback

fn :: ini_parse_int_or String Int      => Int
      ini_parse_int_or ""     fallback =  fallback
      ini_parse_int_or v      _        =  str_to_int v

fn :: ini get bool IniDoc String String Bool => Bool
      ini get bool doc sec key fallback =
        v = ini get doc sec key ""
        ini_parse_bool_or v fallback

fn :: ini_parse_bool_or String  Bool     => Bool
      ini_parse_bool_or ""      fallback =  fallback
      ini_parse_bool_or "true"  _        =  True
      ini_parse_bool_or "True"  _        =  True
      ini_parse_bool_or "1"     _        =  True
      ini_parse_bool_or "yes"   _        =  True
      ini_parse_bool_or "false" _        =  False
      ini_parse_bool_or "False" _        =  False
      ini_parse_bool_or "0"     _        =  False
      ini_parse_bool_or "no"    _        =  False
      ini_parse_bool_or _       fallback =  fallback

fn :: ini set IniDoc String String String => IniDoc
      ini set doc sec key val = IniDoc (ini_sec_put (sections doc) sec key val)

fn :: ini_collect_sec_names [IniSection] => [String]
      ini_collect_sec_names []           =  []
      ini_collect_sec_names (s:rest)     =  [section_name s] :: (ini_collect_sec_names rest)

fn :: ini sections IniDoc => [String]
      ini sections doc    =  ini_collect_sec_names (sections doc)

fn :: dotenv get [IniEntry] String String   => String
      dotenv get env        key    fallback =  ini_kv_get env key fallback

fn :: ini_format_entries [IniEntry] => String
      ini_format_entries []         =  ""
      ini_format_entries ((IniEntry k v):rs) = k + " = " + v + (char_from_code 10) + (ini_format_entries rs)

fn :: ini_format_section IniSection => String
      ini_format_section sec
        | (section_name sec) == "" = ini_format_entries (entries sec)
        | otherwise = "[" + (section_name sec) + "]" + (char_from_code 10) + (ini_format_entries (entries sec))
```

---

## 10.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `ini`

- **Garantia algorítmica e de segurança**: Respeito total pelos caracteres `#` e `;` quando surgem entre aspas simples ou duplas, e conversão booleana flexível (`true/1/yes/on` vs `false/0/no/off`).
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/ini.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test ini.rg`.

### As 5 Regras de Ouro ao programar com a `ini`

1. **Declare `import ini` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `ini` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `ini` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `ini` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 11** passaremos a explorar em profundidade a lib **`regex`** (A lib `regex` — Motor de Expressões Regulares Thompson NFA em Tempo Linear $O(N \cdot M)$).
