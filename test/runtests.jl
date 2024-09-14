using PhyLiNC
using Test
using Aqua

using BioSymbols
using CSV
using DataFrames
using Distributed
using PhyloNetworks
using PhyloTraits
using PhyloTraits: StatisticalSubstitutionModel, discrete_corelikelihood!
using Random
using StaticArrays # for rate substitution matrices
using Statistics
using StatsBase # for aic etc., stderr

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
