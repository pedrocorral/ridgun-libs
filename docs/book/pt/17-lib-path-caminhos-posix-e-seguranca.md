# Capítulo 17: A lib `path` — Normalização POSIX (`path clean`) e Confinamento contra Path Traversal

## 1. Por que existe a lib `path`?

Sejamos sinceros: juntar caminhos com `base + "/" + ficheiro` sem limpar segmentos `..` nem validar prefixos é deixar a porta aberta para alguém pedir `../../etc/passwd` no seu servidor web.

A lib **`path`** implementa normalização léxica POSIX (`path clean`), junção segura (`path join`), extração de componentes (`dirname`, `basename`, `stem`, `ext`, `replace ext`) e o predicado de segurança **`path is safe subpath`** (`VUL-INJ-001`) contra *path traversal*.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`path`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/path.rg` (domínio `PATH`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/path.rglib` | Distribuição e importação direta com `import path` |
| **Ficheiro compilado** | `target/path.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libpath.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import path` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `path`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `path clean / path join / path join list` | Colapsa `//`, `.` e `..` lexicamente e junta segmentos de caminho |
| `path dirname / path basename / path split` | Divide um caminho em diretório pai e nome de ficheiro final |
| `path ext / path stem / path replace ext` | Extrai ou substitui a extensão (tratando `.bashrc` como raiz `.bashrc` e ext `""`) |
| `path is safe subpath : String -> String -> Bool` | Verifica que `rel` permanece estritamente dentro de `base_dir` e sem bytes NUL |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `path`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import path

fn :: resolver archivo estatico (raiz : String) (peticion : String) => (Bool, String)
      resolver archivo estatico raiz peticion =
        seguro = path is safe subpath raiz peticion
        ruta   = path join raiz peticion
        (seguro, ruta)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `path` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import path

fn :: cambiar salida a objeto (fuente : String) => (String, String, String)
      cambiar salida a objeto fuente =
        dir = path dirname fuente
        nom = path stem fuente
        obj = path replace ext (path clean fuente) ".rglib"
        (dir, nom, obj)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: `path is safe subpath` rejeita caminhos absolutos, bytes NUL e qualquer sequência `..` que tente escapar do diretório base ou atingir um prefixo irmão (`/srv/www-secret`).
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_path.rg`.
