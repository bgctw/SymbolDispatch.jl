using SymbolDispatch
using Test

# Macro testing does not work when wrapped iin @testset
#@testset "symboldispatch" begin
    #include("test/test_symboldispatch.jl")
    include("test_symboldispatch.jl")
#end
