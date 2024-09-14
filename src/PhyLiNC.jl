module PhyLiNC

using Dates
using Distributed
using Distributions # e.g. for sample, aweights, Geometric
using LinearAlgebra: mul!, lmul!
using Missings
using NLopt
using PhyloNetworks
using PhyloNetworks: Edge, Node, TopologyConstraint, fliphybrid!,
        deletehybridedge!, addhybridedge!, moveroot!
using PhyloTraits
using PhyloTraits: StatisticalSubstitutionModel, P!, update_logtrans,
        discrete_corelikelihood_trait!, discrete_corelikelihood!,
        discrete_backwardlikelihood_trait!
using Random
using StaticArrays
using StatsAPI: StatsAPI, loglikelihood
using StatsBase: fit!

const PN = PhyloNetworks
const SSM = PhyloTraits.StatisticalSubstitutionModel

export phyLiNC

include("phyLiNCoptimization.jl")

end
