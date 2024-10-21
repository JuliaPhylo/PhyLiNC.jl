fastasimple = joinpath(@__DIR__, "..", "examples", "simple.aln")
fasta8sites = joinpath(@__DIR__, "..", "examples", "Ae_bicornis_8sites.aln") # 8 sites only
fastacontig = joinpath(@__DIR__, "..", "examples", "Ae_bicornis_Tr406_Contig10132.aln")
fasta1missing = joinpath(@__DIR__, "..", "examples", "simple_missingone.aln")
fastaindiv    = joinpath(@__DIR__, "..", "examples", "individuals.aln")
mappingfile   = joinpath(@__DIR__, "..", "examples", "mappingIndividuals.csv")
#= for local trials only, not for automatic testing
  pkgpath = dirname(Base.find_package("PhyLiNC"))
  fastasimple   = abspath(joinpath(pkgpath, "..", "examples", "simple.aln"))
  fasta8sites   = abspath(joinpath(pkgpath, "..", "examples", "Ae_bicornis_8sites.aln"))
  fastacontig   = abspath(joinpath(pkgpath, "..", "examples", "Ae_bicornis_Tr406_Contig10132.aln"))
  fasta1missing = abspath(joinpath(pkgpath, "..", "examples", "simple_missingone.aln"))
  fastaindiv    = abspath(joinpath(pkgpath, "..", "examples", "individuals.aln"))
  mappingfile   = abspath(joinpath(pkgpath, "..", "examples", "mappingIndividuals.csv"))
=#
emptyconstraint = PN.TopologyConstraint[]

@testset "optimize local BL & gammas, simple example" begin
Random.seed!(99)
net_simple = readTopology("(((A:2.0,(B:1.0)#H1:0.1::0.9):1.5,(C:0.6,#H1:1.0::0.1):1.0):0.5,D:2.0);")
obj = StatisticalSubstitutionModel(net_simple, fastasimple, :JC69)

## Local BL
obj.loglik = -Inf64
obj.net.edge[2].length= 0.0 # unzipping
e = PhyLiNC.optimizelocalBL_LiNC!(obj, obj.net.edge[6],
        PhyLiNC.CacheLengthLiNC(obj, 1e-6,1e-6,1e-2,1e-3, 10))
@test length(e) == 4     # not 5: edge below hybrid was excluded
@test obj.loglik > -40.0 # starting likelihood = -43.95468386633092

# ## Local Gamma
γcache = PhyLiNC.CacheGammaLiNC(obj)
hybridmajorparent = getparentedge(obj.net.hybrid[1])
@test_nowarn PhyLiNC.optimizelocalgammas_LiNC!(obj, hybridmajorparent, 1e-6, γcache)
@test hybridmajorparent.gamma != 0.9
@test getparentedgeminor(obj.net.hybrid[1]).gamma != 0.1
end

