import "regent"
local c = regentlib.c

-- Test Lua loop
-- 0
-- 1
-- 2
-- 3
-- Test Terra loop
-- 0
-- 1
-- 2
-- Test Regent loop
-- 0
-- 1
-- 2

local function testLualoop()
    print("Test Lua loop")
    for i = 0, 3 do
        print(i)
    end
end
testLualoop()

terra testTerraloop()
    c.printf("Test Terra loop\n")
    for i = 0, 3 do
        c.printf("%d\n", i)
    end
end
testTerraloop()

task main()
    c.printf("Test Regent loop\n")
    for i = 0, 3 do
        c.printf("%d\n", i)
    end
end

local target = os.getenv("OBJNAME")
regentlib.saveobj(main, target, "executable")