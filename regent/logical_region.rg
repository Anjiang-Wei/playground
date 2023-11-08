import "regent"
local c = regentlib.c

fspace fs {
    a: double,
    {b, c, d}: int,
}

task make_fs(w: double, x: int, y: int, z: int): fs
    var obj = fs { a = w, b = x, c = y, d = z }
    return obj
end

fspace point {
    {x, y}: double
}

fspace edge(r: region(point)) {
    left: ptr(point, r),
    right: ptr(point, r),
}

task make_edge(points: region(point), a: ptr(point, points), b: ptr(point, points))
    return [edge(points)] { left = a, right = b }
end

task main()
    var unstructured_is = ispace(ptr, 1024)
    var structured_is = ispace(int1d, 1024, 0)

    var unstructured_lr = region(unstructured_is, fs)
    var structured_lr = region(structured_is, fs)

    c.printf("bounds = %d, volume = %d\n", structured_lr.bounds, structured_lr.volume)
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")