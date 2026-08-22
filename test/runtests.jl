using Test
using Random
using LinearAlgebra
using FactorVSA          # the resonator-VSA substrate (algebra/resonator/codebooks)
using HMH                # R-HMH (§8) + ColBaC-HDC (§9) application layers

@testset "HMH" begin

    @testset "R-HMH — roles CONTENT-seeded (cross-process reproducible; regression)" begin
        # Two INDEPENDENT RoleBooks stand in for two processes. Pre-fix, role! drew from the global
        # RNG in first-touch order, so these were unequal — encode in one process, decode in another
        # → garbage. Content-seeding makes name → vector a pure function. This gate FAILED before the fix.
        D = 8192
        rb1 = RoleBook(D)
        rb2 = RoleBook(D)
        @test role!(rb1, :actor).data == role!(rb2, :actor).data     # same name → same vector, cross-instance
        @test role!(rb1, :actor).data != role!(rb1, :patient).data   # distinct names → distinct vectors
    end

    @testset "R-HMH — episode encode + resonant recall (§8, 5a/5b)" begin
        Random.seed!(20260606)
        D = 4096
        rb = RoleBook(D)
        cbA = random_codebook(BipolarMAP, D, 16)
        cbB = random_codebook(BipolarMAP, D, 16)
        fa = HV{BipolarMAP}(cbA.atoms[:, 5])
        fb = HV{BipolarMAP}(cbB.atoms[:, 11])
        slots = Dict(:actor => (:agent, fa), :object => (:thing, fb))

        H = encode_episode(Episode(random_hv(BipolarMAP, D); slots=slots), rb)
        @test recover_slot(H, :actor, :agent, rb, cbA) == fa
        @test recover_slot(H, :object, :thing, rb, cbB) == fb

        H2 = encode_episode(
            Episode(random_hv(BipolarMAP, D); slots=slots,
                relations=[(:acts_on, :actor, :object)]), rb)
        @test recover_slot(H2, :actor, :agent, rb, cbA) == fa
        @test recover_slot(H2, :object, :thing, rb, cbB) == fb

        c1 = random_codebook(BipolarMAP, D, 10)
        c2 = random_codebook(BipolarMAP, D, 10)
        p1 = HV{BipolarMAP}(c1.atoms[:, 3])
        p2 = HV{BipolarMAP}(c2.atoms[:, 8])
        H3 = encode_episode(
            Episode(random_hv(BipolarMAP, D); slots=Dict(:goal => (:plan, bind(p1, p2)))),
            rb)
        facs, score = complete_slot(H3, :goal, :plan, rb, [c1, c2])
        @test facs[1] == p1 && facs[2] == p2
        @test score > 0.3      # in-episode (projected bundle) — NOT a bare-product cutoff
    end

    @testset "R-HMH — episodic-semantic consolidation (§8, Eq 77)" begin
        Random.seed!(20260606)
        D = 4096
        rb = RoleBook(D)
        cbAct = random_codebook(BipolarMAP, D, 8)
        cbObj = random_codebook(BipolarMAP, D, 8)
        fa = HV{BipolarMAP}(cbAct.atoms[:, 2])
        eps = [
            Episode(random_hv(BipolarMAP, D);
                slots=Dict(:actor => (:agent, fa),
                    :object => (:thing, HV{BipolarMAP}(cbObj.atoms[:, i])))) for i in 1:8
        ]
        tmpl = consolidate(eps, rb)
        @test recover_slot(tmpl, :actor, :agent, rb, cbAct) == fa
        m_actor = cleanup_margin_of(
            bind(role!(rb, Symbol("mtype_", :agent)), bind(role!(rb, :actor), tmpl)), cbAct)
        m_object = cleanup_margin_of(
            bind(role!(rb, Symbol("mtype_", :thing)), bind(role!(rb, :object), tmpl)), cbObj
        )
        @test m_actor > m_object
        @test tmpl isa HV{BipolarMAP}
    end

    @testset "ColBaC-HDC — representation layer (§9, Eq 84-90)" begin
        Random.seed!(20260606)
        D = 4096
        rb = RoleBook(D)
        cbM = random_codebook(BipolarMAP, D, 16)
        m1 = HV{BipolarMAP}(cbM.atoms[:, 4])
        m2 = HV{BipolarMAP}(cbM.atoms[:, 9])
        m3 = HV{BipolarMAP}(cbM.atoms[:, 1])
        col = Column([(:K, 0, :center, m1), (:L, 1, :lateral, m2), (:B, 2, :bridge, m3)])
        Hm = encode_column(col, rb)

        @test recover_motif(Hm, :K, 0, :center, rb, cbM) == m1
        @test recover_motif(Hm, :B, 2, :bridge, rb, cbM) == m3

        colB = Column([(:K, 0, :center, HV{BipolarMAP}(cbM.atoms[:, 7]))])
        enc = Dict(1 => Hm, 2 => encode_column(colB, rb))
        HS = support_code(enc, [1, 2], rb)
        @test dot(bind(role!(rb, Symbol("col_", 1)), HS).data, Hm.data) / D > 0.3

        cbCh = random_codebook(BipolarMAP, D, 8)
        zshared = HV{BipolarMAP}(cbCh.atoms[:, 3])
        Z = certificate(Dict(:shared => zshared), Hm, rb)
        @test cleanup(bind(role!(rb, :cert_shared), Z), cbCh) == zshared

        @test cleanup_margin_of(m1, cbM) > 0
        @test confusability(m1, cbM; gamma=0.01) == 1
    end
