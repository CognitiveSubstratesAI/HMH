```@meta
CurrentModule = HMH
```

# HMH.jl

**Hierarchical Modular Hypervector** application layer — typed, role-filler memory and
representation built on the [FactorVSA](https://github.com/CognitiveSubstratesAI/FactorVSA)
resonator-VSA substrate. It hosts two application schemas over **one** shared encoder
(the paper's Eq 84 *is* Eq 11 specialized):

| Tower | What | Status |
|-------|------|--------|
| **R-HMH** (§8) | Episodic memory — compile an episode into one hypervector, recall slots by role, complete product fillers with the resonator, consolidate episodes into schemas | a **working** leg, margin-gate-verified |
| **ColBaC-HDC** (§9) | The HDC representation a causal-coding learner *consumes* — column / support / certificate encoders + audit quantities | a **representation substrate** (synthetic columns); **not** a working ColBaC learner (that's the NGC line) |

Source: Goertzel (2026), *"Resonator-Factored Hierarchical Hypervector Embeddings"*.
`HMH` is the general construction; R-HMH and ColBaC-HDC are two applications *of* it — so
this package, holding both, is `HMH.jl`.

## Why hypervector memory?

An episode with factorized structure (actor, object, action, place, relations…) is **not**
collapsed into an opaque embedding. It is compiled into a typed role-filler hypervector whose
algebra lets you **recall any role-bound part** — "who was the actor?", "complete the missing
outcome" — by unbinding a role and cleaning up, rather than scanning the whole episode. The
cost is governed by a capacity law, not by raw episode size: recall is reliable while the
role-bound load stays within `k_slot + k_rel ≲ D / (2·ln M)`.

## Installation

`HMH` depends on `FactorVSA` (dev-linked locally; on the registry once published):

```julia
pkg> add FactorVSA HMH      # or dev the local checkouts
```

```julia
using FactorVSA, HMH        # HMH builds on, and does not re-export, FactorVSA's algebra
```

## 30-second example

```@example quick
using FactorVSA, HMH, Random
Random.seed!(1)
D = 4096

rb = RoleBook(D)                                   # named role atoms
actors = random_codebook(BipolarMAP, D, 8)         # a codebook of possible actors
teacher = HV{BipolarMAP}(actors.atoms[:, 3])

E = Episode(random_hv(BipolarMAP, D);              # one episode…
    slots = Dict(:actor => (:agent, teacher)))
H = encode_episode(E, rb)                          # …compiled to ONE hypervector

recover_slot(H, :actor, :agent, rb, actors) == teacher   # recall the actor
```

Next: the [Guide](guide.md) walks through episodes, resonant completion, consolidation, and
the ColBaC-HDC layer with runnable examples. Full signatures are in the [API](api.md).

## Margin gate

R-HMH's headline property — episodes are HDC-admissible at feasible dimension — is enforced
by a margin gate (`bench/step5_gate.jl`, run in CI). It confirms recovery traces the capacity
boundary `k ≈ D/(2·ln M)`, the negative control collapses with load (a *real* test, not
lossless), and realistic episodes (≈10 slots, ≈5 relations) recover ≥0.95 at D=512. See
`STEP5_GATE_RESULT.md`.
