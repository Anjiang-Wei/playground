import "regent"
local c = regentlib.c

function Array(ElemType)
    local struct ArrayType {
        data: &ElemType,
        N: int
    }
    terra ArrayType:get(i: int) : ElemType
        return self.data[i]
    end

    terra ArrayType:set(i: int, v: ElemType)
        self.data[i] = v
    end

    terra ArrayType:init(size: int)
        self.data = [&ElemType](c.malloc(size * sizeof(ElemType)))
        self.N = size
    end
    
    return ArrayType
end

FloatArray = Array(float) -- Terra types are Lua values

terra mysum(size: int64): float
    var r: FloatArray
    r:init(size)
    for i = 0, r.N do
        r:set(i, 1.0)
        r.data[i] = 2.0
    end
    var s = 0.0
    for i = 0, r.N do
        s = s + r:get(i)
    end
    return s
end

c.printf("%f\n", mysum(10))
