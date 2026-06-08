```@meta
CurrentModule = HMH
```

# HMH.jl

**Hierarchical Modular Hypervector** application layer — hosts **R-HMH episodic memory (§8)**
and the **ColBaC-HDC representation layer (§9)**, both schemas over the shared HMH encoder
(Eq 11 / Eq 84), built on the
[FactorVSA](https://github.com/CognitiveSubstratesAI/FactorVSA) resonator-VSA substrate.
Source: Goertzel (2026), *"Resonator-Factored Hierarchical Hypervector Embeddings"*.

`HMH` is the general construction; R-HMH is its resonant-episodic application and ColBaC-HDC
is another application of the same base — so this package, holding both, is `HMH.jl`.

## Two kinds of "done"

- **R-HMH** is a **working episodic-memory leg**: `encode_episode` (Eq 69) → role-masked
  `recover_slot` / resonant `complete_slot` (Eq 73) → `consolidate` (Eq 77). Its episodic
  **margin gate PASSES** (`STEP5_GATE_RESULT.md`): realistic episodes (≈10 slots, ≈5
  relations) recover ≥0.95 at D=512, recovery traces the capacity boundary `k ≈ D/(2·ln M)`,
  and the negative control collapses with load (a real test, not lossless).
- **ColBaC-HDC** is the **representation substrate a causal-coding learner would consume**:
  `encode_column` (Eq 84) + `recover_motif`, `support_code` (Eq 85), `certificate` (Eq 86–87),
  and HDC audit quantities (`cleanup_margin_of`, `confusability`, `reuse_score`,
  `promote_signal`) — tested on **synthetic columns**. It is **not** a working ColBaC learner
  (that is the separate NGC/FabricPC line).

## Design bound

Keep an episode's role-bound load within `k_slot + k_rel ≲ D/(2·ln M)` (at D=1024, M=64 that's
~120 terms — comfortable for typed episodes). Beyond that, raise `D` or nest sub-episodes.

## Usage

```julia
using FactorVSA, HMH   # HMH builds on, and does not re-export, FactorVSA's algebra
```

## API reference

```@autodocs
Modules = [HMH]
Order = [:type, :function]
```

## Index

```@index
```
