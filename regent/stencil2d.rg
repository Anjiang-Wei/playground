import "regent"

local c = regentlib.c

fspace Fields {
    field1: float,
    field2: float,
}

task create_interior_partition(r_image: region(ispace(int2d), Fields))
    var coloring = c.legion_domain_coloring_create()
    var bounds = r_image.ispace.bounds
    -- todo: debug this line, no applicable overloaded function legion_domain_point_coloring_color_domain for arguments
    c.legion_domain_point_coloring_color_domain(coloring, 0, 
        rect2d{bounds.lo + {2, 2}, bounds.hi - {2, 2} })
    var interior_partition = partition(disjoint, r_image, coloring)
    c.legion_domain_coloring_destroy(coloring)
    return interior_partition
end

task compute(r_halo: region(ispace(int2d), Fields),
             r_interior: region(ispace(int2d), Fields))
where
    reads(r_halo), writes (r_interior)
do
    for e in r_interior do
        r_interior[e].field2 = r_halo[e + {1, 1}].field1
    end
end

task toplevel()
    var size = {32, 32}
    var machine = {2, 2}
    var r_image = region(ispace(int2d, size), Fields)

    var p_interior = create_interior_partition(r_image)
    var r_interior = p_interior[0]
    
    var p_private_colors = ispace(int2d, machine)
    var p_private = partition(equal, r_interior, p_private_colors)

    var c_halo = c.legion_domain_coloring_create()
    for color in p_private_colors do
        var bounds = p_private[color].bounds
        var halo_bounds: rect2d = rect2d{bounds.lo - {2,2}, bounds.hi + {2,2}}
        c.legion_domain_point_coloring_color_domain(c_halo, color, halo_bounds)
    end
    
    -- partition(properties, parent, coloring_object, color_space)
    var p_halo = partition(aliased, r_image, c_halo, p_private_colors)
    c.legion_domain_coloring_destroy(c_halo)

    fill(r_image.field1, 0.0)
    fill(r_image.field2, 0.0)

    for color in p_halo.colors do
        compute(p_halo[color], p_private[color])
    end
end

local target = os.get_env("OBJNAME")
regentlib.saveobj(target, toplevel, "executable")