@testset "optimize local BL & gammas, complex network and 8 sites" begin
Random.seed!(98)
# net from fasta8sites, fuseedgesat! 93, then pruned to the 22 leaves with data, 3 hybrids
net = readTopology("(H_vulgare_HVens23,(((Ae_speltoides_Tr251)H3,(Ae_mutica_Tr237)#H4:::0.6),((((((Ae_caudata_Tr139,Ae_caudata_Tr275))#H1:::0.6,#H2:::0.4),#H1:::0.4),((Ae_comosa_Tr271,Ae_comosa_Tr272),((Ae_uniaristata_Tr403,Ae_uniaristata_Tr357),Ae_uniaristata_Tr402))),(((Ae_tauschii_Tr352,Ae_tauschii_Tr351),Ae_tauschii_Tr125),(((((((Ae_longissima_Tr241,Ae_longissima_Tr242),Ae_longissima_Tr355),Ae_sharonensis_Tr265),((Ae_bicornis_Tr408,Ae_bicornis_Tr407),Ae_bicornis_Tr406)),(Ae_searsii_Tr164,Ae_searsii_Tr165)))#H2:::0.6,#H4:::0.4)))));")
obj = StatisticalSubstitutionModel(net, fasta8sites, :JC69)
preorder!(obj.net)
PhyLiNC.checknetwork_LiNC!(obj.net, 3, true, true, emptyconstraint)
# checknetwork removes degree-2 nodes (including root) and 2- and 3-cycles
# and requires that the network is preordered.
PhyLiNC.updateSSM!(obj, true; constraints=emptyconstraint)
PN.startingBL!(obj.net, obj.trait, obj.siteweight)
PN.unzip_canonical!(obj.net)
## Local BL
lcache = PhyLiNC.CacheLengthLiNC(obj, 1e-6,1e-6,1e-2,1e-3, 5)
obj.loglik = +Inf64
PhyLiNC.optimizelocalBL_LiNC!(obj, obj.net.edge[27], lcache)
obj.loglik = -Inf64
@test_nowarn PhyLiNC.optimizelocalBL_LiNC!(obj, obj.net.edge[27], lcache)
@test obj.net.edge[27].length ≈ 1e-8 atol=.0001
@test obj.net.edge[32].length ≈ 0.032 atol=.0005
@test obj.loglik > -80.4
# Local BL constrained edge
lengthe = obj.net.edge[44].length
@test_nowarn PhyLiNC.optimizelocalBL_LiNC!(obj, obj.net.edge[44], lcache)
@test obj.net.edge[44].length == 0.0
@test obj.loglik > -78.95

# ## Local Gamma
# edge[4] = major parent edge of hybrid[1]
γcache = PhyLiNC.CacheGammaLiNC(obj)
@test_nowarn PhyLiNC.optimizelocalgammas_LiNC!(obj, obj.net.edge[4], 1e-6,γcache)
@test obj.net.edge[4].gamma == 0.0
@test getparentedge(obj.net.hybrid[1]).gamma == 1.0

# gamma at a hybrid ladder: when some displayed trees don't have the focus edge
# 2 unzipped reticulations in a hybrid ladder, reasonable (small) branch lengths
net = readTopology("(#H2:0.0001::0.0244,((C:0.0262,((B:0.0)#H1:0.0::0.6)#H2:0.03::0.9756):0.4812,(#H1:0.0001::0.4,A:0.1274):0.0001):0.0274,D:0.151);")
obj = StatisticalSubstitutionModel(net, fastasimple, :JC69)
obj.trait[1][3] = 3 # to create discordance across sites
obj.trait[4][4] = 2 #    for estimated γ to be within (0,1)
γcache = PhyLiNC.CacheGammaLiNC(obj)
discrete_corelikelihood!(obj) # -29.82754754416619
ll = PhyLiNC.optimizegamma_LiNC!(obj, obj.net.edge[4], .001, γcache, 3)
@test ll ≈ -29.655467369763585
@test obj.net.edge[4].gamma ≈ 0.8090635871910823
@test γcache.hase == [true, true, false]
@test all(γcache.clikn .== 0.0)
ll = PhyLiNC.optimizegamma_LiNC!(obj, obj.net.edge[1], .001, γcache, 3)
@test ll ≈ -29.468517891012983
@test obj.net.edge[1].gamma ≈ 0.19975558937688737
@test γcache.hase[[1,2]] == [false,true]
@test γcache.hase[3] === missing
@test γcache.clikn[[6,7]] ≈ [0.25, 0.0007] rtol=0.01
end #of local branch length and gamma optimization with localgamma! localBL! with 8 sites

