#!/usr/bin/env julia
# tools/repl.jl — warm development REPL for HMH (mirrors FactorVSA's / MORK's tools/repl.jl).
#
# Interactive (recommended — Revise hot-reload, no restart on function edits):
#   julia --project=. -i tools/repl.jl
# Scripted (pipe a targeted snippet — foreground, NO background, NO polling):
#   printf 'include("/tmp/snippet.jl")\n' | julia --project=. -i tools/repl.jl
#
# NEVER cold-start a fresh `julia test/runtests.jl` for iteration — run a TARGETED snippet here
# and debug with @show / println / @info. Re-run t() only for the final full-suite gate (which
# doubles as the HMH->FactorVSA->MORK->PathMap contract-still-binds check at HEAD).
#
# Dev tools (Revise, BenchmarkTools, JET, ...) live in the GLOBAL env on the default LOAD_PATH,
# so they load here WITHOUT being HMH dependencies. HMH is pure FactorVSA algebra (R-HMH §8 +
# ColBaC-HDC §9) — it has NO MORK grounded ops, so there is nothing to register here. If you want
# to explore FactorVSA's grounded (fvsa-*) surface from this REPL, call
# `FactorVSA.register_factorvsa!()` yourself.
#
# NOTE (Revise limitation): editing a STRUCT's fields needs a fresh session; function-body edits
# hot-reload in place. Editing the FactorVSA EXTENSION/ext files is not hot-reloaded either.

try; using Revise; catch; @warn "Revise unavailable — install into the global env for hot-reload"; end

using FactorVSA          # the resonator-VSA substrate HMH builds on (algebra/resonator/codebooks)
using HMH                # R-HMH (§8) + ColBaC-HDC (§9)
using Test, Random, LinearAlgebra

"Run the full HMH test suite from the warm session (also the contract-binds-at-HEAD gate)."
t() = include(joinpath(dirname(@__DIR__), "test", "runtests.jl"))

if isinteractive()
    println("HMH REPL ready — Revise tracking src/, FactorVSA algebra available.")
    println("  t()  — full suite / contract gate")
    println("  on-demand: `using BenchmarkTools` / `using JET` (global env)")
end
