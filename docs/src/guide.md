```@meta
CurrentModule = HMH
```

# Guide

A runnable walk-through of both towers. Every code block below is executed when these docs
are built, so the outputs are real.

```@setup guide
using FactorVSA, HMH, Random
Random.seed!(20260606)
D = 4096
```

## Roles and codebooks

A [`RoleBook`](@ref) hands out a stable random hypervector for each named role (lazily, once
per name). A *codebook* (`FactorVSA.Codebook`) is the dictionary a noisy vector is cleaned up
against — the set of legal fillers for a slot.

```@example guide
rb = RoleBook(D)
actors  = random_codebook(BipolarMAP, D, 8)    # 8 possible actors
objects = random_codebook(BipolarMAP, D, 8)    # 8 possible objects
length(actors)
```

## Encoding an episode (§8.2, Eq 69)

An [`Episode`](@ref) is a typed factor graph: `role => (type, filler)` slots, typed relations
between slots, and optional anchors. [`encode_episode`](@ref) compiles it into **one**
fixed-width hypervector — `r_schema⊗h_σ ⊕ Σ_s m_τ(s)⊗r_s⊗h_{f_s} ⊕ Σ r_ρ⊗r_i⊗r_j⊗(h_{f_i}⊗h_{f_j})`.

```@example guide
teacher = HV{BipolarMAP}(actors.atoms[:, 3])
book    = HV{BipolarMAP}(objects.atoms[:, 5])

E = Episode(random_hv(BipolarMAP, D);
    slots     = Dict(:actor => (:agent, teacher), :object => (:thing, book)),
    relations = [(:reads, :actor, :object)])
H = encode_episode(E, rb)
dim(H)               # the whole episode is one D-dimensional vector
```

## Resonant recall (§8.3, Eq 73)

[`recover_slot`](@ref) unbinds a slot's role (other slots + the relation are bounded
crosstalk) and cleans the result against that slot's codebook:

```@example guide
recover_slot(H, :actor,  :agent, rb, actors)  == teacher
```

```@example guide
recover_slot(H, :object, :thing, rb, objects) == book
```

When a filler is itself a **product** of factor atoms, [`complete_slot`](@ref) runs the
resonator *inside* the episode to recover them:

```@example guide
c1 = random_codebook(BipolarMAP, D, 10)
c2 = random_codebook(BipolarMAP, D, 10)
goal = bind(HV{BipolarMAP}(c1.atoms[:, 4]), HV{BipolarMAP}(c2.atoms[:, 7]))

Hg = encode_episode(Episode(random_hv(BipolarMAP, D);
    slots = Dict(:goal => (:plan, goal))), rb)
factors, score = complete_slot(Hg, :goal, :plan, rb, [c1, c2])
(factors[1] == HV{BipolarMAP}(c1.atoms[:, 4]),
 factors[2] == HV{BipolarMAP}(c2.atoms[:, 7]))
```

(The recompose `score` is ~0.5 here, not ~1: a slot is unbound from a *projected* episode
bundle, so it is noisier than a bare product. The true tuple still dominates spurious ones,
so rejection works — just at a lower absolute margin. Do not reuse bare-product thresholds
inside episodes.)

## Consolidation into a schema (§8.5, Eq 77)

[`consolidate`](@ref) bundles aligned episodes into a template. Slots whose filler **recurs**
reinforce; idiosyncratic fillers wash out — schema formation. The template is a *new
immutable* hypervector; consolidation never mutates a codebook.

```@example guide
common = HV{BipolarMAP}(actors.atoms[:, 2])    # same actor across episodes
episodes = [Episode(random_hv(BipolarMAP, D);
    slots = Dict(:actor  => (:agent, common),
                 :object => (:thing, HV{BipolarMAP}(objects.atoms[:, i])))) for i in 1:8]

template = consolidate(episodes, rb)
recover_slot(template, :actor, :agent, rb, actors) == common   # the recurring slot survives
```

## ColBaC-HDC representation layer (§9, Eq 84-90)

The same machinery, a columnar schema. A [`Column`](@ref)'s motifs are triple-tagged by
microcolumn type (`:K`/`:L`/`:B`), shell tier (`0..3`), and local role.
[`encode_column`](@ref) is Eq 84; [`recover_motif`](@ref) reads any tagged piece back.

```@example guide
motifs = random_codebook(BipolarMAP, D, 16)
col = Column([(:K, 0, :center,  HV{BipolarMAP}(motifs.atoms[:, 4])),
              (:L, 1, :lateral, HV{BipolarMAP}(motifs.atoms[:, 9])),
              (:B, 2, :bridge,  HV{BipolarMAP}(motifs.atoms[:, 1]))])
Hc = encode_column(col, rb)
recover_motif(Hc, :K, 0, :center, rb, motifs) == HV{BipolarMAP}(motifs.atoms[:, 4])
```

The HDC **audit quantities** a learner would use for shell hygiene — cleanup margin Δ
([`cleanup_margin_of`](@ref), Lemma 1) and confusability `M_conf` ([`confusability`](@ref),
Eq 54):

```@example guide
clean = HV{BipolarMAP}(motifs.atoms[:, 4])
(cleanup_margin_of(clean, motifs), confusability(clean, motifs; gamma=0.01))
```

A clean atom has a positive margin and is unambiguous (`M_conf == 1`).
[`support_code`](@ref) (Eq 85) and [`certificate`](@ref) (Eq 86-87) compose columns and their
certificates the same way — see the [API](api.md).
