module ExampleModule

using FieldProperties
using DocStringExtensions

export ExampleStruct

"""
    ExampleStruct

---

$(GETPROPERTY)

---

$(SETPROPERTY)

"""
mutable struct ExampleStruct
    "p1 doc"
    p1
    "p2 doc"
    p2
    p3
    p4
    p5
end

@properties ExampleStruct begin
    "retrieve the `prop1` field"
    prop1(self) => :p1
    prop2(self) => :p2

    "set the `prop1` field"
    prop1!(self, val) => :p1
    prop2!(self, val) => :p2

    prop3(self) => :p3
    prop4(self) => :p4
    Any(self) => :p5
    Any!(self, val) => :p5
end

end
