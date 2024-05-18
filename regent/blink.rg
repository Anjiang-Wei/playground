import "regent"

local c = regentlib.c
local std = terralib.includec("stdlib.h")

fspace BitField
{
    bit: bool,
}

task printer(bit_region: region(ispace(int1d), BitField))
where
    reads(bit_region)
do
    for i in bit_region do
        if bit_region[i].bit then
            c.printf("1 ")
        else
            c.printf("0 ")
        end
    end
    c.printf("\n")
end

task blink(bit_region: region(ispace(int1d), BitField))
where
    reads writes (bit_region)
do
    for i in bit_region do
        bit_region[i].bit = not bit_region[i].bit
    end
    c.usleep(10);
end

task main()
    var size = 60
    var bit_region = region(ispace(int1d, size), BitField)
    var psmall = partition(equal, bit_region, ispace(int1d, 6))

    var coloring = c.legion_domain_point_coloring_create()
    c.legion_domain_point_coloring_color_domain(coloring, [int1d](0), rect1d{0, 30})
    c.legion_domain_point_coloring_color_domain(coloring, [int1d](1), rect1d{30, 59})
    var plarge = partition(aliased, bit_region, coloring, ispace(int1d, 2))

    fill(bit_region.bit, false)
    for color in psmall.colors do
        blink(psmall[color])
    end
    for color in plarge.colors do
        blink(plarge[color])
    end
    printer(bit_region)
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")