@testset "global branch length and gamma optimization" begin
# to run locally on complex network:
# net = readTopology("(H_vulgare_HVens23:0.5,(((Ae_speltoides_Tr251:0.5):0.5,(Ae_mutica_Tr237:0.0)#H4:1.0::0.7):0.5,((((((Ae_caudata_Tr139:0.5,Ae_caudata_Tr275:0.5):0.0)#H1:1.0::0.7,#H2:1.0::0.3):0.5,#H1:1.0::0.3):0.5,((Ae_comosa_Tr271:0.5,Ae_comosa_Tr272:0.5):0.5,((Ae_uniaristata_Tr403:0.5,Ae_uniaristata_Tr357:0.5):0.5,Ae_uniaristata_Tr402:0.5):0.5):0.5):0.5,(((Ae_tauschii_Tr352:0.5,Ae_tauschii_Tr351:0.5):0.5,Ae_tauschii_Tr125:0.5):0.5,(((((((Ae_longissima_Tr241:0.5,Ae_longissima_Tr242:0.5):0.5,Ae_longissima_Tr355:0.5):0.5,Ae_sharonensis_Tr265:0.5):0.5,((Ae_bicornis_Tr408:0.5,Ae_bicornis_Tr407:0.5):0.5,Ae_bicornis_Tr406:0.5):0.5):0.5,(Ae_searsii_Tr164:0.5,Ae_searsii_Tr165:0.5):0.5):0.0)#H2:1.0::0.7,#H4:1.0::0.3):0.5):0.5):0.5):0.5);");
# obj = StatisticalSubstitutionModel(net, fasta8sites, :JC69);
net = readTopology("(((A:0.5,(B:0.0)#H1:1.0::0.9):0.5,(C:0.5,#H1:1.0::0.1):0.5):0.5,D:0.5);")
# branch lengths set to 0.5, then unzipped -> some BL are 0, some 1, most 0.5
obj = StatisticalSubstitutionModel(net, fastasimple, :JC69);

## optimizeBL
Random.seed!(5);
lcache = PhyLiNC.CacheLengthLiNC(obj, 1e-6,1e-6,1e-2,1e-3, 5)
obj.loglik = -Inf64
@test_nowarn PhyLiNC.optimizealllengths_LiNC!(obj, lcache);
@test all(e.length != 1.0 for e in obj.net.edge)
@test sum(e.length == 1.0e-8 for e in obj.net.edge) >= 2
@test sum(e.length == 0.0 for e in obj.net.edge) == 1
@test sum(e.length for e in obj.net.edge) > 0.7

## optimizegammas -- and delete hybrid edges with γ=0
γcache = PhyLiNC.CacheGammaLiNC(obj)
@test_nowarn PhyLiNC.optimizeallgammas_LiNC!(obj,1e-6,γcache,100)
@test obj.net.numHybrids == 0
end

@testset "checknetwork LiNC" begin
tree = readTopology("(A:3.0,(B:2.0,(C:1.0,D:1.0):1.0):1.0);");
@test any(length(n.edge) == 2 for n in tree.node) # one node of degree 2
preorder!(tree)
PhyLiNC.checknetwork_LiNC!(tree, 1, true, true)
@test all(length(n.edge) != 2 for n in tree.node) # no nodes of degree 2
net = readTopology("(((A:2.0,(B:1.0)#H1:0.1::0.9):1.5,(C:0.6,#H1:1.0::0.1):1.0):0.5,D:2.0);")
@test_throws ErrorException PhyLiNC.checknetwork_LiNC!(net, 0, true, true)
end

