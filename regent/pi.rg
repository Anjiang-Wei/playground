import "regent"

local c = regentlib.c
local std = terralib.includec("stdlib.h")

task hit()
    var x: double = std.drand48()
    var y: double = std.drand48()
    if x * x + y * y <= 1.0 then
        return 1
    else
        return 0
    end
end

task hit_iter(iterations: int64)
    var total: int64 = 0
    for i = 0, iterations do
        var x: double = std.drand48()
        var y: double = std.drand48()
        if x * x + y * y <= 1.0 then
            total += 1
        end
    end
    return total
end

terra hit_iter_terra(iterations: int64)
    var total: int64 = 0
    for i = 0, iterations do
        var x: double = std.drand48()
        var y: double = std.drand48()
        if x * x + y * y <= 1.0 then
            total = total + 1
        end
    end
    return total
end

task main()
    var hits: int64 = 0
    var iterations: int64 = 100000

    var args = c.legion_runtime_get_input_args()
    if args.argc == 2 then
        c.printf("Iterations: %d\n", c.atoi(args.argv[1]))
        iterations = c.atoi(args.argv[1])
    end
    var time_start: int64, time_end: int64;
    time_start = c.legion_get_current_time_in_micros()
    c.printf("Starting %d ms\n", time_start)
    -- __fence(__execution, __block)
    for i = 0, iterations do
        hits += hit()
    end
    __fence(__execution, __block)
    time_end = c.legion_get_current_time_in_micros()
    c.printf("Ending %d ms\n", time_end)
    c.printf("Area is approximately %.2f, time = %d ms\n", hits * 4.0 / float(iterations), time_end - time_start)

    time_start = c.legion_get_current_time_in_micros()
    c.printf("Starting %d ms\n", time_start)
    -- __fence(__execution, __block)
    hits = 0
    for i = 0, 4 do
        hits += hit_iter(iterations / 4)
    end
    __fence(__execution, __block)
    time_end = c.legion_get_current_time_in_micros()
    c.printf("Ending %d ms\n", time_end)
    c.printf("Area is approximately %.2f, time = %d ms\n", hits * 4.0 / float(iterations), time_end - time_start)

    time_start = c.legion_get_current_time_in_micros()
    c.printf("Starting %d ms\n", time_start)
    -- __fence(__execution, __block)
    hits = 0
    for i = 0, 4 do
        hits += hit_iter_terra(iterations / 4)
    end
    __fence(__execution, __block)
    time_end = c.legion_get_current_time_in_micros()
    c.printf("Ending %d ms\n", time_end)
    c.printf("Area is approximately %.2f, time = %d ms\n", hits * 4.0 / float(iterations), time_end - time_start)
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")