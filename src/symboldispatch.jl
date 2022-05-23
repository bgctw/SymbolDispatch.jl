"""
    @symboldispatch foo(Val{:asymbol}, ...) = body

This macro takes a function definition whose first argument is a valuetype of a symbol
and creates two more methods, a dispatch and a default fallback:

    foo(s::Symbol, ...) = foo(Val(s), ...)

    foo(::Val{T}, ...) where T = ArgumentError("Its defined for <possible symbols>")

It helps to implement the Singleton type dispatch pattern 
without exposing the usage of valuetypes to the user of the function.
Depending on the given Symbol `s`, the respective method is invoked.

Note that additional methods of `foo` for other possible symbols 
should be defined without the macro in order to avoid redifinition of the 
dispatch and fallback method.

```jldoctest; output = false
module mod_tmp
    using SymbolDispatch
    @symboldispatch _bar(::Val{:method1}) = "method for :method1"
    _bar(::Val{:method2}) = "method for :method2"
end
#mod_tmp._bar(:symbol_without_dispatch) # reporting :method1,:method2
mod_tmp._bar(:method1) == "method for :method1"
# output
true
``` 
"""
macro symboldispatch(ex)
    _symboldispatch(ex, Val(1))
end

"""
    @symboldispatch_pos2 foo(_, Val{:asymbol}, ...) = body

Similar to [`@symboldispatch`](@ref), adds a a dispatch and a default method,
but takes a function where the second argument is a valuetype of a symbol is
used to dispatch.

    foo(x1, s::Symbol, ...) = foo(x1, Val(s), ...)

    foo(_, ::Val{T}, ...) where T = ArgumentError("Its defined for <possible symbols>")

This helps to support different dispatches of mutating methods, where the 
first argument is conventionally the mutated element.

```jldoctest; output = false
module mod_tmp2
    using SymbolDispatch
    @symboldispatch_pos2 _bar!(x, ::Val{:method1}) = "method for :method1"
    _bar!(x, ::Val{:method2}) = "method for :method2"
end
#mod_tmp2._bar!([1], :symbol_without_dispatch) # reporting :method1,:method2
mod_tmp2._bar!([1], :method1) == "method for :method1"
# output
true
``` 
"""
macro symboldispatch_pos2(ex)
    _symboldispatch(ex, Val(2))
end

function _symboldispatch(ex, valpos::Val{pos}=Val(1)) where pos
    fdef = splitdef(longdef(ex))
    # form with argument name
    c1 = @capture(fdef[:args][pos], a_::Val{:s_}) 
    # form without argument name
    if !c1
        @capture(fdef[:args][pos], ::Val{:s_}) || error(
            "expected argument $pos to be a valuetype of symbol, e.g. ::Val{:yoursymbol}," * 
            " but was $(fdef[:args][pos])")
    end
    fname = esc(fdef[:name])
    fnamestr = string(fdef[:name])
    args = esc(:args)
    kwargs = esc(:kwargs)
    Val_ = esc(:Val)
    T = esc(:T)
    # Symbol at first positiong
    get_ex_dispatch(::Val{1}) = :(
            @inline $(fname)(s::$(esc(:Symbol)), $args...; $kwargs...) = 
            $(fname)($Val_(s), $args...; $kwargs...))
    get_ex_default(::Val{1}) = :(
            $(fname)(::$Val_{$T}, $args...; $kwargs...) where $T = 
            raise_argument_error($fname, $T, $(esc(pos))))
    # Symobl at second position: inserts arg1, in function signature
    get_ex_dispatch(::Val{2}) = :(
            # @inline $(fname)(arg1, s::$(esc(:Symbol)), $args...; $kwargs...) = 
            # $(fname)(arg1, $Val_(s), $args...; $kwargs...))
            $(fname)(arg1, s::$(esc(:Symbol)), $args...; $kwargs...) = 
            $(fname)(arg1, $Val_(s), $args...; $kwargs...))
    get_ex_default(::Val{2}) = :(
            $(fname)(arg1, ::$Val_{$T}, $args...; $kwargs...) where $T = 
            raise_argument_error($fname, $T, $(esc(pos))))
    quote
        $(get_ex_dispatch(valpos))
        $(get_ex_default(valpos))
        Core.@__doc__ $(esc(ex))
    end
end

#using Infiltrator
function raise_argument_error(f, sym, pos)
    local syms = extract_methods_varsymbols(f,pos)
    local syms_str = join(":" .* string.(syms),",")
    local preargs = repeat("_,",pos-1)
    throw(ArgumentError(
        string(f)*"("*preargs*":"*string(sym)*
        ", ...) not defined. Its defined for "*syms_str))
end

"""
    extract_methods_varsymbols(f)

Filter all methods of f for first type being a Var{s::Symbol}, and return
a generator of unique symbols.   
"""
function extract_methods_varsymbols(f,pos)
    g = (mi.sig.parameters[1+pos].parameters[1] for mi in methods(f) if 
    hasproperty(mi.sig, :parameters) && 
    length(mi.sig.parameters) > pos &&
    mi.sig.parameters[1+pos] <: Val &&
    mi.sig.parameters[1+pos].parameters[1] isa Symbol
    )
    unique(g)
end

i_tmp = () -> begin
    mi = first(methods(f))
    #mi.sig.parameters[2].parameters[1] for mi in methods(f) 
end
