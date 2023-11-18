import "regent"

local c = regentlib.c

task f(): int
    var r = region(ispace(int2d, {3, 2}), int)
    var colors = ispace(int2d, {2, 2})

    var rc = c.legion_domain_point_coloring_create()
    c.legion_domain_point_coloring_color_domain(rc, int2d{0, 0}, rect2d{{0, 0}, {1, 1}})
    var p = partition(disjoint, r, rc, colors)
    var r0 = p[{0, 0}]

    fill(r, 1)
    fill(r0, 10)
    
    var t = 0
    for i in r do
        t += r[i]
    end
    return t
end

task main()
    regentlib.assert(f() == 42, "test failed")
    c.printf("passed\n")
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")