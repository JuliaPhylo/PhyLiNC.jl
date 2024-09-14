using PhyLiNC
using Test
using Aqua

using Distributed
using PhyloNetworks
using PhyloTraits
using PhyloTraits: StatisticalSubstitutionModel, discrete_corelikelihood!
using Random

const PN = PhyloNetworks

@testset "PhyLiNC code quality (Aqua.jl)" begin
    Test.detect_ambiguities(PhyLiNC)
    Aqua.test_all(
        PhyLiNC;
        ambiguities = (broken=false),
        persistent_tasks = false,
    )
end

@testset "PhyLiNC" begin
    include("test_phyLiNCoptimization.jl")
end
