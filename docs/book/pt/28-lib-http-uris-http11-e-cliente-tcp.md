# Capítulo 28: A lib `http` — URIs RFC 3986, Codec HTTP/1.1 RFC 9112 e Cliente TCP ao Vivo

## 1. Por que existe a lib `http`?

Sejamos sinceros: se não filtrar quebras `\r\n` nos valores dos cabeçalhos HTTP, um atacante pode injetar cabeçalhos falsos (*CRLF Response Splitting*), e ligar a `libcurl` apenas para fazer um `GET` ou `POST` é um exagero.

A lib **`http`** implementa decomposição de **URIs RFC 3986**, construção e análise de pedidos e respostas **HTTP/1.1 RFC 9112** com higienização automática de CRLF (`VUL-INJ-002`) e `Content-Length` automático, extração de tokens `Bearer` e um **cliente HTTP/1.1 ao vivo sobre sockets TCP do kernel** (`http get`, `http post`, `http request tcp`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`http`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/http.rg` (domínio `HTTP`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/http.rglib` | Distribuição e importação direta com `import http` |
| **Ficheiro compilado** | `target/http.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libhttp.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import http` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `http`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `uri parse / uri scheme / uri host / uri port / uri path / uri query` | Decompõe URIs RFC 3986 com portas padrão automáticas (`80` em `http`, `443` em `https`) |
| `http build request / http parse request` | Formata e analisa pedidos HTTP/1.1 com higienização CRLF de cabeçalhos |
| `http build response / http parse response` | Formata e analisa respostas HTTP/1.1 com frases de estado padrão |
| `http header get / http bearer token` | Pesquisa de cabeçalhos insensível a maiúsculas e extração de `Authorization: Bearer <token>` |
| `http get / http post / http request tcp` | Executa chamadas HTTP/1.1 ao vivo sobre sockets TCP do kernel com `timeout_ms` |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `http`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import http

fn :: inspeccionar endpoint (url : String) => (String, Int, String, String)
      inspeccionar endpoint url =
        host = uri host url
        port = uri port url
        path = uri path url
        wire = http build request "GET" path [("Host", host)] ""
        (host, port, path, wire)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `http` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import http

fn :: extraer credenciales (raw_req : String) => (String, String)
      extraer credenciales raw_req =
        (metodo, ruta, _, hdrs_raw, _) = http parse request raw_req
        hdrs = http parse headers hdrs_raw
        tok  = http bearer token hdrs
        (metodo + " " + ruta, tok)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Higienização automática de `\r` e `\n` em todos os cabeçalhos (`http sanitize header`) para impedir ataques de divisão de resposta HTTP.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_http.rg`.
