# Creating Properties

When a dot operator call `getproperty` or `setproperty!` it represent the property as a `Symbol`. Sometimes it's useful to have a method that retrieves a specific property so that users have a common API that doesn't change despite changes in the internal structure of types. `@defprop` automatically creates a method that calls `getproperty` and a method that calls `setproperty!`. This permits a sort of duck typing that can also be optimized for compile time performance. This section describes how to create properties quickly and some ways of customizing the behavior.

## Simple property construction
```@docs
@defprop
```

## Property types and interface

```@docs
AbstractProperty
propname
proptype
propconvert
```

