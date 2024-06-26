import "regent"
local c = regentlib.c

fspace input {
    x: double,
    y: double,
}

fspace output {
    z: double,
}

task init(input_lr: region(ispace(int1d), input)) -- no need to pass in the index space actually
where writes(input_lr) do
    for i in input_lr do
        input_lr[i].x = c.drand48()
        input_lr[i].y = c.drand48()
    end
end

task daxpy(input_lr: region(ispace(int1d), input),
           output_lr: region(ispace(int1d), output),
           alpha: double)
where reads(input_lr), writes(output_lr) do
    for i in input_lr do
        output_lr[i].z = alpha * input_lr[i].x + input_lr[i].y
    end
end

task check(input_lr: region(ispace(int1d), input),
           output_lr: region(ispace(int1d), output),
           alpha: double)
where reads(input_lr), reads(output_lr) do
    for i in input_lr do
        regentlib.assert(output_lr[i].z == alpha * input_lr[i].x + input_lr[i].y, "check failed")
    end
end

task main()
    var num_elements = 1000
    var is = ispace(int1d, num_elements)
    var input_lr = region(is, input)
    var output_lr = region(is, output)

    var num_subregions = 4
    var ps = ispace(int1d, num_subregions)
    var input_lp = partition(equal, input_lr, ps)
    var output_lp = partition(equal, output_lr, ps)

    __demand(__index_launch)
    for i in ps do
        init(input_lp[i])
    end
    var alpha = c.drand48()
    __demand(__index_launch)
    for i in ps do
        daxpy(input_lp[i], output_lp[i], alpha)
    end
    __demand(__index_launch)
    for i in ps do
        check(input_lp[i], output_lp[i], alpha)
    end
    c.printf("check passed\n")
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")