@testset "update root in SSM displayed trees" begin
# W structure
net = readTopology("(C:0.0262,(B:0.0)#H2:0.03::0.9756,(((D:0.1,A:0.1274):0.0)#H1:0.0::0.6,(#H2:0.0001::0.0244,#H1:0.151::0.4):0.0274):0.4812);")
# "((C:0.0262,(B:0.0)#H2:0.03::0.9756):0.4812,((D:0.1,A:0.1274):0.0)#H1:0.0::0.6,(#H2:0.0001::0.0244,#H1:0.151::0.4):0.0274);")
obj = StatisticalSubstitutionModel(net, fastasimple, :JC69)
@test [t.node[t.root].number for t in obj.displayedtree] == [5,5,5,5]
# obj.displayedtree[1]: (C:0.026,(B:0.0):0.03,(((D:0.1,A:0.127):0.0):0.0):0.481);
# move the root to place the W structure at the root:
# the network's root node will be missing from some displayed trees.
rootatnode!(obj.net, 7) # node 7 = tree node whose 2 children are both hybrids
# "(#H2:0.0001::0.0244,((C:0.0262,(B:0.0)#H2:0.03::0.9756):0.4812,((D:0.1,A:0.1274):0.0)#H1:0.0::0.6):0.0274,#H1:0.151);"
PhyLiNC.updateSSM_root!(obj) # re-root displayed trees in the same way
@test [t.node[t.root].number for t in obj.displayedtree] == [6,7,7,7]
@test writeTopology(obj.displayedtree[1]) == "(((D:0.1,A:0.1274):0.0)H1:0.0,(C:0.0262,(B:0.0)H2:0.03):0.4812);"
end

@testset "skip γ and lengths optimization when needed" begin
# W structure, with middle γs = 0
net = readTopology("(C:0.0262,(B:0.0)#H2:0.03::1,(((D:0.1,A:0.1274):0.0)#H1:0.004::1,(#H2:0.0001,#H1:0.151):0.0274):0.4812);")
obj = StatisticalSubstitutionModel(net, fastasimple, :JC69)
for i in [8,9] setGamma!(obj.net.edge[i], 0.0); end
PhyLiNC.updateSSM!(obj)
lcache = PhyLiNC.CacheLengthLiNC(obj, 1e-6,1e-6,1e-2,1e-3, 5);
e = PhyLiNC.optimizelocalBL_LiNC!(obj, obj.net.edge[10], lcache)
@test length(e) == 3 # not 5: the 2 edges with γ = 0 were excluded
@test obj.net.edge[10].length == 0.0274
# hybrid ladder, with lower γ = 0
net = readTopology("(#H2:0.0001::0.0244,((C:0.0262,((B:0.0)#H1:0.0::0.6)#H2:0.03::0.9756):0.4812,(#H1:0.0001::0.4,A:0.1274):0.0001):0.0274,D:0.151);")
obj = StatisticalSubstitutionModel(net, fastasimple, :JC69)
setGamma!(obj.net.edge[4], 0.0); PhyLiNC.updateSSM!(obj)
e = PhyLiNC.optimizelocalBL_LiNC!(obj, obj.net.edge[5], lcache)
@test length(e) == 4
@test [obj.net.edge[i].length for i in [1,5]] == [0.0001, 0.03]
γcache = PhyLiNC.CacheGammaLiNC(obj);
ll = PhyLiNC.optimizegamma_LiNC!(obj, obj.net.edge[5], .001, γcache, 3)
@test ll ≈ -31.124547305074074 # same as before optimization
end

@testset "optimizestructure with simple example" begin
#= network pre-processing: resulting net hard-coded below.
net = readTopology("(((A:2.0,(B:1.0)#H1:0.1::0.9):1.5,(C:0.6,#H1:1.0::0.1):1.0):0.5,D:2.0);")
obj = StatisticalSubstitutionModel(net, fastasimple, :JC69; maxhybrid=1)
PhyLiNC.checknetwork_LiNC!(obj.net, 1, true, true)
PhyLiNC.updateSSM!(obj, true; constraints=emptyconstraint)
PN.startingBL!(obj.net, obj.trait, obj.siteweight)
PN.unzip_canonical!(obj.net)
writeTopology(obj.net)
=#
net = readTopology("((A:0.3399824481995197,(B:0.0)#H1:0.08353360676474617::0.9):0.0001,(C:0.0001,#H1:0.048844990600034506::0.1):0.10871530327558311,D:0.33998306091744424);")
obj = StatisticalSubstitutionModel(net, fastasimple, :JC69; maxhybrid=1)
discrete_corelikelihood!(obj)
@test obj.loglik ≈ -29.7762035
maxmoves = 2
Random.seed!(90)
γcache = PhyLiNC.CacheGammaLiNC(obj)
lcache = PhyLiNC.CacheLengthLiNC(obj, 1e-6,1e-6,1e-2,1e-3, 5)
PhyLiNC.optimizestructure!(obj, maxmoves, 1, true, true, 0,100,
                                emptyconstraint, 1e-6, γcache, lcache)
