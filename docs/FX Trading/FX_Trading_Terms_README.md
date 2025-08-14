# Foreign Exchange (FX) Trading Terms — GitHub Compatible

This README explains common FX trading terms and includes **Mermaid** flow diagrams.  
To maximize GitHub compatibility, diagrams use **simple shapes** and **no edge labels**.

## Contents
- [Blotter Session](#1-blotter-session)
- [Block Session](#2-block-session)
- [Mix Blotter and Block](#3-mix-blotter-and-block)
- [Algo Trading](#4-algo-trading)
- [Slice Trading](#5-slice-trading)
- [Allocation](#6-allocation)
- [Automated Order Router](#7-automated-order-router)
- [Basket Benchmark](#8-basket-benchmark)
- [Basket CP](#9-basket-cp)
- [Benchmark CP](#10-benchmark-cp)
- [Competitive Trading](#11-competitive-trading)
- [Portfolio Trading](#12-portfolio-trading)
- [RFQ Trading](#13-rfq-trading)
- [RFS Trading](#14-rfs-trading)
- [RFS Multivalue Date Trading](#15-rfs-multivalue-date-trading)

---

## 1. Blotter Session
A **Blotter Session** is a trading view that shows executed, working, and canceled orders/trades for a trader or desk. Refers to a trading interface or system view that displays all executed, pending, and canceled trades for a trader or trading desk within a given session.  
- Functions as an electronic "trade journal."
- Includes trade details such as currency pairs, amounts, execution rates, counterparties, timestamps, and settlement dates.
- Allows traders to monitor live trade activity and manage post-trade actions such as confirmations and allocations.
- Often integrated with back-office and middle-office systems for compliance and reporting.
- Real-time monitoring of fills, amendments, cancels.
- Key fields: pair, side, notional, rate, value date, counterparty, timestamps, status.
- Integrates with middle/back office for confirmations, allocations, and reporting.

```mermaid
flowchart LR
  T(Trader) --> OMS[Order Management System]
  OMS --> EMS[Execution Venues]
  EMS --> OMS
  OMS --> BLOTTER[Blotter UI]
  BLOTTER --> BO[Middle Back Office]
  BO --> BLOTTER
```

## 2. Block Session
A **Block Session** enables execution of large FX tickets (blocks) in a single or negotiated trade. Is a trading session designed for executing large FX trades (blocks) in a single transaction rather than splitting them into smaller trades.  
- Reduces market exposure by limiting the time a large order is in the market.
- Typically negotiated directly with counterparties or via platforms that support block trade functionality.
- May require pre-arranged credit limits and agreements due to trade size.
- Used by institutions to manage large position adjustments or client flows.
- Minimizes signaling and market impact.
- Often requires pre-negotiated credit and custom workflows.

```mermaid
flowchart LR
  PM(Portfolio Manager) --> TRADER(Trader)
  TRADER --> PLATFORM[Block Trading Platform]
  PLATFORM --> LPS{Liquidity Providers}
  LPS --> PLATFORM
  PLATFORM --> STP[Settlement and STP]
```

## 3. Mix Blotter and Block
A **hybrid session** combining a live blotter with block-trade capabilities in one interface.
- Single pane of glass for day-to-day flow and large tickets.

```mermaid
flowchart LR
  UI[Unified UI] --> BVIEW[Blotter View]
  UI --> BPANEL[Block Ticket Panel]
  BVIEW --> OMS
  BPANEL --> OMS
  OMS --> VENUES[(Venues)]
```

## 4. Algo Trading
**Algorithmic execution** uses strategies (e.g., TWAP, VWAP, POV) to optimize execution quality and reduce impact.

```mermaid
flowchart LR
  TRADER --> PARENT[Parent Order]
  PARENT --> ALGO[Algo Strategy]
  ALGO --> C1((Child Order 1))
  ALGO --> C2((Child Order 2))
  C1 --> VENUES[(Venues)]
  C2 --> VENUES
  VENUES --> ALGO
  ALGO --> BLOTTER[Blotter]
```

## 5. Slice Trading
**Slice Trading** breaks a large order into smaller pieces—manual or algo-driven.

```mermaid
flowchart LR
  PARENT[Large Order] --> S1[Slice 1]
  PARENT --> S2[Slice 2]
  PARENT --> S3[Slice 3]
  S1 --> V1[Venue 1]
  S2 --> V2[Venue 2]
  S3 --> V3[Venue 3]
```

## 6. Allocation
**Allocation** assigns portions of a filled trade to funds/accounts post-execution or via pre-trade rules.

```mermaid
flowchart LR
  FILL[Executed Fill] --> ENGINE[Allocation Engine]
  ENGINE --> A[Fund A]
  ENGINE --> B[Fund B]
  ENGINE --> C[Fund C]
  A --> BOOKS[Books and Records]
  B --> BOOKS
  C --> BOOKS
  BOOKS --> CONF[Confirmations]
```

## 7. Automated Order Router
An **Automated Order Router (AOR)** routes orders to venues using rules and real-time signals.

```mermaid
flowchart LR
  OMS --> AOR[Automated Order Router]
  AOR --> CREDIT[Credit Check]
  AOR --> POLICY[Routing Policy]
  POLICY --> V1[(LP 1)]
  POLICY --> V2[(LP 2)]
  V1 --> OMS
  V2 --> OMS
```

## 8. Basket Benchmark
Execute a multi-currency **basket** against a **benchmark** (e.g., WM 4pm).

```mermaid
flowchart LR
  PM --> BASKET[Basket Orders]
  BASKET --> BENCH[Benchmark Window]
  BENCH --> EXEC[Coordinated Execution]
  EXEC --> ATTR[Attribution]
```

## 9. Basket CP
Execute a **basket** with a single **counterparty** to simplify operations and credit.

```mermaid
flowchart LR
  BASKET[Multi Currency Basket] --> CP[Single Counterparty]
  CP --> TRADE[Package Trade]
  TRADE --> OPS[Unified Settlement]
```

## 10. Benchmark CP
Execute with a designated **counterparty** who provides **benchmark-based** pricing (e.g., guaranteed fix).

```mermaid
flowchart LR
  PM --> CP[Benchmark Counterparty]
  CP --> FIX[Fixing Price]
  FIX --> TRADE[Trade at Benchmark]
  TRADE --> REPORT[Reporting]
```

## 11. Competitive Trading
Multiple LPs compete to quote; trader selects the best price.

```mermaid
flowchart LR
  TRADER --> RFQ[RFQ Request]
  RFQ --> LP1[LP 1]
  RFQ --> LP2[LP 2]
  RFQ --> LP3[LP 3]
  LP1 --> DECISION{Decision}
  LP2 --> DECISION
  LP3 --> DECISION
  DECISION --> EXEC[Execute Trade]
```

## 12. Portfolio Trading
Execute a **set of trades** as part of a portfolio-wide optimization.

```mermaid
flowchart LR
  PORT[Portfolio Targets] --> OPT[Optimizer]
  OPT --> NET[Netting]
  OPT --> SCHED[Execution Schedule]
  SCHED --> VENUES[(Venues)]
  VENUES --> BLOTTER[Consolidated Blotter]
```

## 13. RFQ Trading
**Request for Quote (RFQ)**: solicit quotes for a specific ticket; accept the best.

```mermaid
flowchart LR
  TRADER --> SPEC[Ticket Spec]
  SPEC --> SEND[Send RFQ]
  SEND --> LPS{Counterparties}
  LPS --> REPLIES[Quotes]
  REPLIES --> CHOOSE{Accept or Reject}
  CHOOSE --> EXEC[Execute]
```

## 14. RFS Trading
**Request for Stream (RFS)**: counterparty streams updating executable prices for a defined time/size.

```mermaid
flowchart LR
  TRADER --> RFSREQ[RFS Request]
  RFSREQ --> LP[Liquidity Provider]
  LP --> STREAM[Executable Stream]
  STREAM --> TRADER
  STREAM --> END[(Session End)]
```

## 15. RFS Multivalue Date Trading
RFS variant enabling **multiple value dates** within the same streaming session.

```mermaid
flowchart LR
  TRADER --> RFSREQ[RFS Request With Dates]
  RFSREQ --> LPE[LP Stream Engine]
  LPE --> STREAMS[Streams Per Value Date]
  STREAMS --> F1[Spot Trade]
  STREAMS --> F2[Forward 1]
  STREAMS --> F3[Forward 2]
  F1 --> BLOTTER[Blotter]
  F2 --> BLOTTER
  F3 --> BLOTTER
```

---

### Notes
- Keep Mermaid blocks fenced with triple backticks and a blank line before and after each block.
- Avoid special characters in edge labels; this README omits edge labels for maximum compatibility.
