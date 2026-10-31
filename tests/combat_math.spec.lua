local CombatMath = require("../src/shared/CombatMath")
local passed = 0
local function test(name, callback)
	local ok, message = pcall(callback)
	assert(ok, name .. ": " .. tostring(message))
	passed += 1
	print("PASS " .. name)
end

test("circle includes its boundary and rejects outside", function()
	local attack={shape="circle",radius=6}
	assert(CombatMath.Contains(attack,0,0,0,-1,0,0))
	assert(CombatMath.Contains(attack,0,0,0,-1,6,0))
	assert(not CombatMath.Contains(attack,0,0,0,-1,6.01,0))
end)

test("line is forward-only with exact width", function()
	local attack={shape="line",range=12,width=5}
	assert(CombatMath.Contains(attack,0,0,0,-1,0,-12))
	assert(CombatMath.Contains(attack,0,0,0,-1,2.5,-6))
	assert(not CombatMath.Contains(attack,0,0,0,-1,2.51,-6))
	assert(not CombatMath.Contains(attack,0,0,0,-1,0,1))
	assert(not CombatMath.Contains(attack,0,0,0,-1,0,-12.01))
end)

test("cone follows locked direction and angle", function()
	local attack={shape="cone",range=10,angle=60}
	assert(CombatMath.Contains(attack,0,0,1,0,8,0))
	local edge=math.rad(30)
	assert(CombatMath.Contains(attack,0,0,1,0,math.cos(edge)*8,math.sin(edge)*8))
	local outside=math.rad(31)
	assert(not CombatMath.Contains(attack,0,0,1,0,math.cos(outside)*8,math.sin(outside)*8))
	assert(not CombatMath.Contains(attack,0,0,1,0,-2,0))
end)

test("direction is normalized and invalid definitions fail closed", function()
	assert(CombatMath.Contains({shape="line",range=4,width=2},0,0,10,0,3,0.9))
	assert(not CombatMath.Contains({shape="line",range=4,width=2},0,0,0,0,1,0))
	assert(not CombatMath.Contains({shape="unknown",range=4},0,0,1,0,1,0))
	assert(not CombatMath.Contains({shape="circle",radius=0/0},0,0,1,0,0,0))
end)

print(string.format("%d combat geometry tests passed",passed))
