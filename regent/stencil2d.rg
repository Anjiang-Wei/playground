import "regent"

-- mpirun build/stencil2d -ll:gpu 4 -ll:fsize 15000 -ll:cpu 4 -ll:util 2 -lg:prof 1 -lg:prof_logfile prof

local c = regentlib.c

local format = require("std/format")

fspace Fields {
    field1: float,
    field2: float,
}

task create_interior_partition(r_image: region(ispace(int2d), Fields))
    var coloring = c.legion_domain_coloring_create()
    var bounds = r_image.ispace.bounds
    c.legion_domain_coloring_color_domain(coloring, 0, 
        rect2d { bounds.lo + {2, 2}, bounds.hi - {2, 2} })
    var interior_image_partition = partition(disjoint, r_image, coloring)
    c.legion_domain_coloring_destroy(coloring)
    return interior_image_partition
end

__demand(__cuda)
task compute1(r_halo: region(ispace(int2d), Fields),
              r_interior: region(ispace(int2d), Fields))
where
    reads(r_halo.field1), reduces+(r_interior.field2)
do
    format.println("compute r_halo.ispace.bounds = {}, r_interior.ispace.bounds = {}",
        r_halo.ispace.bounds, r_interior.ispace.bounds)
    for e in r_interior do
        r_interior[e].field2 += r_halo[e + {1, 1}].field1
    end
end

__demand(__cuda)
task compute2(r_halo: region(ispace(int2d), Fields),
              r_interior: region(ispace(int2d), Fields))
where
    reads(r_halo.field2), reduces+(r_interior.field1)
do
    format.println("compute r_halo.ispace.bounds = {}, r_interior.ispace.bounds = {}",
        r_halo.ispace.bounds, r_interior.ispace.bounds)
    for e in r_interior do
        r_interior[e].field1 += r_halo[e + {1, 1}].field2
    end
end

task toplevel()
    var size = {50000, 50000}
    var machine = {2, 2}
    var r_image = region(ispace(int2d, size), Fields)

    var p_interior = create_interior_partition(r_image)
    var r_interior = p_interior[0]
    
    var p_private_colors = ispace(int2d, machine)
    var p_private = partition(equal, r_interior, p_private_colors)

    var c_halo = c.legion_domain_point_coloring_create()
    for color in p_private_colors do
        var bounds = p_private[color].bounds
        var halo_bounds: rect2d = rect2d{bounds.lo - {2,2}, bounds.hi + {2,2}}
        c.legion_domain_point_coloring_color_domain(c_halo, color, halo_bounds)
    end
    
    -- partition(properties, parent, coloring_object, color_space)
    var p_halo = partition(aliased, r_image, c_halo, p_private_colors)
    c.legion_domain_point_coloring_destroy(c_halo)

    fill(r_image.field1, 0.0)
    fill(r_image.field2, 0.0)

    __demand(__index_launch)
    for color in p_halo.colors do
        compute1(p_halo[color], p_private[color])
    end

    __demand(__index_launch)
    for color in p_halo.colors do
        compute2(p_halo[color], p_private[color])
    end
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(toplevel, target, "executable")