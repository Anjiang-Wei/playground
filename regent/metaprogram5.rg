import "regent"
local c = regentlib.c

local function create_stencil(width, s, j)
    local value
    for i = -width, width-1 do -- Lua loop, includes the end
        local component = rexpr s[i+j] end
        if value then
            value = rexpr value + component end
        else
            value = rexpr component end
        end
    end
    return value
end

local function make_task(STENCIL_WIDTH)
    local task toplevel()
        var vsize = 100000
        var nt = 1000
        var vector = ispace(int1d, vsize)
        var source = region(vector, float)
        var dest = region(vector, float)
        fill(source, 1.0)
        fill(dest, 0.0)
        for i = 0, nt do
            for j = STENCIL_WIDTH, vsize - STENCIL_WIDTH do -- Regent loop, does not contain the end
                dest[j] = [ create_stencil(STENCIL_WIDTH, source, j) ]
            end
        end
        -- 20.000000 20.000000 20.000000 0.000000
        c.printf("%f %f %f %f\n", dest[STENCIL_WIDTH], dest[STENCIL_WIDTH+1], dest[vsize - STENCIL_WIDTH - 1], dest[vsize - STENCIL_WIDTH])
    end
    return toplevel
end

local main = make_task(10)
main:printpretty()

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")