@test obj.loglik > -27.6 # -27.42 with RNG from julia 1.5

# allow hybrid ladders
Random.seed!(110)
PhyLiNC.optimizestructure!(obj, maxmoves, 1, true, false, 0,100,
                                emptyconstraint, 1e-6, γcache, lcache)
@test obj.loglik > -27.5 # -27.42 with RNG from julia 1.5
end # of optimizestructure with simple example

@testset "phyLiNCone with simple net, no constraints" begin
no3cycle = true
net = readTopology("((A:0.3399824481995197,(B:0.0)#H1:0.08353360676474617::0.9):0.0001,(C:0.0001,#H1:0.048844990600034506::0.1):0.10871530327558311,D:0.33998306091744424);")
seed = 102
for nohybridladder in [true, false]
    #=
    net = readTopology("(((A:2.0,(B:1.0)#H1:0.1::0.9):1.5,(C:0.6,#H1:1.0::0.1):1.0):0.5,D:2.0);");
    obj = StatisticalSubstitutionModel(net, fastasimple, :JC69)
    PhyLiNC.checknetwork_LiNC!(obj.net, 1, no3cycle, nohybridladder)
    PhyLiNC.updateSSM!(obj, true; constraints=emptyconstraint)
    PN.startingBL!(obj.net, obj.trait, obj.siteweight)
    PN.unzip_canonical!(obj.net)
    writeTopology(obj.net) # result hard-coded above. independent of nohybridladder
    =#
    obj = StatisticalSubstitutionModel(net, fastasimple, :JC69)
    obj.loglik = -Inf # missing otherwise, which would cause an error below
    γcache = PhyLiNC.CacheGammaLiNC(obj)
    lcache = PhyLiNC.CacheLengthLiNC(obj, 1e-6,1e-6,1e-2,1e-3, 5)
    @test_nowarn PhyLiNC.phyLiNCone!(obj, 1, no3cycle,
            nohybridladder, 3, 2, false, false,
            devnull, seed, 0.5, emptyconstraint,
            1e-2, 1e-2, 1e-2, 1e-2, 0.0, 25.0, 0.01,0.9,
            γcache, lcache)
    @test obj.loglik > -27.45
end
end

@testset "phyLiNC no constraints: HKY, rate variation" begin
net = readTopology("(((A:2.0,(B:1.0)#H1:0.1::0.9):1.5,(C:0.6,#H1:1.0::0.1):1.0):0.5,D:2.0);");
obj = @test_nowarn phyLiNC(net, fastasimple, :JC69, :G, 2; maxhybrid=2, # no missing BLs, so they're not re-estimated
                    no3cycle=true, nohybridladder=true, maxmoves=2,
                    nreject=1, nruns=1, filename="", verbose=false, seed=108)
@test obj.loglik > -27.5 # depends on RNG. -27.4 with julia 1.5, -27.27 earlier
net = readTopology("(((A:2.0,(B:1.0)#H1:0.1::0.9):1.5,(C:0.6,#H1:1.0::0.1):1.0):0.5,D:2.0);");
obj = @test_nowarn phyLiNC(net, fastasimple, :HKY85; maxhybrid=2,
                    no3cycle=true, nohybridladder=true, maxmoves=2, probST=1.0, # not enough moves to get back to a good topology
                    nreject=1, nruns=1, filename="phyLiNC2", verbose=false, seed=0)
@test obj.loglik > -24.21
@test read("phyLiNC2.err", String) == ""
@test startswith(read("phyLiNC2.log", String), "PhyLiNC network estimation starting")
rm("phyLiNC2.log")
rm("phyLiNC2.err")

