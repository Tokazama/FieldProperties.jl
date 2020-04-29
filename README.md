# FieldProperties.jl

[![Build Status](https://travis-ci.com/Tokazama/FieldProperties.jl.svg?branch=master)](https://travis-ci.com/Tokazama/FieldProperties.jl)
[![codecov](https://codecov.io/gh/Tokazama/FieldProperties.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Tokazama/FieldProperties.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/FieldProperties.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/FieldProperties.jl/dev)

`FieldProperties` provides an interface for creating method/property based APIs that can be flexibly incorporated into Julia structures.
This is predominantly accomplished through the use of [`@defprop`](@ref) and [`@properties`](@ref).
These macros help in the creation of methods and mapping them to the fields of a concrete type.
