# Stacking Properties


Sometimes we want a more modular set of properties that can be created and managed separately, but combined later on.

```julia
julia> struct Nested1
           field1
           field2
       end

julia> struct Nested2
           field3
           field4
       end

julia> struct MultiNest
           field1
           field2
       end

julia> @assignprops(
           MultiNest,
           :field1 => nested,
           :field2 => nested
       )

```

Now instances of `MultiNest` are treated like the combination of `Nested1` and `Nested2`.
```julia
julia> mn = MultiNest(Nested1(1,2), Nested2(3,4))
MultiNest(Nested1(1, 2), Nested2(3, 4))

julia> propertynames(mn)
(:field1, :field2, :field3, :field4)

julia> mn.field1
1

julia> mn.field2
2

julia> mn.field3
3

julia> mn.field4
4

julia> mn.field1 = 2
2

julia> mn.field1
2
```





