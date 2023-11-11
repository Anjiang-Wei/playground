import "regent"
local c = regentlib.c

function gen_square(x)
    return `x * x
end

terra mse(a: float, b: float): float
    return [gen_square(a)] - [gen_square(b)]
end

mse:printpretty()
c.printf("Answer %f\n", mse(4, 2))

function gen_expr(c, x)
    return `c * x
end

terra scale(a: float): float
    var COEFF = 6.0
    return [gen_expr(COEFF, a)]
end

scale:printpretty()
-- ent/metaprogram3.rg:19: terra scale(a : float) : float
-- ent/metaprogram3.rg:20:     var COEFF : double = 6
-- ent/metaprogram3.rg:21:     return [float](
-- ent/metaprogram3.rg:16:                    COEFF * [double](a))
-- ent/metaprogram3.rg:19: end
c.printf("Answer %f\n", scale(7.0))