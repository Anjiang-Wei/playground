import "regent"
local c      = regentlib.c
local format = require("std/format")

task fibonacci(n: int) : int
    if n < 2 then return n end
    var var1 = fibonacci(n - 1)
    var var2 = fibonacci(n - 2)
    return var1 + var2
end

task print_result(i: int, n: int)
    c.printf("fib(%d) = %d\n", i, n)
end

task main()
    var num = 7
    for i = 0, num do
        var res = fibonacci(i)
        print_result(i, res)
    end
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")
