# Capítulo 27: A lib `socket` — TCP, UDP, AF_UNIX, Framing, DNS RFC 1035 e Kernel Sockets (`RGF-001`)

## 1. Por que existe a lib `socket`?

Sejamos sinceros: programar sockets BSD em C com `struct sockaddr_in`, `htons`, `inet_pton` e `getaddrinfo` (que ainda por cima arrasta a `libnss` da `glibc`) é um ritual arcano dos anos 80.

A lib **`socket`** oferece duas camadas complementares sem uma linha de C: (1) a API de descritores do kernel **`RGF-001`** para servidores de produção como o **Solstice** (`sys tcp listen`, `sys tcp listen reuseport`, `sys accept`, `sys tcp connect`, `sys send`, `sys recv`, `sys resolve ipv4` via `/etc/hosts` + pacotes DNS UDP RFC 1035 na porta 53) e (2) a máquina de estados funcional imutável `Socket` com framing por comprimento, linhas CRLF e sub-redes CIDR.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`socket`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/socket.rg` (domínio `SOCK`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/socket.rglib` | Distribuição e importação direta com `import socket` |
| **Ficheiro compilado** | `target/socket.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libsocket.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import socket` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `socket`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `sys tcp listen / sys tcp listen reuseport / sys unix listen` | Associa e escuta em TCP IPv4 (`SO_REUSEADDR` / `SO_REUSEPORT`) ou `AF_UNIX` |
| `sys accept / sys tcp connect / sys unix connect` | `accept` e `connect` limitados por timeout devolvendo `SockFdResult` / `SockAcceptResult` |
| `sys send / sys recv / sys shutdown write` | Envio, receção e fecho de escrita (`SHUT_WR`) de socket com timeout |
| `sys resolve ipv4 / dns resolve a` | Resolução IPv4 pura em Ridgun via `/etc/hosts` e consultas DNS UDP RFC 1035 |
| `sock send frame / sock recv frame / ipv4 in cidr` | Framing prefixado por comprimento (`N:payload`) e correspondência de sub-redes CIDR IPv4 |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `socket`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import socket

fn :: eco tcp local () => String
      eco tcp local =
        l_res = sys tcp listen "127.0.0.1" 0 16
        lfd   = sock fd l_res
        port  = sys local port lfd
        c_res = sys tcp connect "127.0.0.1" port 1000
        cfd   = sock fd c_res
        a_res = sys accept lfd 1000
        sfd   = sock accept fd a_res
        _     = sys send cfd "hola-solstice" 1000
        r_res = sys recv sfd 64 1000
        datos = sock recv data r_res
        _     = sys_close cfd
        _     = sys_close sfd
        _     = sys_close lfd
        datos
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `socket` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import socket

fn :: verificar ip interna (ip : String) => Bool
      verificar ip interna ip =
        ipv4 in cidr ip "10.0.0.0/8"
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Atualização de registos com sintaxe imutável `s with field = val`, resolução DNS sem `glibc`/`libnss` e códigos de estado determinísticos (`0` OK, `-1` EOF, `-2` TIMEOUT, `-3` REFUSED).
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_socket.rg`.
