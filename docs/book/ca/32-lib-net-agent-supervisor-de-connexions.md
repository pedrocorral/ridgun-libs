# Capítol 32: La lib `net_agent` — Supervisor de Connexions de Xarxa i Pont d'Esdeveniments No Bloquejant

## 1. Per què existeix la lib `net_agent`?

Siguem sincers: en un servidor real com **Solstice**, acceptar connexions TCP és la part fàcil; el difícil és limitar el màxim de clients simultanis, desconnectar clients zombis inactius (*idle timeout*) i connectar el bucle `ppoll` amb els teus actors sense fuites de descriptors.

La lib **`net_agent`** tanca el cercle de `ridgun-libs` unint **`posix`**, **`socket`** i **`agent`**: gestiona taules de connexions supervisades (`NetSupervisor`), aplica límits de concurrència (`max_conns`), purga connexions inactives (`net evict idle`) i converteix esdeveniments de descriptors del nucli en esdeveniments tipats (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`) a més d'oferir un pas d'eco TCP complet d'extrem a extrem (`net tcp echo step`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`net_agent`** és una **lib** de primera classe situada a `src/main/ridgun/lib/net_agent.rg` (domini `AGENT`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/net_agent.rglib` | Distribució i importació directa amb `import net_agent` |
| **Fitxer compilat** | `target/net_agent.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libnet_agent.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import net_agent` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `net_agent`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | Crea un supervisor de connexions amb límit `max_conns` i inactivitat `idle_timeout_ms` |
| `net register conn / net record rx / net record tx / net close conn` | Registra sockets acceptats, actualitza comptadors de bytes/activitat i tanca parells |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | Tanca i expulsa connexions inactives més enllà d'`idle_timeout_ms`, retornant els seus FDs |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | Pont `wait fd` no bloquejant que emet `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` o `NetEvError` |
| `net tcp echo step : String -> Int -> (Int, String)` | Pas complet d'extrem a extrem TCP loopback (`listen/connect/accept/supervise/echo`) |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `net_agent`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import net_agent

fn :: supervisar clientes () => (Int, [Int])
      supervisar clientes =
        s0        = net supervisor new 100 5000
        (s1, _)   = net register conn s0 10 "10.0.0.1" 51000 1000
        (s2, _)   = net register conn s1 11 "10.0.0.2" 51001 6500
        (s3, exp) = net evict idle s2 7000
        (net active count s3, exp)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `net_agent` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Protecció automàtica enfront d'esgotament de descriptors (`max_conns`), expulsió determinista de connexions inactives i tancament garantit de sockets a `net tcp echo step`.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_net_agent.rg`.
