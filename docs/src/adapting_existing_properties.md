# Examples


## Using Existing Properties

Let's say someone creates a package with the following code.
```julia
module SmallModule

using FieldProperties

export prop1

@defprop Prop1{:prop1}::Int=1

end
```

`prop1` will always 

If another package defines a property but you want the same syntax and support for your custom type 
