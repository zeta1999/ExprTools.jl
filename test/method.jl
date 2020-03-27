macro test_signature(function_def_expr, method=nothing)
    _target = splitdef(function_def_expr)
    return quote
        fun = $(esc(function_def_expr))
        meth = if ($method === nothing)
            only_method(fun, Tuple{Vararg{Any}})
        else
            $(esc(method))
        end
        sig = signature(meth)
        test_matches(sig, $(_target))
    end
end

function test_matches(candidate::AbstractDict, target::Dict)
    # we want to use literals in the tests so that @test gives useful output on failure
    haskey(target, :name) && @test target[:name] == get(candidate, :name, nothing)
    haskey(target, :params) && @test target[:params] == get(candidate, :params, nothing)
    haskey(target, :args) && @test target[:args] == get(candidate, :args, nothing)
    haskey(target, :whereparams) &&
        @test target[:whereparams] == get(candidate, :whereparams, nothing)
    return nothing
end

"""
    only_method(f, typ)

Return the only method of `f` that accepts the types indicated by `type`.
Similar to `only(methods(f, typ))` in julia 1.4.
"""
function only_method(f, typ)
    meths = methods(f, typ)
    if length(meths) !== 1
        error("not just one method matches the given types. Found $(length(meths))")
    end
    return first(meths)
end



@testset "method.jl: signature" begin
    @testset "Basics" begin
        @test_signature basic1(x) = 2x
        @test_signature basic2(x::Int64) = 2x
        @test_signature basic3(x::Int64, y) = 2x
        @test_signature basic4() = 2
    end

    @testset "missing argnames" begin
        @test_signature ma1(::Int32) = 2x
        @test_signature ma2(::Int32, ::Bool) = 2x
        @test_signature ma3(x, ::Int32) = 2x
    end

    @testset "Whereparams" begin
        @test_signature f4(x::T, y::T) where T = 2x

        @test_signature f5(x::S, y::T) where {S,T} = 2x
        @test_signature f6(x::S, y::T) where {T,S} = 2x
        @test_signature f7(x::S, y::T) where T where S = 2x
    end

    @testset "Whereparams with constraints" begin
        @test_signature f8(x::S) where S<:Integer = 2x
        @test_signature f9(x::S, y::S) where S<:Integer = 2x
        @test_signature f10(x::S, y::T) where {S<:Integer, T<:Real} = 2x
        @test_signature f11(x::S, y::Int64) where S<:Integer = 2x

        @test_signature f12(x::S) where {S>:Integer} = 2x
        @test_signature f13(x::S) where Integer<:S<:Number = 2x
    end

    @testset "Arg types with type-parameters" begin
        @test_signature f14(x::Array{Int64, 1}) = 2x
        @test_signature f15(x::Array{T, 1}) where T = 2x

        # Note: we don't test: `f16(x::Array{<:Real, 1}) = 2x` as it lowers to same
        # method as below, but has a different AST according to `splitdef` so we can't
        # generate a solution that would unlower to two different AST for same method
        @test_signature f16(x::Array{T, 1} where T<:Real) = 2x

        #==
        # noncanonical form works
        old_sig = signature(first(methods(f16)))
        f16(x::Array{<:Real, 1} = 2x  # redefine it
        @assert length(methods(f16)) == 1  # no new method should have been created
        new_sig = signature(first(methods(f16)))
        ==#
    end

    @testset "anon functions" begin
        @test_signature (x) -> x  # no args
        @test_signature (x)->2x

        @test_signature ((::T) where T) -> 0   # Anonymous parameter


    end

    @testset "vararg" begin
        # we don't check `f18(xs...) = 2` as it lowers to the same method as below
        # but has a different AST according to `splitdef` so we can't
        # generate a solution that would unlower to two different AST for same method.
        @test_signature f17(xs::Vararg{Any, N} where N) = 2

        @test_signature f18(xs::Vararg{Int64, N} where N) = 2
        @test_signature f19(x, xs::Vararg{Any, N} where N) = 2x
    end

    @testset "kwargs" begin  # We do not support them right now
        #Following is broken:
        #@test_signature kwargs17(x; y=3x) = 2x
    end


    @testset "Constructors (basic)" begin
        # demo type for testing on
        struct NoParamStruct
            x
        end

        test_matches(  # default constructor
            signature(only_method(NoParamStruct, Tuple{Any})),
            Dict(:name => :NoParamStruct, :args => [:x]),
        )


        @test_signature(
            NoParamStruct(x::Bool, y::Int32) = NoParamStruct(x || y > 2),
            only_method(NoParamStruct, Tuple{Bool, Int32})
        )

        struct OneParamStructBasic{T}
            x::T
        end

        test_matches(  # default constructor
            signature(only_method(OneParamStructBasic, Tuple{Any})),
            Dict(:name => :OneParamStruct, :args => [:(x::T)]),
        )

        @test_signature(
            OneParamStructBasic(x::Bool, y::Int32) = OneParamStruct(x || y > 2),
            only_method(OneParamStructBasic, Tuple{Bool, Int32})
        )
    end

    @testset "params (via Constructors with type params" begin
        struct OneParamStruct{T}
            x::T
        end

        @test_signature(
            OneParamStruct{String}(x::Int32, y::Bool) = OneParamStruct(string(x^y)),
            only_method(OneParamStruct{String}, Tuple{Int32, Bool})
        )

        @test_signature(  # whereparams on params
            OneParamStruct{T}(x::Float32, y::Bool) where T<:AbstractFloat = OneParamStruct(x^y),
            only_method(OneParamStruct{Float32}, Tuple{Float32, Bool})
        )
    end
end
