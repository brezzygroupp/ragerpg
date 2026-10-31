-- Pure 2D hit geometry shared by the authoritative server and local tests.
local CombatMath = {}

local function finite(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function CombatMath.Contains(definition, originX, originZ, directionX, directionZ, pointX, pointZ)
	if type(definition) ~= "table" then return false end
	for _, value in ipairs({originX, originZ, directionX, directionZ, pointX, pointZ}) do
		if not finite(value) then return false end
	end
	local offsetX, offsetZ = pointX - originX, pointZ - originZ
	local distance = math.sqrt(offsetX * offsetX + offsetZ * offsetZ)
	if definition.shape == "circle" then
		local radius = definition.radius or definition.range
		return finite(radius) and radius > 0 and distance <= radius
	end
	local directionLength = math.sqrt(directionX * directionX + directionZ * directionZ)
	local range = definition.range
	if directionLength <= 0.0001 or not finite(range) or range <= 0 then return false end
	directionX, directionZ = directionX / directionLength, directionZ / directionLength
	local forward = offsetX * directionX + offsetZ * directionZ
	if forward < 0 or forward > range then return false end
	local lateral = math.abs(offsetX * directionZ - offsetZ * directionX)
	if definition.shape == "line" then
		local width = definition.width
		return finite(width) and width > 0 and lateral <= width * 0.5
	end
	if definition.shape == "cone" then
		local angle = definition.angle
		if not finite(angle) or angle <= 0 or angle >= 180 then return false end
		if distance <= 0.0001 then return true end
		local cosine = forward / distance
		return cosine >= math.cos(math.rad(angle * 0.5))
	end
	return false
end

return CombatMath
