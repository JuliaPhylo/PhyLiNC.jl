module PhyLiNC

using BioSequences
using BioSymbols
using CSV
using DataFrames # innerjoin new in v0.21
using Distributions #for RateVariationAcrossSites
using FASTX
using GLM
using LinearAlgebra: mul!, lmul!
using NLopt
using PhyloNetworks
using PhyloNetworks: Edge, Node, TopologyConstraint, fliphybrid!,
        deletehybridedge!, addhybridedge!
using PhyloTraits
using PhyloTraits: StatisticalSubstitutionModel, P!, update_logtrans,
        discrete_corelikelihood_trait!, discrete_corelikelihood!,
        discrete_backwardlikelihood_trait!
using Random
using StaticArrays
using StatsAPI: StatsAPI, loglikelihood
using StatsBase
using StatsFuns # logsumexp, logaddexp, log2π, various cdf
using StatsModels # re-exported by GLM. for ModelFrame ModelMatrix Formula etc

const PN = PhyloNetworks
const SSM = PhyloTraits.StatisticalSubstitutionModel

import Base: show
import StatsAPI: fit!

export phyLiNC

include("phyLiNCoptimization.jl")

end
