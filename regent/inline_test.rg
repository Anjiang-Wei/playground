import "regent"
local c      = regentlib.c
local format = require("std/format")

fspace test_struct {
    id : int32
}

local
terra pow2(e : int) : int
    return 1 << e
end

__demand(__inline)
task to_be_inline(r: region(ispace(int1d), test_struct))
where reads writes (r) do
    var result = pow2(r[0].id)
    c.printf("%d\n", result)
    for cij in r.ispace do
        r[cij].id = cij + 1
    end
end

task main()
    var region_test = region(ispace(int1d, 10), test_struct)
    fill(region_test.id, 2);
    to_be_inline(region_test)
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")
