import "regent"
local c = regentlib.c

fspace input {
    x: double,
    y: double,
}

fspace output {
    z: double,
}

task main()
    var num_elements = 1000
    var is = ispace(int1d, num_elements)
    var input_lr = region(is, input)
    var output_lr = region(is, output)

    for i in is do
        input_lr[i].x = c.drand48()
        input_lr[i].y = c.drand48()
    end

    var alpha = c.drand48()

    for i in is do
        output_lr[i].z = alpha * input_lr[i].x + input_lr[i].y
    end

    for i in is do
        var expected = alpha * input_lr[i].x + input_lr[i].y
        regentlib.assert(output_lr[i].z == expected, "check failed")
    end
    c.printf("check passed\n")
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")