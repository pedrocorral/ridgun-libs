# Capítulo 01: A lib `str` — Manipulação de Texto, Pesquisa e Formatação Tabular

## 01.1. Por que existe a lib `str`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `str` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `str`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: manipular cadeias em C com `strtok` e `strncpy` é caminhar num campo de minas de *buffer overflows* e ponteiros `NULL`, e noutras linguagens acaba a importar pacotes externos só para alinhar colunas ou repetir um separador em $O(\log N)$.

A lib **`str`** fornece todas as primitivas puras e imutáveis para pesquisar, aparar, dividir, juntar, converter maiúsculas/minúsculas, repetir por duplicação binária $O(\log N)$ e preencher cadeias.

Num ecossistema tradicional, resolver as tarefas do domínio **`STR`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`str`** (`src/main/ridgun/lib/str.ridgun`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import str` (ou `import str as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: str` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `str` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 01.2. Artefactos nativos, importação e catálogo completo da API de `str`

No `ridgun-libs`, **`str`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/str.ridgun` (domínio `STR`). Ao compilar com `stable bundle`, é empacotada num formato nativo:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/str.ridgunlib` | Distribuição e importação direta com `import str` |

> Cada lib declara o seu próprio espaço de nomes com `module :: str`: basta escrever `import str` (ou `import str as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 01.2.1. Resumo das famílias funcionais da `str`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `str index of : String -> String -> Int` | Primeiro índice da subcadeia (`-1` se ausente / `0` se vazia) |
| `str contains / str starts with / str ends with` | Predicados `Bool` de subcadeia, prefixo e sufixo |
| `str trim / str trim left / str trim right` | Remove espaços em branco ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str split chars / str join` | Divide em `[String]` e junta listas com um separador |
| `str replace / str to upper / str to lower` | Substituição sem sobreposição e conversão ASCII de maiúsculas/minúsculas |
| `str repeat / str pad left / str pad right` | Repetição em $O(\log N)$ e preenchimento de colunas com largura fixa |

### 01.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/str.ridgun`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/str.ridgun` (`0` tipos, `0` operadores e `37` funções):

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: is ascii space Int` | `Bool` |
| `2` | `fn :: is ascii lower Int` | `Bool` |
| `3` | `fn :: is ascii upper Int` | `Bool` |
| `4` | `fn :: to upper code Int` | `Int` |
| `5` | `fn :: to lower code Int` | `Int` |
| `6` | `fn :: str index of from String String Int Int Int` | `Int` |
| `7` | `fn :: str index of String String` | `Int` |
| `8` | `fn :: str ends with step String String Int Int` | `Bool` |
| `9` | `fn :: str ends with String String` | `Bool` |
| `10` | `fn :: str is empty String` | `Bool` |
| `11` | `fn :: first non space idx String Int Int` | `Int` |
| `12` | `fn :: last non space end String Int` | `Int` |
| `13` | `fn :: str trim left String` | `String` |
| `14` | `fn :: str trim right String` | `String` |
| `15` | `fn :: str trim slice String Int Int` | `String` |
| `16` | `fn :: str trim String` | `String` |
| `17` | `fn :: str is blank String` | `Bool` |
| `18` | `fn :: str replace step String String String Int` | `String` |
| `19` | `fn :: str replace String String String` | `String` |
| `20` | `fn :: str split chars String Int Int [String]` | `[String]` |
| `21` | `fn :: str split onech loop String Int Int Int Int [String]` | `[String]` |
| `22` | `fn :: str split loop String String Int Int Int Int Int [String]` | `[String]` |
| `23` | `fn :: str split step String String Int Int` | `[String]` |
| `24` | `fn :: str split String String` | `[String]` |
| `25` | `fn :: str case fill Tensor[U8] Int Bool` | `Tensor[U8]` |
| `26` | `idem :: str upper table` | `Tensor[U8]` |
| `27` | `idem :: str lower table` | `Tensor[U8]` |
| `28` | `fn :: str case map Tensor[U8 * n] Tensor[U8]` | `Tensor[U8 * n]` |
| `29` | `fn :: str to upper String` | `String` |
| `30` | `fn :: str to lower String` | `String` |
| `31` | `fn :: str repeat loop String Int String` | `String` |
| `32` | `fn :: str repeat String Int` | `String` |
| `33` | `fn :: pad fill unit String` | `String` |
| `34` | `fn :: str pad left step String Int String Int` | `String` |
| `35` | `fn :: str pad left String Int String` | `String` |
| `36` | `fn :: str pad right step String Int String Int` | `String` |
| `37` | `fn :: str pad right String Int String` | `String` |

---

## 01.3. Explorando a `str` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `str` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test str.ridgun`.

### 01.3.1. Exemplo 1: Fluxo principal em estilo tabular com `str`

Repare como em Ridgun os sinais `=` e os passos de transformação com `str` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import str

fn :: normalizar cabecera String => String
      normalizar cabecera raw =
        raw str trim -> str to lower -> limpia
        limpia str split " " -> partes
        str join partes "-" -> slug
        str pad right slug 24 "."
```

### 01.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `str` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 38 libs do `ridgun-libs`:

```ridgun
import str

fn :: dominio desde String Int => String
      dominio desde correo pos =
        | pos < 0   = "sin-dominio"
        | otherwise = str replace (str to lower correo) "@" " en "

fn :: extraer dominio String => String
      extraer dominio correo =
        dominio desde correo (str index of correo "@")
```

### 01.3.3. Exemplo 3: Pesquisa de subcadeias (`str index of`), sufixos (`str ends with`) e predicados de vazio/branco

Neste exemplo prático exploramos de forma exaustiva como a `str` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test str search and predicates => ()
      test str search and predicates =
        str index of "hello world" "world" -> assert equals 6 "AC1: index_of world"
        str index of "hello world" "hello" -> assert equals 0 "AC1: index_of hello at 0"
        str index of "ababa" "aba" -> assert equals 0 "AC1: index_of returns first occurrence"
        str index of "hello" "xyz" -> assert equals (0 - 1) "AC1: index_of missing"
        str index of "short" "much_longer_needle" -> assert equals (0 - 1) "AC1: needle longer than haystack -> -1"
        str index of "" "a" -> assert equals (0 - 1) "AC1: non-empty needle in empty haystack -> -1"
        str index of "" "" -> assert equals 0 "AC1: empty needle in empty haystack -> 0"
        str index of "abc" "" -> assert equals 0 "AC1: empty needle -> 0"

        str ends with "archive.ridgunlib" ".ridgunlib" -> assert true "AC1: ends_with true"
        str ends with "exact" "exact" -> assert true "AC1: ends_with full string"
        str ends with "any" "" -> assert true "AC1: ends_with empty suffix true"
        str ends with "archive.ridgun" ".ridgunlib" -> assert false "AC1: ends_with false"
        str ends with "short" "longer_suffix" -> assert false "AC1: ends_with suffix longer than string"

        str is empty "" -> assert true "AC1: is_empty true"
        str is empty " " -> assert false "AC1: space is not empty"
        str is blank "" -> assert true "AC1: empty is blank"
        str is blank "   \t\n\r " -> assert true "AC1: whitespace-only is blank"
        str is blank "  x " -> assert false "AC1: non-whitespace is not blank"
        ()
```

### 01.3.4. Exemplo 4: Corte de espaços (`trim`, `str trim left`, `str trim right`), substituição (`str replace`), divisão (`str split`) e junção (`str join`)

Neste exemplo prático exploramos de forma exaustiva como a `str` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test str trim replace and split => ()
      test str trim replace and split =
        str trim "  \thi\n\r " -> assert equals "hi" "AC2: str_trim mixed ASCII whitespace"
        str trim "   \t\r\n" -> assert equals "" "AC2: str_trim all whitespace -> empty"
        str trim "" -> assert equals "" "AC2: str_trim empty -> empty"
        str trim "no_ws" -> assert equals "no_ws" "AC2: str_trim no whitespace"
        str trim left "  abc  " -> assert equals "abc  " "AC2: str_trim_left"
        str trim right "  abc  " -> assert equals "  abc" "AC2: str_trim_right"

        str replace "a-b-c" "-" "_" -> assert equals "a_b_c" "AC2: str_replace single char"
        str replace "aaaa" "aa" "b" -> assert equals "bb" "AC2: str_replace non-overlapping left-to-right"
        str replace "Hello,World" "World" "" -> assert equals "Hello," "AC2: str_replace deletion to empty"
        str replace "abc" "" "x" -> assert equals "abc" "AC2: str_replace empty old leaves string unchanged"
        str replace "abc" "z" "y" -> assert equals "abc" "AC2: str_replace absent needle"

        str split "a,b,c" "," -> assert equals ["a", "b", "c"] "AC2: str_split comma"
        str split "a,,b," "," -> assert equals ["a", "", "b", ""] "AC2: str_split consecutive and trailing delim"
        str split ",a" "," -> assert equals ["", "a"] "AC2: str_split leading delim"
        str split "a::b::c" "::" -> assert equals ["a", "b", "c"] "AC2: str_split multi-char delimiter"
        str split "ab" "" -> assert equals ["a", "b"] "AC2: str_split empty delim splits chars"
        str split "" "" -> assert equals [] "AC2: str_split empty string with empty delim -> []"

        str join [] "::" -> assert equals "" "AC2: str_join empty list"
        str join ["only"] "::" -> assert equals "only" "AC2: str_join singleton"
        str join ["alpha", "beta", "gamma"] "::" -> assert equals "alpha::beta::gamma" "AC2: str_join 3 items"
        ()
```

### 01.3.5. Exemplo 5: Conversão de caixa ASCII (`str to upper`, `str to lower`), repetição binária $O(\log N)$ (`str repeat`) e preenchimento tabular (`str pad left`, `str pad right`)

Neste exemplo prático exploramos de forma exaustiva como a `str` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test str case repeat and padding => ()
      test str case repeat and padding =
        str to upper "Abc! 123 xyz" -> assert equals "ABC! 123 XYZ" "AC3: str_to_upper"
        str to lower "Abc! 123 XYZ" -> assert equals "abc! 123 xyz" "AC3: str_to_lower"
        str to upper "" -> assert equals "" "AC3: str_to_upper empty"

        str repeat "ab" 3 -> assert equals "ababab" "AC3: str_repeat 3"
        str repeat "ab" 1 -> assert equals "ab" "AC3: str_repeat 1"
        str repeat "ab" 0 -> assert equals "" "AC3: str_repeat 0"
        str repeat "ab" (0 - 5) -> assert equals "" "AC3: str_repeat negative -> empty"
        str repeat "" 100 -> assert equals "" "AC3: str_repeat empty string -> empty"

        t0 = sys monotonic ms
        r64k = str repeat "x" 65536
        r256k = str repeat "x" 262144
        t1 = sys monotonic ms
        r8m = str repeat "x" 8000000
        str len r64k -> assert equals 65536 "AC3: str_repeat 65536 length"
        str len r256k -> assert equals 262144 "AC3: str_repeat 262144 length"
        str len r8m -> assert equals 8000000 "AC3: RG-052 str_repeat 8000000 exact length without 1 MiB cap"
        (t1 - t0) < 200 -> assert true "AC3: LIB-9 str_repeat 64k+256k in < 200 ms"

        str pad left "7" 3 "0" -> assert equals "007" "AC3: str_pad_left"
        str pad right "7" 3 "0" -> assert equals "700" "AC3: str_pad_right"
        str pad left "7" 4 "" -> assert equals "   7" "AC3: str_pad_left empty pad_ch defaults to space"
        str pad left "7" 4 "xyz" -> assert equals "xxx7" "AC3: str_pad_left uses first char of pad_ch"
        str pad left "1234" 3 "0" -> assert equals "1234" "AC3: str_pad_left already wider than width"
        str pad right "1234" 3 "0" -> assert equals "1234" "AC3: str_pad_right already wider than width"
        ()
```

---

## 01.4. Debaixo do capô: como a `str` é construída em Ridgun puro (`src/main/ridgun/lib/str.ridgun`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/str.ridgun` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 01.4.1. Implementação interna: ASCII Classification Helpers

Observe como `str.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
module :: str

fn :: is ascii space Int  => Bool
      is ascii space code =
        code == 32 or code == 9 or code == 10 or code == 13

fn :: is ascii lower Int  => Bool
      is ascii lower code =  code >= 97 and code <= 122

fn :: is ascii upper Int  => Bool
      is ascii upper code =  code >= 65 and code <= 90

fn :: to upper code Int  => Int
      to upper code code =
        | is ascii lower code = code - 32
        | otherwise           = code

fn :: to lower code Int  => Int
      to lower code code =
        | is ascii upper code = code + 32
        | otherwise           = code
```

### 01.4.2. Implementação interna: Whitespace Trimming

Observe como `str.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: first non space idx String Int Int => Int
      first non space idx s idx len =
        | idx >= len                         = len
        | is ascii space (str char at s idx) = first non space idx s (idx + 1) len
        | otherwise                          = idx

fn :: last non space end String Int => Int
      last non space end s end =
        | end <= 0                                 = 0
        | is ascii space (str char at s (end - 1)) = last non space end s (end - 1)
        | otherwise                                = end

fn :: str trim left String => String
      str trim left s      =
        s str len -> len
        first non space idx s 0 len -> start
        str slice s start len

fn :: str trim right String => String
      str trim right s      =
        s str len -> len
        last non space end s len -> end
        str slice s 0 end

fn :: str trim slice String Int Int => String
      str trim slice s start end =
        | start >= end = ""
        | otherwise    = str slice s start end

fn :: str trim String => String
      str trim s      =
        s str len -> len
        first non space idx s 0 len -> start
        last non space end s len -> end
        str trim slice s start end

fn :: str is blank String => Bool
      str is blank s      =  s str trim -> str is empty
```

### 01.4.3. Implementação interna: String Splitting & Joining

Observe como `str.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: str split chars String Int Int [String] => [String]
      str split chars s idx slen acc =
        | idx >= slen = acc
        | otherwise   = str split chars s (idx + 1) slen (acc :: [str slice s idx (idx + 1)])

fn :: str split onech loop String Int Int Int Int [String] => [String]
      str split onech loop s d0 pos slen seg_start acc =
        | pos >= slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 =
          seg = str slice s seg_start pos
          str split onech loop s d0 (pos + 1) slen (pos + 1) (acc :: [seg])
        | otherwise =
          str split onech loop s d0 (pos + 1) slen seg_start acc

fn :: str split loop String String Int Int Int Int Int [String] => [String]
      str split loop s delim d0 pos slen dlen seg_start acc =
        | pos + dlen > slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 and (str slice s pos (pos + dlen)) == delim =
          seg = str slice s seg_start pos
          str split loop s delim d0 (pos + dlen) slen dlen (pos + dlen) (acc :: [seg])
        | otherwise =
          str split loop s delim d0 (pos + 1) slen dlen seg_start acc

fn :: str split step String String Int Int => [String]
      str split step s delim slen dlen =
        | dlen == 0 = str split chars s 0 slen []
        | dlen == 1 = str split onech loop s (str char at delim 0) 0 slen 0 []
        | otherwise = str split loop s delim (str char at delim 0) 0 slen dlen 0 []

fn :: str split String String => [String]
      str split s      delim  =
        str split step s delim (str len s) (str len delim)

-- `str join [String] String => String` is the compiler prelude's (ridgunc 0.9.55).
```

### 01.4.4. Implementação interna: Repetition & Padding

Observe como `str.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: str repeat loop String Int String => String
      str repeat loop cur n acc =
        | n <= 0       = acc
        | (n % 2) == 1 = str repeat loop (cur + cur) (n / 2) (acc + cur)
        | otherwise    = str repeat loop (cur + cur) (n / 2) acc

fn :: str repeat String Int => String
      str repeat s      n   =
        | n <= 0 or (str len s) == 0 = ""
        | otherwise                  = str repeat loop s n ""

fn :: pad fill unit String => String
      pad fill unit pad_ch =
        | (str len pad_ch) == 0 = " "
        | otherwise             = str slice pad_ch 0 1

fn :: str pad left step String Int String Int => String
      str pad left step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = (str repeat (pad fill unit pad_ch) (width - slen)) + s

fn :: str pad left String Int String => String
      str pad left s width pad_ch =
        str pad left step s width pad_ch (str len s)

fn :: str pad right step String Int String Int => String
      str pad right step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = s + (str repeat (pad fill unit pad_ch) (width - slen))

fn :: str pad right String Int String => String
      str pad right s width pad_ch =
        str pad right step s width pad_ch (str len s)
```

---

## 01.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `str`

- **Garantia algorítmica e de segurança**: Repetição em $O(\log N)$ através de duplicação binária de cadeias, predicados seguros perante agulhas vazias e zero mutação local.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/str.ridgun` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test str.ridgun`.

### As 5 Regras de Ouro ao programar com a `str`

1. **Declare `import str` no início do ficheiro** e chame as suas funções com espaços, tal como estão declaradas, para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `str` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `str` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `str` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 02** passaremos a explorar em profundidade a lib **`math`** (A lib `math` — Aritmética Segura, Teoria dos Números e Estatística).
