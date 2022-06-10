# SymbolDispatch

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://bgctw.github.io/SymbolDispatch.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://bgctw.github.io/SymbolDispatch.jl/dev)
[![Build Status](https://github.com/bgctw/SymbolDispatch.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/bgctw/SymbolDispatch.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/bgctw/SymbolDispatch.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/bgctw/SymbolDispatch.jl)

Macro @symboldispatch helps implementing the [singleton type dispatch pattern](https://subscription.packtpub.com/book/programming/9781838648817/12/ch12lvl1sec70/singleton-type-dispatch-pattern), with avoiding
the [value type anti pattern](https://discourse.julialang.org/t/is-keyword-argument-val-true-good-practice-or-an-antipattern/75543).

Code Example
```julia
using SymbolDispatch
@symboldispatch _bar(::Val{:method1}) = "method for :method1"
_bar(::Val{:method2}) = "method for :method2"

# call with symbol, rather than Val(:method1)
_bar(:method1) == "method for :method1"
```

See [documentation](https://bgctw.github.io/SymbolDispatch.jl/dev)


# Type-stable Alternatives 
**Caution** The return of a [symbol-dispatched call is type-unstable](https://discourse.julialang.org/t/understand-why-type-stability-depends-on-number-of-methods/81434). 
Use this pattern only in non-performance-critical parts of your application or where you can
deal with type-instability.

As an alternative, consider explicitly declaring Singleton-types.

```julia
abstract type ETMethod end
struct PriestleyTaylor <: ETMethod end
struct PenmanMonteith <: ETMethod end

potential_ET(::PriestleyTaylor, Tair) = "return from PriestlyTaylor"
potential_ET(::PenmanMonteith, Tair) = "return from PenmanMonteith"

method = PriestleyTaylor()
ET = potential_ET(method, 21.3)
```