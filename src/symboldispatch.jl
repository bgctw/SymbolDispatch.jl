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
    _symboldispatch(ex)
end

function _symboldispatch(ex) 
    fdef = splitdef(longdef(ex))
    # form with argument name
    c1 = @capture(first(fdef[:args]), a_::Val{:s_}) 
    # form without argument name
    if !c1
        @capture(first(fdef[:args]), ::Val{:s_}) || error(
            "expected first argument of valuetype of symbol, e.g. ::Val{:yoursymbol}," * 
            " but was $(first(fdef[:args]))")
    end
    fname = esc(fdef[:name])
    fnamestr = string(fdef[:name])
    args = esc(:args)
    kwargs = esc(:kwargs)
    Val = esc(:Val)
    ex_dispatch = :(@inline $(fname)(s::$(esc(:Symbol)), $args...; $kwargs...) = 
        $(fname)($Val(s), $args...; $kwargs...))
    T = esc(:T)
    ex_default = :(
        function $(fname)(::$Val{$T}, $args...; $kwargs...) where $T 
            # local mstr = $(esc(:join))(
            #     $(esc(string)).($(esc(methods))($(fname), ($Val,))[1:(end-1)]),"\n")
            local mstr = extract_methods_varsymbols($fname)
            $(esc(throw))( $(esc(ArgumentError))(
                $fnamestr*"(:"* $(esc(string))($T) *
                ", ...) not defined. Its defined for " * mstr))
        end  
    )
    quote
        $(esc(ex))
        $ex_dispatch
        $ex_default
    end
end

"""
    extract_methods_varsymbols(f)

Filter all methods of f for first type being a Var{s::Symbol}, and return
a string of the unique symbols.   
"""
function extract_methods_varsymbols(f)
    g = (mi.sig.parameters[2].parameters[1] for mi in methods(f) if 
    hasproperty(mi.sig, :parameters) && 
    length(mi.sig.parameters) > 1 &&
    mi.sig.parameters[2] <: Val &&
    mi.sig.parameters[2].parameters[1] isa Symbol
    )
    join(":" .* string.(unique(g)),",")
end
