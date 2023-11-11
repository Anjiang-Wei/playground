import "regent"
local c = regentlib.c

function get5()
    return 5
end

terra return42(): int64
    -- [e] escpate operator: whatever goes into an escape operator inserts a value of Lua experession e into a Terra context
    -- e is Lua code, and [e] evaluates to a Terra expression
    return [get5() + 37]
end

return42:printpretty()
c.printf("%d\n", return42())