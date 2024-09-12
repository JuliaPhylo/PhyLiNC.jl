# PhyLiNC

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaPhylo.github.io/PhyLiNC.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaPhylo.github.io/PhyLiNC.jl/dev/)
[![Build Status](https://github.com/JuliaPhylo/PhyLiNC.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaPhylo/PhyLiNC.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaPhylo/PhyLiNC.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaPhylo/PhyLiNC.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

PhyLiNC is a [Julia](http://julialang.org/) package implementing a method to
estimate a phylogenetic network from DNA sequences, assuming that sites evolve
independently. It does not account for incomplete lineage sorting, but accounts
for possible hybridization, gene flow or recombination.
The acronym stands for "phylogenetic Likelihood Network from Concatenated data".

A phylogenetic network is a graphical representation of the evolutionary history
of a group of individuals (or populations, or species), in which each node
represents an ancestor and either a splitting event (e.g. population split, or
speciation) or a merging event (e.g. migration, gene flow, hybridization).

For details on the method, identifiability results, and semidirected NNI (sNNI)
moves to move from one network to another, see Chapters 2-4 in the dissertation by
[Allen-Savietta (2020)](https://www.proquest.com/docview/2476856270/),
which was joint work with Cécile Ané.

> [!NOTE]
> Much of this package was formerly part of PhyloNetworks v0.16.4 (and prior).
> PhyloNetworks v0.17 will be stripped of PhyLiNC functions.
> The semidirected NNI (sNNI) moves described in Chapter 4 will remain in
> PhyloNetworks v0.17, as they are of general interest.

> [!WARNING]
> The PhyLiNC method has not been thoroughly tested:
> consider using [NetRAX](https://github.com/lutteropp/NetRAX) instead
> which was developed independently around the same time as PhyLiNC but has been
> through much more testing.

Below are the main differences between PhyLiNC and NetRAX.

- NetRAX is more flexible in that it can consider 1 or more site per block,
  whereas PhyLiNC has the constraint that 1 site = 1 block.
- When searching the network space, NetRAX may consider candidate networks that
  are non-distinguishable from the current network, which may slow it down
  (e.g. due to the presence vs. shrinkage of a 3-cycle; or rooted networks that
  only differ by their root position, identical when semidirected).
  PhyLiNC avoids comparing indistinguishable networks, based on theory
  about identifiability (see Chapter 3 in Dr. Allen-Savietta's dissertation).

## Citing

See [`CITATION.bib`](CITATION.bib) for the relevant reference(s).
