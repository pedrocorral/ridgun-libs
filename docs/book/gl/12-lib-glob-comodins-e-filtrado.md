# Capítulo 12: A lib `glob` — Padróns de Comodíns (`*`, `?`, `[a-z]`) e Filtrado de Listas

## 12.1. Por que existe a lib `glob`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `glob` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `glob`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: usar unha expresión regular completa só para comprobar se un ficheiro remata en `*.rg` ou comeza por `test_[0-9]*.rg` é matar moscas a cañonazos.

A lib **`glob`** implementa coincidencia exacta de comodíns de shell (`*`, `?`, clases `[a-z]`, clases negadas `[!0-9]` / `[^a-z]`), variantes insensibles a maiúsculas (`glob match ci`) e filtrado directo de listas de rutas ou nomes.

Nun ecosistema tradicional, resolver as tarefas do dominio **`GLOB`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`glob`** (`src/main/ridgun/lib/glob.rg`) aborda o problema con catro principios innegociables:

1. **Declara `import glob` (ou `import glob as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: glob` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `glob` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 12.2. Artefactos nativos, importación e catálogo completo da API de `glob`

En `ridgun-libs`, **`glob`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/glob.rg` (dominio `GLOB`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/glob.rglib` | Distribución e importación directa con `import glob` |
| **Ficheiro compilado** | `target/glob.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libglob.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Cada lib declara o seu propio espazo de nomes con `module :: glob`: abonda con escribir `import glob` (ou `import glob as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 12.2.1. Resumo de familias funcionais de `glob`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `glob match / glob match ci` | Coincidencia de padróns glob sensible e insensible a maiúsculas ASCII |
| `glob filter / glob any match` | Filtra `[String]` segundo un padrón ou comproba se coincide algún padrón dunha lista |
| `glob has magic` | Detecta se unha cadea contén metacaracteres de comodín (`*`, `?`, `[`) |

### 12.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/glob.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/glob.rg` (`0` tipos, `0` operadores e `18` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: gl lower char String Int Int` | `String` |
| `2` | `fn :: gl to lower loop String Int Int` | `String` |
| `3` | `fn :: gl to lower String` | `String` |
| `4` | `fn :: gl find close bracket String Int Int` | `Int` |
| `5` | `fn :: gl match range String Int Int Int Int Int` | `Bool` |
| `6` | `fn :: gl match class body String Int Int Int` | `Bool` |
| `7` | `fn :: gl eval bracket char String Int Int Int Int` | `Bool` |
| `8` | `fn :: gl eval bracket String Int Int Int` | `Bool` |
| `9` | `fn :: gl skip stars String Int Int` | `Int` |
| `10` | `fn :: gl match star String Int Int String Int Int` | `Bool` |
| `11` | `fn :: gl match star at String Int Int String Int Int` | `Bool` |
| `12` | `fn :: gl match bracket step String Int Int String Int Int Int` | `Bool` |
| `13` | `fn :: gl match step String Int Int String Int Int Int` | `Bool` |
| `14` | `fn :: gl match loop String Int Int String Int Int` | `Bool` |
| `15` | `fn :: glob match String String` | `Bool` |
| `16` | `fn :: glob match ci String String` | `Bool` |
| `17` | `fn :: glob filter String [String]` | `[String]` |
| `18` | `fn :: glob any match [String] String` | `Bool` |

---

## 12.3. Explorando `glob` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `glob` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test glob.rg`.

### 12.3.1. Exemplo 1: Fluxo principal en estilo tabular con `glob`

Observa como en Ridgun os signos `=` e os pasos de transformación con `glob` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import glob

fn :: seleccionar fuentes ridgun [String] => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### 12.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `glob` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida String => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

### 12.3.3. Exemplo 3: Comodíns `*` e `?`, coincidencia exacta de extremos e casos límite con patróns baleiros

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `glob` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test glob wildcards and boundaries => ()
      test glob wildcards and boundaries =
        assert true (glob match "" "") "AC1: empty pattern matches empty string"
        assert false (glob match "" "a") "AC1: empty pattern rejects non-empty"
        assert true (glob match "*" "") "AC1: * matches empty string"
        assert true (glob match "***" "") "AC1: *** matches empty string"
        assert true (glob match "*" "anything.rg") "AC1: * matches full filename"
        assert true (glob match "*.rg" "socket.rg") "AC1: *.rg matches socket.rg"
        assert true (glob match "*.rg" ".rg") "AC1: *.rg matches leading dot .rg"
        assert false (glob match "*.rg" "README.md") "AC1: *.rg rejects README.md"
        assert false (glob match "*.rg" "socket.rg.bak") "AC1: *.rg rejects trailing suffix"
        assert true (glob match "test_?.rg" "test_a.rg") "AC1: ? matches single char"
        assert false (glob match "test_?.rg" "test_.rg") "AC1: ? rejects zero chars"
        assert false (glob match "test_?.rg" "test_ab.rg") "AC1: ? rejects two chars"
        assert true (glob match "???" "abc") "AC1: ??? matches 3 chars"
        assert false (glob match "???" "ab") "AC1: ??? rejects 2 chars"
        assert true (glob match "a*b*c" "abc") "AC1: multiple * matching zero chars"
        assert true (glob match "a*b*c" "axxxbyyyc") "AC1: multiple * matching substrings"
        assert true (glob match "a*b*c" "abbc") "AC1: backtracking * across repeated b"
        assert false (glob match "a*b*c" "axxxbyyy") "AC1: missing trailing literal after *"
        assert true (glob match "a***b" "axyzb") "AC1: collapsed *** matches"
        -- Pathological backtracking immunity via gl skip stars
        assert false (glob match "****************a" "bbbbbbbbbbbbbbbbbbbbbbbbbbbb") "AC1: collapsed stars avoid exponential backtracking"
        ()
```

### 12.3.4. Exemplo 4: Clases de caracteres `[a-z]`, rangos negados `[!0-9]` / `[^0-9]` e coincidencia insensible a maiúsculas (`glob match ci`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `glob` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test glob classes and case insensitivity => ()
      test glob classes and case insensitivity =
        assert true (glob match "file_[0-9].txt" "file_0.txt") "AC2: [0-9] lower bound 0"
        assert true (glob match "file_[0-9].txt" "file_9.txt") "AC2: [0-9] upper bound 9"
        assert false (glob match "file_[0-9].txt" "file_a.txt") "AC2: [0-9] rejects alpha"
        assert true (glob match "id_[a-zA-Z0-9].rg" "id_Z.rg") "AC2: multi-range [a-zA-Z0-9] matches Z"
        assert true (glob match "id_[a-zA-Z0-9].rg" "id_5.rg") "AC2: multi-range [a-zA-Z0-9] matches 5"
        assert false (glob match "id_[a-zA-Z0-9].rg" "id__.rg") "AC2: multi-range [a-zA-Z0-9] rejects _"
        assert true (glob match "v[135].rg" "v3.rg") "AC2: discrete character set [135]"
        assert false (glob match "v[135].rg" "v2.rg") "AC2: discrete character set rejects 2"
        assert true (glob match "file_[!0-9].txt" "file_a.txt") "AC2: [!0-9] POSIX negated class"
        assert false (glob match "file_[!0-9].txt" "file_7.txt") "AC2: [!0-9] rejects digit"
        assert true (glob match "file_[^0-9].txt" "file_z.txt") "AC2: [^0-9] caret negated class"
        assert false (glob match "file_[^0-9].txt" "file_0.txt") "AC2: [^0-9] rejects digit"
        assert true (glob match "a[b" "a[b") "AC2: unclosed '[' matches literally"
        assert false (glob match "a[b" "axb") "AC2: unclosed '[' rejects non-bracket"

        -- Case-insensitive matching
        assert true (glob match ci "*.RG" "socket.rg") "AC2: glob_match_ci *.RG on lowercase"
        assert true (glob match ci "*.rg" "SOCKET.RG") "AC2: glob_match_ci *.rg on uppercase"
        assert true (glob match ci "src/**/Test_[A-Z]*.rg" "SRC/main/test_crypto.RG") "AC2: glob_match_ci mixed case"
        ()
```

### 12.3.5. Exemplo 5: Filtrado masivo de listas de rutas (`glob filter`) e comprobación contra múltiples patróns (`glob any match`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `glob` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test glob filter and any match => ()
      test glob filter and any match =
        files = ["socket.rg", "README.md", "test_socket.rg", "crypto.rg", "build.sh"]
        assert eq (glob filter "*.rg" files) ["socket.rg", "test_socket.rg", "crypto.rg"]
        assert eq (glob filter "test_*.rg" files) ["test_socket.rg"]
        assert eq (glob filter "*.nomatch" files) []
        assert eq (glob filter "*.rg" []) []
        assert true (glob any match ["*.md", "*.txt", "*.sh"] "README.md") "AC3: glob_any_match first pattern"
        assert true (glob any match ["*.md", "*.txt", "*.sh"] "build.sh") "AC3: glob_any_match last pattern"
        assert false (glob any match ["*.md", "*.txt"] "socket.rg") "AC3: glob_any_match no match"
        assert false (glob any match [] "socket.rg") "AC3: glob_any_match empty pattern list"
        ()
```

---

## 12.4. Baixo o capó: como está construída `glob` en Ridgun puro (`src/main/ridgun/lib/glob.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/glob.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 12.4.1. Implementación interna: Bracket Character Class `[...]` Matching

Fíxate en como `glob.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: glob

fn :: gl find close bracket String Int Int => Int
      gl find close bracket pat idx plen =
        | idx >= plen                  = 0 - 1
        | (str char at pat idx) == 93  = idx
        | otherwise                    = gl find close bracket pat (idx + 1) plen

fn :: gl match range String Int Int Int Int Int => Bool
      gl match range pat idx end_idx tc lo hi =
        | tc >= lo and tc <= hi = True
        | otherwise             = gl match class body pat (idx + 3) end_idx tc

fn :: gl match class body String Int Int Int => Bool
      gl match class body pat idx end_idx tc =
        | idx >= end_idx = False
        | ((idx + 2) < end_idx) and ((str char at pat (idx + 1)) == 45) =
          gl match range pat idx end_idx tc (str char at pat idx) (str char at pat (idx + 2))
        | (str char at pat idx) == tc = True
        | otherwise                   = gl match class body pat (idx + 1) end_idx tc

fn :: gl eval bracket char String Int Int Int Int => Bool
      gl eval bracket char pat pstart close_idx tc c0 =
        | c0 == 33 or c0 == 94 = not (gl match class body pat (pstart + 1) close_idx tc)
        | otherwise            = gl match class body pat pstart close_idx tc

fn :: gl eval bracket String Int Int Int => Bool
      gl eval bracket pat pstart close_idx tc =
        gl eval bracket char pat pstart close_idx tc (str char at pat pstart)
```

### 12.4.2. Implementación interna: Wildcard (`*`, `?`, `[...]`) Matcher

Fíxate en como `glob.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: gl skip stars String Int Int => Int
      gl skip stars pat pidx plen =
        | pidx >= plen                 = pidx
        | (str char at pat pidx) == 42 = gl skip stars pat (pidx + 1) plen
        | otherwise                    = pidx

fn :: gl match star String Int Int String Int Int => Bool
      gl match star pat pidx plen txt tidx tlen =
        | gl match loop pat pidx plen txt tidx tlen = True
        | tidx >= tlen                              = False
        | otherwise                                 = gl match star pat pidx plen txt (tidx + 1) tlen

fn :: gl match star at String Int Int String Int Int => Bool
      gl match star at pat next_p plen txt tidx tlen =
        | next_p >= plen = True
        | otherwise      = gl match star pat next_p plen txt tidx tlen

fn :: gl match bracket step String Int Int String Int Int Int => Bool
      gl match bracket step pat pidx plen txt tidx tlen close_idx =
        | close_idx < 0 =
          | (str char at txt tidx) == 91 = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
          | otherwise                    = False |.
        | gl eval bracket pat (pidx + 1) close_idx (str char at txt tidx) =
          gl match loop pat (close_idx + 1) plen txt (tidx + 1) tlen
        | otherwise = False

fn :: gl match step String Int Int String Int Int Int => Bool
      gl match step pat pidx plen txt tidx tlen pc =
        | pc == 42                     = gl match star at pat (gl skip stars pat (pidx + 1) plen) plen txt tidx tlen
        | tidx >= tlen                 = False
        | pc == 63                     = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | pc == 91                     = gl match bracket step pat pidx plen txt tidx tlen (gl find close bracket pat (pidx + 1) plen)
        | pc == (str char at txt tidx) = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | otherwise                    = False

fn :: gl match loop String Int Int String Int Int => Bool
      gl match loop pat pidx plen txt tidx tlen =
        | pidx >= plen = tidx >= tlen
        | otherwise    = gl match step pat pidx plen txt tidx tlen (str char at pat pidx)

fn :: glob match String String => Bool
      glob match pat    txt    =  gl match loop pat 0 (str len pat) txt 0 (str len txt)

fn :: glob match ci String String => Bool
      glob match ci pat    txt    =
        pat gl to lower -> lpat
        txt gl to lower -> ltxt
        glob match lpat ltxt

fn :: glob filter String [String] => [String]
      glob filter _      []       =  []
      glob filter pat    (x:rest) =
        | glob match pat x = [x] :: (glob filter pat rest)
        | otherwise        = glob filter pat rest

fn :: glob any match [String] String => Bool
      glob any match []       _      =  False
      glob any match (p:rest) txt    =
        | glob match p txt = True
        | otherwise        = glob any match rest txt
```

---

## 12.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `glob`

- **Garantía algorítmica e de seguridade**: Colapso automático de estrelas consecutivas (`***` $\rightarrow$ `*`) para evitar retrocesos redundantes e manexo seguro de corchetes sen pechar `[`.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/glob.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test glob.rg`.

### As 5 Regras de Ouro ao programar con `glob`

1. **Declara `import glob` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `glob` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `glob` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `glob` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 13** pasaremos a explorar en profundidade a lib **`diff`** (A lib `diff` — Algoritmo LCS, Distancia de Edición, Unified Diff e Parches).