end

@testset "§8.6 admissibility gate — the R-HMH go/no-go, WIRED" begin
    # 🔴 THIS GATE EXISTED AND NOTHING RAN IT. `bench/step5_gate.jl` is the R-HMH episodic
    # admissibility oracle — its own header calls it the "Go/no-go for building 5c/5d" — and
    # `hmh_context_gating_spec.md` §7 CITES IT AS EVIDENCE. It was referenced by neither this suite
    # nor any script. Measured 2026-08-21: it PASSES, and that result had been invisible.
    #
    # That is the shape the port-inventory ratchet records for `cmp_pure.jl`: a real measurement
    # sitting beside an unwired harness — "knowledge that nothing executes changes nothing".
    # [[feedback_verify_the_oracle_runs]] · [[feedback_enforcement_works_prose_memory_does_not]]
    #
    # ⚠️ THE NEGATIVE CONTROL IS THE LOAD-BEARING HALF, not the recovery number. Its header says the
    # sweep "must PUSH PAST that boundary so its negative control actually exercises degradation
    # (else it's measuring only the easy regime — the E3 anti-gaming lesson from Step-4)". A gate
    # whose control does not collapse is measuring nothing, however green it reads.
    #
    # Trials are reduced from the bench's 80 to keep the suite fast; the full sweep stays in
    # bench/step5_gate.jl. Seeded, so this is deterministic rather than flaky-by-design.
    Random.seed!(20260606)

    # A REALISTIC episode (k_slot=10, k_rel=5, M=16) must recover at a FEASIBLE dimension.
    # Bench measured 0.989 at D=512 and 1.000 at D>=1024; HMHStore's default D is 1024.
    r_1024 = episode_recovery_rate(1024, 10, 5, 16; trials=40)
    @test r_1024 >= 0.95

    # THE NEGATIVE CONTROL: push past the D/(2 ln M) capacity bound and recovery MUST collapse.
    # Bench at D=512, M=64: 0.997 (k_slot=8) -> 0.136 (k_slot=256).
    easy = episode_recovery_rate(512, 8, 0, 64; trials=40)
    hard = episode_recovery_rate(512, 256, 0, 64; trials=40)
    @test easy > 0.9                     # the easy regime really is easy…
    @test hard < 0.4                     # …and the overloaded one really does degrade
    @test easy - hard > 0.5              # ⇐ the anti-gaming assertion: the gate discriminates
end

println("HMH tests passed ✓")
