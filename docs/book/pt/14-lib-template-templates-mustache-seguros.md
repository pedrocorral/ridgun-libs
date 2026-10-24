# Capítulo 14: A lib `template` — Templates Mustache Seguros com Auto-Escape HTML e LaTeX

## 1. Por que existe a lib `template`?

Sejamos sinceros: montar páginas HTML ou relatórios LaTeX concatenando cadeias à mão é a receita perfeita para uma vulnerabilidade XSS (`<script>`) ou para que um simples `%` ou `_` quebre o seu PDF.

A lib **`template`** oferece um motor **Mustache** sem lógica arbitrária com auto-escape contextual (`TmplPlain`, `TmplHtml`, `TmplLatex`), substituição bruta explícita (`{{{raw}}}` / `{{&raw}}`), comentários (`{{! ... }}`), secções condicionais (`{{#sec}}...{{/sec}}`) e invertidas (`{{^sec}}...{{/sec}}`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`template`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/template.rg` (domínio `TMPL`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/template.rglib` | Distribuição e importação direta com `import template` |
| **Ficheiro compilado** | `target/template.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libtemplate.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import template` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `template`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Renderiza templates Mustache com auto-escape simples, HTML ou LaTeX |
| `tmpl escape html / tmpl escape latex` | Escapa `& < > " '` para HTML ou `\ { } & % $ # _ ~ ^` para LaTeX |
| `tmpl extract vars / tmpl has unclosed tags` | Extrai os nomes das variáveis necessárias e valida o fecho das etiquetas |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `template`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import template

fn :: renderizar perfil html (usuario : String) (es_admin : String) => String
      renderizar perfil html usuario es_admin =
        plantilla = "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}"
        vars      = [("user", usuario), ("admin", es_admin)]
        tmpl render html plantilla vars
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `template` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import template

fn :: generar linea latex (metrica : String) => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Prevenção de XSS por omissão em `tmpl render html` (escapando `&`, `<`, `>`, `"`, `'`), enquanto `{{{var}}}` permite injetar fragmentos confiáveis explicitamente.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_template.rg`.
