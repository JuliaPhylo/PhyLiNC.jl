using PhyLiNC
using Test
using Aqua

@testset "PhyLiNC.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(PhyLiNC)
    end
    # Write your tests here.
end
