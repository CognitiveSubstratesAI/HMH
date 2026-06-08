# HMH.jl

[![CI](https://github.com/CognitiveSubstratesAI/HMH/actions/workflows/CI.yml/badge.svg)](https://github.com/CognitiveSubstratesAI/HMH/actions/workflows/CI.yml)
[![docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://cognitivesubstratesai.github.io/HMH/stable/)

**Hierarchical Modular Hypervector** application layer — typed, role-filler memory and
representation built on the [FactorVSA](https://github.com/CognitiveSubstratesAI/FactorVSA)
resonator-VSA substrate. It hosts two application schemas over **one** shared encoder
(the paper's Eq 84 *is* Eq 11 specialized):

| Tower | What | Status |
|-------|------|--------|
| **R-HMH** (§8) | Episodic memory — compile an episode into one hypervector, recall slots by role, complete product fillers with the resonator, consolidate episodes into schemas | a **working** leg, margin-gate-verified |
| **ColBaC-HDC** (§9) | The HDC representation a causal-coding learner *consumes* — column / support / certificate encoders + audit quantities | a **representation substrate** (synthetic columns); **not** a working ColBaC learner (that's the [NGC/FabricPC](https://github.com/CognitiveSubstratesAI) line) |

Source: Goertzel (2026), *"Resonator-Factored Hierarchical Hypervector Embeddings"*.
`HMH` is the general construction; R-HMH and ColBaC-HDC are two applications *of* it — so this
package, holding both, is `HMH.jl`.

## Why

An episode with factorized structure (actor, object, action, place, relations…) is **not**
collapsed into an opaque embedding. It is compiled into a typed role-filler hypervector whose
algebra lets you **recall any role-bound part** — "who was the actor?", "complete the missing
outcome" — by unbinding a role and cleaning up, rather than scanning the whole episode.
Recall is reliable while the role-bound load stays within `k_slot + k_rel ≲ D / (2·ln M)`
(a measured capacity law, not raw episode size).

## Install

```julia
pkg> add FactorVSA HMH        # dev the local checkouts until registered
```

## Quick example

```julia
using FactorVSA, HMH, Random
Random.seed!(1)
D = 4096

rb = RoleBook(D)                                     # named role atoms
actors  = random_codebook(BipolarMAP, D, 8)          # possible actors
teacher = HV{BipolarMAP}(actors.atoms[:, 3])

E = Episode(random_hv(BipolarMAP, D);                # an episode…
    slots = Dict(:actor => (:agent, teacher)))
H = encode_episode(E, rb)                            # …compiled to ONE hypervector

recover_slot(H, :actor, :agent, rb, actors) == teacher   # true — recall the actor
```

See the **[Guide](https://cognitivesubstratesai.github.io/HMH/stable/guide/)** for episodes,
resonant completion, consolidation, and the ColBaC-HDC layer (all runnable), and the
**[API](https://cognitivesubstratesai.github.io/HMH/stable/api/)** for full signatures.

## Margin gate

R-HMH's headline property — episodes are HDC-admissible at feasible dimension — is enforced by
a margin gate (`bench/step5_gate.jl`, run in CI). It confirms recovery traces the capacity
boundary `k ≈ D/(2·ln M)`, the negative control collapses with load (a *real* test, not
lossless), and realistic episodes (≈10 slots, ≈5 relations) recover ≥0.95 at D=512. See
[`STEP5_GATE_RESULT.md`](STEP5_GATE_RESULT.md).

## Scope

Built: R-HMH (encode / recall / consolidate) and the ColBaC-HDC representation layer (Eq 84–90)
on synthetic columns. **Out of scope / fenced:** §8.4 neural judgment (densifier `𝒟_hmh` + a
neural model) and the ColBaC *learner* itself (a separate causal-coding architecture).

## Dependency chain

`HMH → FactorVSA → MORK → PathMap` — clean and downward-only.
