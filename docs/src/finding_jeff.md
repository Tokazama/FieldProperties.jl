# Finding Jeff

Let's say we have a property `jeff`. Much like the person, `jeff` is extremely useful to have around yet is difficult to consistently locate.

## Defining `jeff`

Here the property `jeff` is defined.
```julia
julia> @defprop Jeff{:jeff} begin
           @getproperty x -> begin
               if hasproperty(x, :jeff)
                   return print(getproperty(x, :jeff))
               else
                   return print("Jeff is not here. You are alone...\n")
               end
           end
           @setproperty! (x, val) -> begin
               setproperty!(x, :jeff, "I am Jeff. I give you " * string(val) * ".\n")
           end
       end
```

Now we use the `Metadata` type to store people we know.
```julia
julia> m = Metadata()
Metadata{Dict{Symbol,Any}} with 0 entries

julia> jeff(m)
Jeff is not here. You are alone...

julia> jeff!(m, "beans");

julia>  jeff(m)
I am Jeff. I give you beans.

```

This doesn't effect the standard functionality of `getproperty` or `setproperty` for the `Metadata` type. The following doesn't print the `String` gives us the raw `String` we've stored instead of printing it.
```julia
julia> m.jeff
"I am Jeff. I give you beans.\n"

```

## Locating Jeff

Perhaps we want to specifically store a list of people we know. Some people are pretty consistent so we can dedicate fields for them, but we still need to account for the transient state of Jeff (the person).

```julia
julia> struct MyPeeps
           mom::String
           dad::String
           sister::String
           extension::Metadata
       end

julia> @properties MyPeeps begin
           mom(x) => :mom
           dad(x) => :dad
           sister(x) => :sister
           Any(x) => :extension
           Any!(x, val) => :extension
       end
```

Now we define an instance of `MyPeeps` and access them.
```julia
julia> peeps = MyPeeps("I am your mom.\n",
                       "I am your dad.\n",
                       "I am your sister.\n", Metadata());
julia> peeps.mom
"I am your mom.\n"

julia> peeps.dad
"I am your dad.\n"

julia> peeps.sister
"I am your sister.\n"

julia> jeff(peeps)
Jeff is not here. You are alone...

julia> peeps.jeff = "I am Jeff.\n";

julia> jeff(peeps)
I am Jeff.

# make Jeff a little more useful
julia> jeff(peeps)
I am Jeff. I give you beans.
```

This is a pretty simple setup of though. We probably know more people.
```julia
julia> struct Children
           child1::String
           child2::String
       end

julia> struct Family
           significant_other::String
           children::Children
       end

julia> @properties Family begin
           significant_other(self) => :significant_other
           Any(self) => :children
       end

julia> struct ListOfPeeps
           family::Family
           peeps::MyPeeps
       end

julia> @properties ListOfPeeps begin
           Any(self) => (:family,:peeps)
           Any!(self, val) => (:family,:peeps)
       end


julia> list_o_peeps = ListOfPeeps(Family("I am your significant other.\n",
                                         Children("Feed me.\n",
                                                  "Feed me too.\n")),
                                  MyPeeps("I am your mom.\n",
                                          "I am your dad.\n",
                                          "I am your sister.\n", Metadata())
                                  );
julia> propertynames(list_o_peeps)
(:significant_other, :child1, :child2, :mom, :dad, :sister)
```

And yet we are so very alone.
```julia
julia> jeff(list_o_peeps)
Jeff is not here. You are alone...

```

However, if we should happen to find Jeff again we can keep track off him.
```julia
julia> jeff!(list_o_peeps, "beans");

julia> jeff(list_o_peeps)
I am Jeff. I give you beans.

```

