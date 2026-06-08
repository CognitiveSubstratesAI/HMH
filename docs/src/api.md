```@meta
CurrentModule = HMH
```

# API Reference

All names below are exported by `HMH`. The algebra they build on (`HV`, `bind`, `cleanup`,
`factorize`, `random_hv`, `random_codebook`, `Codebook`, …) lives in
[FactorVSA](https://github.com/CognitiveSubstratesAI/FactorVSA); use `using FactorVSA, HMH`.

## R-HMH — episodic memory (§8)

```@docs
RoleBook
role!
Episode
encode_episode
recover_slot
complete_slot
consolidate
episode_recovery_rate
```

## ColBaC-HDC — representation layer (§9)

```@docs
Column
encode_column
recover_motif
support_code
certificate
cleanup_margin_of
confusability
reuse_score
promote_signal
```

## Index

```@index
```
