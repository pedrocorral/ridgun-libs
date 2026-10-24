# Capítulo 10: A lib `ini` — Ficheiros `.ini` por Secções, `.env` e Interpolação de Variáveis

## 1. Por que existe a lib `ini`?

Sejamos sinceros: os ficheiros `.env` e `.ini` parecem triviais até alguém adicionar `export KEY="valor # com cardinal"`, comentários `;` no fim da linha ou referências cruzadas entre variáveis.

A lib **`ini`** analisa configurações `.ini` com secções (`[database]`) e ficheiros `.env` com prefixos `export`, preservando símbolos `#` e `;` dentro de aspas e resolvendo interpolações de variáveis em `dotenv parse`.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`ini`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/ini.rg` (domínio `INI`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ini.rglib` | Distribuição e importação direta com `import ini` |
| **Ficheiro compilado** | `target/ini.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libini.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import ini` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `ini`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `ini parse / ini stringify` | Analisa texto `.ini` por secções em `IniDoc` e serializa de volta para texto canónico |
| `ini get / ini get int / ini get bool / ini set` | Consultas tipadas por secção+chave (`""` para secção global) e atualização imutável |
| `ini sections / ini section map` | Lista todos os nomes de secção ou extrai o mapa `[String String]` de uma secção |
| `dotenv parse` | Analisa linhas `.env` (`export K=V`, aspas, comentários e expansão de variáveis) |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `ini`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

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

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `ini` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Respeito total pelos caracteres `#` e `;` quando surgem entre aspas simples ou duplas, e conversão booleana flexível (`true/1/yes/on` vs `false/0/no/off`).
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_ini.rg`.
