import "regent"
local c      = regentlib.c
local stdlib = terralib.includec("stdlib.h")
local string = terralib.includec("string.h")
local format = require("std/format")

fspace my_fsp {
    var1 : double,
    var2 : double,
}


task main()
    var a = 1
    c.printf("a = %d\n", a)
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")
