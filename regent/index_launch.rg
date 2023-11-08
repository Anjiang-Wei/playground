import "regent"
local c      = regentlib.c
local format = require("std/format")

task double_of(i: int, x: int)
    c.printf("double_of from task i = %d\n", i)
    return x * 2
end

task main()
    var num_points = 4
    var total = 0
    __demand(__index_launch)
    for i = 0, num_points do
        total += double_of(i, i + 10)
    end
    regentlib.assert(total == 92, "check failed")

    -- __demand(__index_launch) -- compile error: __demand(__index_launch) is not permitted
    var total2 = 0
    for i = 0, num_points do
        var x = double_of(i, i + 10)
        total2 += double_of(i, x)
    end
    c.printf("total2 = %d\n", total2)
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")
