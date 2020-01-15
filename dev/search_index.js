var documenterSearchIndex = {"docs":
[{"location":"api/#","page":"API","title":"API","text":"CurrentModule = ExprTools","category":"page"},{"location":"api/#API-1","page":"API","title":"API","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"","category":"page"},{"location":"api/#","page":"API","title":"API","text":"splitdef\ncombinedef","category":"page"},{"location":"api/#ExprTools.splitdef","page":"API","title":"ExprTools.splitdef","text":"splitdef(ex::Expr; throw::Bool=true) -> Union{Dict{Symbol,Any}, Nothing}\n\nSplit a function definition expression into its various components including:\n\n:head: Expression head of the function definition (:function, :(=), :(->))\n:name: Name of the function (not present for anonymous functions)\n:params: Parametric types defined on constructors\n:args: Positional arguments of the function\n:kwargs: Keyword arguments of the function\n:rtype: Return type of the function\n:whereparams: Where parameters\n:body: Function body (not present for empty functions)\n\nAll components listed may not be present in the returned dictionary with the exception of :head which will always be present.\n\nIf the provided expression is not a function then an exception will be raised when throw=true. Use throw=false avoid raising an exception and return nothing instead.\n\nSee also: combinedef\n\n\n\n\n\n","category":"function"},{"location":"api/#ExprTools.combinedef","page":"API","title":"ExprTools.combinedef","text":"combinedef(def::Dict{Symbol,Any}) -> Expr\n\nCreate a function definition expression from various components. Typically used to construct a function using the result of splitdef.\n\nFor more details see the documentation on splitdef.\n\n\n\n\n\n","category":"function"},{"location":"#ExprTools-1","page":"Home","title":"ExprTools","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"ExprTools provides tooling for working with Julia expressions during metaprogramming. This package aims to provide light-weight performant tooling without requiring additional package dependencies.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Alternatively see the MacroTools package for more powerful set of tools.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Currently, this package provides the splitdef and combinedef functions which are useful for inspecting and manipulating function definition expressions.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"e.g.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> using ExprTools\n\njulia> ex = :(\n           function Base.f(x::T, y::T) where T\n               x + y\n           end\n       )\n:(function Base.f(x::T, y::T) where T\n      #= none:3 =#\n      x + y\n  end)\n\njulia> def = splitdef(ex)\nDict{Symbol,Any} with 5 entries:\n  :args        => Any[:(x::T), :(y::T)]\n  :body        => quote…\n  :name        => :(Base.f)\n  :head        => :function\n  :whereparams => Any[:T]\n\njulia> def[:name] = :g;\n\njulia> def[:head] = :(=);\n\njulia> def[:body] = :(x * y);\n\njulia> combinedef(def)\n:((g(x::T, y::T) where T) = x * y)","category":"page"}]
}
