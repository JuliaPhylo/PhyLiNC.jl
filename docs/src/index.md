```@meta
CurrentModule = PhyLiNC
```

# PhyLiNC

[PhyLiNC](https://github.com/JuliaPhylo/PhyLiNC.jl) is a
[Julia](http://julialang.org/) package implementing the PhyLiNC (Phylogenetic
Likelihood Network from Concatenated data) method. This method aims to
estimate a phylogenetic network from DNA sequences, assuming that sites evolve
independently. It does not account for incomplete lineage sorting, but accounts
for possible hybridization, gene flow or recombination.

A phylogenetic network represents the evolutionary history
of a group of taxa (individuals, or populations, or species), in which each node
represents an ancestor and either a splitting event (e.g. population split, or
speciation) or a merging event (e.g. migration, gene flow, hybridization).

For details on the method, identifiability results, and semidirected NNI (sNNI)
moves to move from one network to another, see Chapters 2-4 in the dissertation by
[Allen-Savietta (2020)](https://www.proquest.com/docview/2476856270/),
which was joint work with Cécile Ané.

!!! note
    Much of this package was formerly part of
    [PhyloNetworks](https://github.com/juliaphylo/PhyloNetworks.jl) v0.16.4 (and prior).
    PhyloNetworks v0.17 will be stripped of PhyLiNC functions.
    The semidirected NNI (sNNI) moves described in Chapter 4 of
    [Allen-Savietta (2020)](https://www.proquest.com/docview/2476856270/) will
    remain in PhyloNetworks v0.17, as they are of general interest.

!!! warning
    The PhyLiNC method has not been thoroughly tested:
    consider using [NetRAX](https://github.com/lutteropp/NetRAX) instead
    which was developed independently around the same time as PhyLiNC but has been
    through much more testing.

Below are the main differences between PhyLiNC and NetRAX.

- NetRAX is more flexible in that it can consider 1 or more site per block,
  whereas PhyLiNC has the constraint that 1 site = 1 block.
- When searching the network space, NetRAX may consider candidate networks that
  are non-distinguishable from the current network, which may slow it down
  (e.g. due to the presence vs. shrinkage of a 3-cycle; or rooted networks that
  only differ by their root position, identical when semidirected).
  PhyLiNC avoids comparing indistinguishable networks, based on theory
  about identifiability (see Chapter 3 in Dr. Allen-Savietta's dissertation).

## references

please see them in [bibtex format](https://github.com/juliaphylo/PhyLiNC.jl/blob/master/CITATION.bib).

## documentation

The main function is [`phyLiNC`](@ref).

```@autodocs
Modules = [PhyLiNC]
```
