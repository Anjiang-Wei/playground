import "regent"

__demand(__local, __cuda)
task f(r: region(ispace(int1d), int))
where reads writes(r) do
    for x in r do
        r[x] += 1
    end
end

__demand(__leaf, __cuda)
task call_f(r: region(ispace(int1d), int),
            p: partition(disjoint, r, ispace(int1d)))
where reads writes(r) do
    f(r)
    for i = 0, 2 do
        f(p[i])
    end
end

task main()
    var r = region(ispace(int1d, 100), int)
    var p = partition(equal, r, ispace(int1d, 2))
    fill(r, 0)

    call_f(r, p)

    for x in r do
        regentlib.assert(r[x] == 2, "check failed")
    end
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")