net = readTopology("(((A:2.0,(B:1.0)#H1:0.1::0.9):1.5,(C:0.6,#H1:1.0::0.1):1.0):0.5,D:2.0);");
addprocs(1) # multiple cores
@everywhere using PhyLiNC
#using Distributed; @everywhere begin; using Pkg; Pkg.activate("."); using PhyloNetworks; end
originalstdout = stdout  # verbose=true below
redirect_stdout(devnull)
obj = phyLiNC(net, fastasimple, :JC69; maxhybrid=2, no3cycle=true,
                        nohybridladder=true, maxmoves=2, nreject=1, nruns=2,
                        filename="phyLiNCmult", verbose=true, seed=106)
redirect_stdout(originalstdout)
@test obj.loglik > -28.27
rmprocs(workers()) # remove extra processors
@test occursin("using 1 worker", read("phyLiNCmult.log", String))
rm("phyLiNCmult.log")

# phyLiNC w/ maxhybrid = 0
net_h0 = readTopology("(((A:2.0,B:1.0):1.5,C:0.6):0.5,D:2.0);");
obj = @test_nowarn phyLiNC(net_h0, fastasimple, :JC69, :G, 2; maxhybrid=0,
                    no3cycle=true, nohybridladder=true, maxmoves=2,
                    nreject=1, nruns=1, filename="", verbose=false, seed=115)
@test obj.loglik > -27.4
end

@testset "phyLiNC with simple net and one constraint" begin
net_level1_s = readTopology("(((S8,S9),((((S1,S4),(S5)#H1),(#H1,(S6,S7))))#H2),(#H2,S10));") # S1A S1B S1C go on leaf 1
# 3-cycle at degree-2 root -> 2-cycle after root deletion, removed within LiNC
# constraint
net_level1_i, c_species = PN.mapindividuals(net_level1_s, mappingfile)
PN.resetNodeNumbers!(net_level1_i)
net_level1_i.node[22].number = 100
PN.updateconstraints!(c_species, net_level1_i)
@test c_species[1].taxonnums == Set([8,9,100])
@test c_species[1].node.number == 21
@test getparent(net_level1_i.node[22].edge[1]).number == 21

obj = StatisticalSubstitutionModel(net_level1_i,fastaindiv,:JC69,:GI,2)
# obj.net = deepcopy of input net, so we need to rebuild the constraints
c_species[1] = PN.TopologyConstraint(0x01, c_species[1].taxonnames, obj.net)
# obj.net = deepcopy of input net, so we need to rebuild the constraints if done after
@test_logs (:warn, r"no 3-cycle") match_mode=:any PhyLiNC.checknetwork_LiNC!(obj.net, 2,
                                                    true, true, c_species, true)
PhyLiNC.updateSSM!(obj, true; constraints=emptyconstraint)

#= assign good starting branch lengths: find them outside of tests
for e in obj.net.edge e.length = 0.1; end # was -1.0 for missing
PN.startingBL!(obj.net, obj.trait, obj.siteweight)
PN.unzip_canonical!(obj.net)
print([e.length for e in obj.net.edge])
=#
startingbl = [0.07817851911808402, 0.16346448006948466, 0.007466318403444228, 0.34338840607739174, 0.17023758685593676, 0.03060241610507292, 0.0, 0.5775895221009606, 0.05156530617279971, 0.33292850647444944, 0.13056644275564092, 0.27314259657043044, 0.07441709795812174, 0.0001, 0.0909334086743112, 0.017615628089233237, 0.13268439288408584, 0.14375488372292924, 0.3199334263745607]
for (i,e) in enumerate(obj.net.edge)
  e.length = startingbl[i]
