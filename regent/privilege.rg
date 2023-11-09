import "regent"
local c = regentlib.c

fspace input {
    x: double,
    y: double,
}

fspace output {
    z: double,
}

task init(is : ispace(int1d),
         input_lr: region(is, input))
where writes(input_lr) do
    for i in is do
        input_lr[i].x = c.drand48()
        input_lr[i].y = c.drand48()
    end
end

task daxpy(is: ispace(int1d),
           input_lr: region(is, input),
           output_lr: region(is, output),
           alpha: double)
where reads(input_lr), writes(output_lr) do
    for i in is do
        output_lr[i].z = alpha * input_lr[i].x + input_lr[i].y
    end
end

task check(is: ispace(int1d),
           input_lr: region(is, input),
           output_lr: region(is, output),
           alpha: double)
where reads(input_lr), reads(output_lr) do
    for i in is do
        regentlib.assert(output_lr[i].z == alpha * input_lr[i].x + input_lr[i].y, "check failed")
    end
end

task main()
    var num_elements = 1000
    var is = ispace(int1d, num_elements)
    var input_lr = region(is, input)
    var output_lr = region(is, output)

    init(is, input_lr)
    var alpha = c.drand48()
    daxpy(is, input_lr, output_lr, alpha)
    check(is, input_lr, output_lr, alpha)
    c.printf("check passed\n")
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")