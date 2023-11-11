import "regent"
local c = regentlib.c

ITERATE = 6

function create_expr(num, v)
    local value
    for i = 1, num do
        if value then
            value = `value + v
        else
            value = `v
        end
    end
    return value
end

terra scale(a: float): float
    -- var ITERATE = 6 -- this will not work because the for loop expects a value instead of a variable named ITERATE
    return [create_expr(ITERATE, a)]
end

scale:printpretty()
-- ent/metaprogram4.rg:18: terra scale(a : float) : float
-- ent/metaprogram4.rg:19:     return 
-- ent/metaprogram4.rg:10:            
-- ent/metaprogram4.rg:12:            a + 
-- ent/metaprogram4.rg:10:                a + a + a + a + a
-- ent/metaprogram4.rg:18: end
c.printf("Answer : %f\n", scale(7))