struct SpatialProperties
end

@required_properties SpatialProperties begin
    SpaceDirections
end

@optional_properties SpatialProperties begin
    AffineProperty::AffineMap
    QuaternionProperty::Quaternion
end
