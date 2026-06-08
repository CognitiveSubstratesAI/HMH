"""
    HMH

HMH.jl — Hierarchical Modular Hypervector application layer. Hosts **R-HMH episodic
memory (§8)** and **ColBaC-HDC representation (§9)**, both schemas over the shared HMH
encoder (Eq 11 / Eq 84), built on the [FactorVSA](https://github.com/CognitiveSubstratesAI/FactorVSA)
resonator-VSA substrate. Source: Goertzel (2026), *"Resonator-Factored Hierarchical
Hypervector Embeddings"*.

`HMH` is the general construction; R-HMH is its resonant-episodic application and ColBaC-HDC
is another application of the same HMH base — so this package, holding both, is HMH.jl
(not a contraction of R-HMH).

**Two kinds of "done":** R-HMH is a WORKING episodic-memory leg (encode / resonant recall /
consolidation, margin-gate-verified at feasible D). ColBaC-HDC is the REPRESENTATION
SUBSTRATE a causal-coding learner would consume (column / support / certificate encoders +
HDC audit quantities, tested on synthetic columns) — NOT a working ColBaC learner, which is
the separate NGC/FabricPC line.

Use with `using FactorVSA, HMH` (HMH builds on, and does not re-export, FactorVSA's algebra).
"""
module HMH

using FactorVSA
using LinearAlgebra
using Random

# §8 — R-HMH episodic memory (5a encode + 5b recall + 5c consolidate + the 5-gate)
include("RHMH.jl")
# §9 — ColBaC-HDC representation layer (Eq 84-90), the same machinery, columnar schema
include("ColBaCHDC.jl")

end # module HMH
