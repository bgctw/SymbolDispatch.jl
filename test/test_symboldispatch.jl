delete_bar_methods = () -> begin
    if @isdefined _bar
        for m in methods(_bar)
            Base.delete_method(m)
        end
    end
end

check_bar_result = () -> begin
    @test length(methods(_bar)) == 3
    #@code_warntype _bar(:m2)
    @test @inferred(_bar(:m2)) == :m2
    # informative Error instead of method exception
    @test_throws ArgumentError _bar(:non_existing) 
end

#@testset "case with argument name" begin
    delete_bar_methods()
    @symboldispatch _bar(s::Val{:m2}) = :m2
    check_bar_result()
#end;

#@testset "case without argument name" begin
    delete_bar_methods()
    @symboldispatch _bar(::Val{:m2}) = :m2
    check_bar_result()
#end;

check_bar2_result = () -> begin
    @test length(methods(_bar)) == 3
    #@code_warntype _bar(:m2)
    @test @inferred(_bar(nothing, :m2)) == :m2
    # informative Error instead of method exception
    @test_throws ArgumentError _bar(nothing, :non_existing) 
end


delete_bar_methods()
@symboldispatch_pos2 _bar(df, ::Val{:m2}) = :m2
check_bar2_result()



@testset "error on not passing a function" begin
    @test_throws AssertionError SymbolDispatch._symboldispatch(:(:not_a_function))
end;

@testset "error on first argument not a value type" begin
    ex = :(_bar(s) = :m2)
    @test_throws ErrorException SymbolDispatch._symboldispatch(ex)
end;

@testset "error on value type parameter not a symbol" begin
    ex = :(_bar(::Val{4}) = :m2)
    @test_throws ErrorException SymbolDispatch._symboldispatch(ex)
end;



i_tmp = () -> begin
    # inspecting the macro output
    delete_bar_methods()
    @symboldispatch _bar(::Val{:m2}) = :m2
    _bar(:m2)
    _bar(::Val{:m3}) = :m3
    _bar(:nonexisting)
    
    @macroexpand @symboldispatch bar(::Val{:m2}) = :m2
    @macroexpand @symboldispatch bar(s::Val{:m2}) = :m2
    @macroexpand @symboldispatch bar(s::Val{:m2}) = :m2
end

