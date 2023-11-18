import "regent"

local c = regentlib.c

task f(): int
    var r = region(ispace(int1d, 5), int)
    var colors = ispace(int1d, 1)

    var rc = c.legion_domain_point_coloring_create()
    c.legion_domain_point_coloring_color_domain(rc, int1d(0), rect1d{0, 3})
    var p = partition(disjoint, r, rc, colors)
    c.legion_domain_point_coloring_destroy(rc)

    var r0 = p[0]

    fill(r, 1)
    fill(r0, 10)

    var t = 0
    for i in r do
        t += r[i]
    end
    return t
end

task main()
    regentlib.assert(f() == 41, "test failed")
    c.printf("test passed\n")
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")