end
PhyloTraits.setalpha!(obj.ratemodel, 0.48438)
obj.loglik = -Inf # actual likelihood -56.3068141288164. Need something non-missing
seed = 103
γcache = PhyLiNC.CacheGammaLiNC(obj)
lcache = PhyLiNC.CacheLengthLiNC(obj, 1e-2,1e-2,1e-2,1e-2, 5)
@test_nowarn PhyLiNC.phyLiNCone!(obj, 2, true, true,
        3, 2, false, false, devnull,
        seed, 0.5, c_species, 1e-2, 1e-2,
        1e-2, 1e-2, 0.0,50.0, 0.01,.9, γcache, lcache)
@test obj.loglik > -65.4 # -65.0 with RNG from julia 1.5

obj = phyLiNC(net_level1_s, # missing BLs, so BLs are re-estimated before starting
            fastaindiv, :JC69, :Inv; maxhybrid=2, no3cycle=true, nohybridladder=true,
            verbose=false, filename="", speciesfile=mappingfile, seed=138, nruns=1,
            maxmoves=10, nreject=2)
@test obj.loglik > -67.7 # -69.83824 with :noRV
@test 0.19 < obj.ratemodel.pinv[1] < 0.3
# test that species stayed together after optimization, as the only polytomy
function polytomyS1(node)
    length(node.edge) > 3 || return false
    return Set(n.name for n in getchildren(node)) == Set(["S1A", "S1B", "S1C"])
end
@test sum(polytomyS1(nod) for nod in obj.net.node) == 1
end

# hybrid flip tests
@testset "hybrid flip basics" begin
no3cycle = true
# nohybridladder = true w/ simple 1 hybrid starting network
Random.seed!(123)
# below: net already checked for PhyLiNC, startingBL and unzipped
net = readTopology("((A:0.3399824481995197,(B:0.0)#H1:0.08353360676474617::0.9):0.0001,(C:0.0001,#H1:0.048844990600034506::0.1):0.10871530327558311,D:0.33998306091744424);")
obj = StatisticalSubstitutionModel(net, fastasimple, :JC69)
obj.loglik = -Inf # loglik missing otherwise, which would cause an error below
γcache = PhyLiNC.CacheGammaLiNC(obj)
lcache = PhyLiNC.CacheLengthLiNC(obj, 1e-6,1e-6,1e-2,1e-3, 5)
@test PhyLiNC.fliphybridedgeLiNC!(obj, obj.loglik, true, emptyconstraint, 1e-6, γcache, lcache)
@test obj.loglik ≈ -27.7273003 atol=.0001
@test !PhyLiNC.deletehybridedgeLiNC!(obj, obj.loglik, no3cycle, emptyconstraint, γcache, lcache)
@test obj.loglik ≈ -27.7273003 atol=.0001

# nohybridladder = false w/ hybrid ladder starting network
Random.seed!(2)
# below: net already checked for PhyLiNC and unzipped
net = readTopology("(#H2:0.02495259889870113::0.0244,((C:1e-4,((B:0.0)#H1:0.0::0.6)#H2:0.034190897863530335::0.9756):0.24434924848805456,(#H1:0.01539513240840275::0.4,A:0.2864250860992079):1.0e-8):1e-4,D:0.2716998373895161);")
obj = StatisticalSubstitutionModel(net, fastasimple, :JC69)
obj.loglik = -Inf # loglik missing otherwise, which would cause an error below
γcache = PhyLiNC.CacheGammaLiNC(obj);
lcache = PhyLiNC.CacheLengthLiNC(obj, 1e-6,1e-6,1e-2,1e-3, 5);
@test PhyLiNC.fliphybridedgeLiNC!(obj, obj.loglik, false, emptyconstraint, 1e-6, γcache, lcache)
@test obj.loglik ≈ -29.05 atol=.1
previousloglik = obj.loglik
@test PhyLiNC.deletehybridedgeLiNC!(obj, obj.loglik, no3cycle, emptyconstraint, γcache, lcache)
@test obj.loglik > previousloglik + 0.1
@test !PhyLiNC.fliphybridedgeLiNC!(obj, obj.loglik, false, emptyconstraint, 1e-6, γcache, lcache)
end # hybrid flip basics
