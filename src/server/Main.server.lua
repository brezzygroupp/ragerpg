-- Brumavale runtime. All inventory, damage and currency decisions are server-owned.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

local shared = ReplicatedStorage:WaitForChild("Brumavale")
shared:SetAttribute("ServerRuntime", "Starting")
local Config = require(shared:WaitForChild("Config"))
local CombatMath = require(shared:WaitForChild("CombatMath"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Profiles = require(script.Parent:WaitForChild("Profiles"))
local world = require(script.Parent:WaitForChild("World")).Build()
local actionRemote = shared:WaitForChild("Action")
local stateRemote = shared:WaitForChild("State")
local getState = shared:WaitForChild("GetState")
local fxRemote = shared:WaitForChild("FX")
local sessions, listings, mobs = {}, {}, {}
local closing = false
local effectsFolder = world:FindFirstChild("Effects")
if not effectsFolder then
	effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "Effects"
	effectsFolder.Parent = world
end

local function integer(value, maximum)
	return type(value) == "number" and value == value and value >= 1
		and value <= maximum and value % 1 == 0
end

local function body(player)
	local character = player.Character
	if not character then return nil end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if root and humanoid and humanoid.Health > 0 then return root, humanoid end
	return nil
end

local function regionAt(position)
	for _, region in ipairs(Config.Regions) do
		local center = Vector3.new(table.unpack(region.center))
		if math.abs(position.X - center.X) <= region.size / 2
			and math.abs(position.Z - center.Z) <= region.size / 2 then
			return region
		end
	end
	return nil
end

local function notify(player, message)
	if player.Parent == Players then stateRemote:FireClient(player, nil, message) end
end

local function marketSnapshot()
	local result = {}
	for _, listing in pairs(listings) do
		table.insert(result, {
			id=listing.id, item=listing.item, count=listing.count, price=listing.price,
			sellerId=listing.sellerId, sellerName=listing.sellerName,
		})
	end
	table.sort(result, function(a, b) return a.id < b.id end)
	return {listings=result}
end

local function snapshot(player)
	local profile = Profiles.Get(player)
	local session = sessions[player]
	if not profile or not session or not session.ready then return nil end
	local stats = Economy.Stats(profile)
	return {
		silver=profile.silver, xp=profile.xp, level=stats.level,
		capacity=Config.Capacity, weight=Economy.Weight(profile),
		inventory=profile.inventory, equipment=profile.equipment, stats=profile.stats,
		quest=Economy.Quest(profile), market=marketSnapshot(),
		persistent=Profiles.IsPersistent(player), region=session.region or "town",
		damage=stats.damage, defense=stats.defense, maxHealth=stats.maxHealth,
	}
end

local function update(player, message)
	local data = snapshot(player)
	if not data or player.Parent ~= Players then return end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local silver, level = stats:FindFirstChild("Prata"), stats:FindFirstChild("Nível")
		if silver and silver:IsA("IntValue") then silver.Value = data.silver end
		if level and level:IsA("IntValue") then level.Value = data.level end
	end
	local _, humanoid = body(player)
	if humanoid then humanoid.MaxHealth = data.maxHealth end
	stateRemote:FireClient(player, data, message)
end

local function updateMarket()
	for player, session in pairs(sessions) do
		if session.ready then update(player) end
	end
end

local function nearStation(player, stationType)
	local root = body(player)
	if not root then return false end
	for _, station in ipairs(world.Stations:GetChildren()) do
		if station:GetAttribute("Station") == stationType and station.PrimaryPart
			and (root.Position - station.PrimaryPart.Position).Magnitude <= 18 then
			return true
		end
	end
	return false
end

local function cooldown(player, key, seconds)
	local session = sessions[player]
	local now = os.clock()
	if not session or now < (session.cooldowns[key] or 0) then return false end
	session.cooldowns[key] = now + seconds
	return true
end

local function allowRequest(player)
	local session = sessions[player]
	if not session or not session.ready or closing then return false end
	local now = os.clock()
	session.tokens = math.min(20, session.tokens + (now - session.lastToken) * 10)
	session.lastToken = now
	if session.tokens < 1 then return false end
	session.tokens -= 1
	return true
end

local function effect(position, color, radius)
	local part = Instance.new("Part")
	part.Name = "BrumavaleEffect"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.Material, part.Color, part.Transparency = Enum.Material.Neon, color, 0.5
	part.Parent = world
	TweenService:Create(part, TweenInfo.new(0.32), {
		Size=Vector3.new(radius, radius, radius), Transparency=1,
	}):Play()
	Debris:AddItem(part, 0.4)
end

local function equipmentVisual(player)
	local profile, character = Profiles.Get(player), player.Character
	if not profile or not character then return end
	local previous = character:FindFirstChild("BrumavaleEquipment")
	if previous then previous:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "BrumavaleEquipment", character
	local function welded(name, size, limb, offset, color, material)
		local part = Instance.new("Part")
		part.Name, part.Size, part.Color = name, size, color
		part.Material = material or Enum.Material.Metal
		part.Massless, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.CFrame = limb.CFrame * offset
		part.Parent = folder
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = limb, part, part
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local weapon = Config.Items[profile.equipment.weapon]
	if hand and weapon then
		local tint = weapon.tier == 3 and Color3.fromRGB(98, 232, 225) or Color3.fromRGB(190, 204, 212)
		welded("Empunhadura", Vector3.new(0.22, 0.9, 0.22), hand, CFrame.new(0, -0.6, 0), Color3.fromRGB(92, 57, 38))
		welded("Guarda", Vector3.new(1.1, 0.16, 0.3), hand, CFrame.new(0, -1, 0), Color3.fromRGB(201, 169, 93))
		welded("Lâmina", Vector3.new(0.35, 2.5, 0.13), hand, CFrame.new(0, -2.2, 0), tint)
	end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local armor = Config.Items[profile.equipment.armor]
	if torso and armor then
		welded("Peitoral", Vector3.new(1.7, 1.35, 0.15), torso, CFrame.new(0, 0, -0.57),
			armor.tier == 2 and Color3.fromRGB(94, 120, 139) or Color3.fromRGB(105, 72, 51))
	end
end

local function visibility(model, visible, saved)
	for part, original in pairs(saved) do
		if part.Parent then
			part.Transparency = visible and original.transparency or 1
			part.CanCollide = visible and original.collide or false
			part.CanQuery = visible and original.query or false
		end
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BillboardGui") or descendant:IsA("ProximityPrompt") then
			descendant.Enabled = visible
		end
	end
end

local function savedAppearance(model)
	local saved = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			saved[descendant] = {transparency=descendant.Transparency, collide=descendant.CanCollide, query=descendant.CanQuery}
		end
	end
	return saved
end

local function updateEnemyLabel(record)
	local model = record.model
	model:SetAttribute("Health", record.health)
	local gui = model:FindFirstChild("EnemyLabel", true)
	if gui then
		local healthLabel = gui:FindFirstChild("HealthLabel", true)
		if healthLabel and healthLabel:IsA("TextLabel") then
			healthLabel.Text = string.format("%d / %d", math.max(0, record.health), record.config.health)
		end
		local bar = gui:FindFirstChild("Bar", true)
		local fill = bar and bar:FindFirstChild("Fill")
		if fill then fill.Size = UDim2.fromScale(math.clamp(record.health / record.config.health, 0, 1), 1) end
	end
end

local TELEGRAPH_Y = 1.24
local TELEGRAPH_RED = Color3.fromRGB(235, 72, 68)
local TELEGRAPH_DARK = Color3.fromRGB(122, 30, 38)

local function groundPosition(position)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = {world.TerrainParts}
	parameters.IgnoreWater = true
	local result = workspace:Raycast(Vector3.new(position.X, position.Y + 28, position.Z), Vector3.new(0, -100, 0), parameters)
	return result and (result.Position + Vector3.new(0, 0.08, 0)) or Vector3.new(position.X, TELEGRAPH_Y, position.Z)
end

local function flatDirection(from, to, fallback)
	local delta = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if delta.Magnitude > 0.05 then return delta.Unit end
	local look = fallback or Vector3.new(0, 0, -1)
	look = Vector3.new(look.X, 0, look.Z)
	return look.Magnitude > 0.05 and look.Unit or Vector3.new(0, 0, -1)
end

local function telegraphPart(parent, name, size, cframe, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Shape = shape or Enum.PartType.Block
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = TELEGRAPH_DARK
	part.Transparency = 0.56
	part.Parent = parent
	return part
end

local function createTelegraph(definition, origin, direction, windup)
	local telegraph = Instance.new("Model")
	telegraph.Name = "MonsterTelegraph"
	telegraph:SetAttribute("Shape", definition.shape)
	telegraph.Parent = effectsFolder
	local surfaceOrigin = origin
	if definition.shape == "circle" then
		local radius = definition.radius or definition.range or 6
		telegraphPart(telegraph, "Danger", Vector3.new(0.12, radius * 2, radius * 2),
			CFrame.new(surfaceOrigin) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
	elseif definition.shape == "line" then
		local range, width = definition.range or 10, definition.width or 4
		local center = surfaceOrigin + direction * (range * 0.5)
		telegraphPart(telegraph, "Danger", Vector3.new(width, 0.12, range),
			CFrame.lookAt(center, center + direction))
	else
		local range = definition.range or 9
		local halfAngle = math.rad((definition.angle or 70) * 0.5)
		local segments = 8
		local segmentLength = range / segments
		for index = 1, segments do
			local distance = (index - 0.5) * segmentLength
			local halfWidth = math.tan(halfAngle) * math.min(range, distance + segmentLength * 0.5)
			local center = surfaceOrigin + direction * distance
			telegraphPart(telegraph, "Danger", Vector3.new(math.max(0.4, halfWidth * 2), 0.12, segmentLength + 0.08),
				CFrame.lookAt(center, center + direction))
		end
	end
	for _, part in ipairs(telegraph:GetChildren()) do
		if part:IsA("BasePart") then
			TweenService:Create(part, TweenInfo.new(windup, Enum.EasingStyle.Linear), {
				Color=TELEGRAPH_RED, Transparency=0.18,
			}):Play()
		end
	end
	return telegraph
end

local function createCastIndicator(record, definition, windup)
	local gui = Instance.new("BillboardGui")
	gui.Name = "AttackCast"
	gui.Adornee = record.model.PrimaryPart
	gui.Size = UDim2.fromOffset(176, 42)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 95
	gui.Parent = record.model.PrimaryPart
	local name = Instance.new("TextLabel")
	name.Name = "AttackName"
	name.Size = UDim2.new(1, 0, 0, 23)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.Text = string.upper(definition.name or "ATAQUE")
	name.TextColor3 = Color3.fromRGB(255, 226, 202)
	name.TextStrokeColor3 = Color3.fromRGB(55, 16, 24)
	name.TextStrokeTransparency = 0.15
	name.TextSize = 12
	name.Parent = gui
	local bar = Instance.new("Frame")
	bar.Name = "CastBar"
	bar.Position = UDim2.fromOffset(13, 26)
	bar.Size = UDim2.new(1, -26, 0, 8)
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = Color3.fromRGB(51, 25, 31)
	bar.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = TELEGRAPH_RED
	fill.Parent = bar
	TweenService:Create(fill, TweenInfo.new(windup, Enum.EasingStyle.Linear), {Size=UDim2.fromScale(1, 1)}):Play()
	return gui
end

local function cancelMonsterAttack(record)
	local attackState = record.attack
	if not attackState then return end
	if attackState.telegraph and attackState.telegraph.Parent then attackState.telegraph:Destroy() end
	if attackState.castGui and attackState.castGui.Parent then attackState.castGui:Destroy() end
	record.attack = nil
	record.model:SetAttribute("AttackState", "Idle")
end

local function positionInAttack(attackState, position)
	return CombatMath.Contains(attackState.definition,
		attackState.origin.X, attackState.origin.Z,
		attackState.direction.X, attackState.direction.Z,
		position.X, position.Z)
end

local function clearAttackPath(record, player, root, attackState)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	local excluded = {record.model, world.Enemies, effectsFolder}
	for _, currentPlayer in ipairs(Players:GetPlayers()) do
		if currentPlayer.Character then table.insert(excluded, currentPlayer.Character) end
	end
	parameters.FilterDescendantsInstances = excluded
	parameters.IgnoreWater = true
	local origin = attackState.origin + Vector3.new(0, 2, 0)
	return workspace:Raycast(origin, root.Position - origin, parameters) == nil
end

local function resolveMonsterAttack(record)
	local attackState = record.attack
	if not attackState then return end
	local telegraph = attackState.telegraph
	if attackState.castGui and attackState.castGui.Parent then attackState.castGui:Destroy() end
	if telegraph and telegraph.Parent then
		for _, part in ipairs(telegraph:GetChildren()) do
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(0.1), {Color=Color3.new(1, 1, 1), Transparency=0.04}):Play()
			end
		end
		Debris:AddItem(telegraph, 0.16)
	end
	record.model:PivotTo(attackState.base)
	record.model:SetAttribute("AttackState", "Impact")
	fxRemote:FireAllClients("monsterImpact", {
		monster=record.model, position=attackState.origin,
		radius=attackState.definition.radius or attackState.definition.range or 6,
	})
	for player, session in pairs(sessions) do
		local root, humanoid
		if session.ready then root, humanoid = body(player) end
		local region = root and regionAt(root.Position)
		if root and humanoid and region and not region.safe
			and math.abs(root.Position.Y - attackState.origin.Y) < 16
			and positionInAttack(attackState, root.Position)
			and clearAttackPath(record, player, root, attackState) then
			local profile = Profiles.Get(player)
			if profile then
				local damage = math.max(1, record.config.damage - Economy.Stats(profile).defense)
				local before = humanoid.Health
				humanoid:TakeDamage(damage)
				local dealt = math.max(0, before - humanoid.Health)
				if dealt > 0 then
					effect(root.Position, Color3.fromRGB(231, 103, 101), 3)
					fxRemote:FireAllClients("playerHit", {player=player, monster=record.model, damage=dealt})
				end
			end
		end
	end
	record.attack = nil
	task.delay(0.12, function()
		if record.model.Parent and record.health > 0 and not record.attack then record.model:SetAttribute("AttackState", "Idle") end
	end)
end

local function startMonsterAttack(record, targetRoot, now)
	local definition = record.config.attack or {shape="circle", range=5.5, radius=5.5, windup=0.8, cooldown=1.3}
	local position = record.model:GetPivot().Position
	local attackOrigin = groundPosition(position)
	local direction = flatDirection(position, targetRoot.Position, record.model:GetPivot().LookVector)
	local base = CFrame.lookAt(position, position + direction)
	record.model:PivotTo(base)
	local windup = math.clamp(definition.windup or 0.9, 0.35, 3)
	record.attack = {
		definition=definition, origin=attackOrigin, direction=direction, base=base,
		started=now, resolves=now + windup, windup=windup,
		telegraph=createTelegraph(definition, attackOrigin, direction, windup),
		castGui=createCastIndicator(record, definition, windup),
	}
	record.nextAttack = now + math.max(windup + 0.15, definition.cooldown or 1.5)
	record.model:SetAttribute("AttackState", "Windup")
	record.model:SetAttribute("AttackShape", definition.shape)
	fxRemote:FireAllClients("monsterWindup", {monster=record.model, shape=definition.shape, windup=windup})
	return true
end

local function animateMonsterAttack(record, now)
	local attackState = record.attack
	if not attackState then return end
	local progress = math.clamp((now - attackState.started) / attackState.windup, 0, 1)
	local recoil
	if progress < 0.72 then
		recoil = math.sin((progress / 0.72) * math.pi * 0.5) * 1.15
	else
		recoil = 1.15 - ((progress - 0.72) / 0.28) * 2.8
	end
	local lift = math.sin(progress * math.pi) * 0.3
	local lean = math.rad(progress < 0.72 and (-9 * progress / 0.72) or (18 * (progress - 0.72) / 0.28))
	record.model:PivotTo(attackState.base * CFrame.new(0, lift, recoil) * CFrame.Angles(lean, 0, 0))
	if now >= attackState.resolves then resolveMonsterAttack(record) end
end


-- Each anchored enemy has a lightweight procedural rig: relative part poses
-- are evaluated after movement. No uploaded animations or external assets.
local function captureEnemyRig(model)
    local rest = {}
    local pivot = model:GetPivot()
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") and item ~= model.PrimaryPart then
            table.insert(rest, {part=item, offset=pivot:ToObjectSpace(item.CFrame), name=item.Name})
        end
    end
    return rest
end

local function poseEnemy(record, now, moving, distance)
    if distance > 120 and not record.attack then return end
    local model = record.model
    if not model.PrimaryPart then return end
    local state = model:GetAttribute("AttackState")
    local attacking = state == "Windup" or state == "Impact"
    local rate = record.config.speed > 12 and 9 or 6
    local phase = now * rate + record.phase
    local intensity = moving and 1 or 0.12
    local rise = math.sin(phase * 2) * (moving and 0.13 or 0.05)
    local attackWave = attacking and math.sin(now * 18) * 0.24 or 0
    local creature = model:GetAttribute("EnemyType")
    local stagger = math.max(0, 1 - (now - (record.lastHit or -100)) / 0.35)
    local windup = record.attack and math.clamp((now - record.attack.started) / record.attack.windup, 0, 1) or 0
    local root = model:GetPivot()
    for _, joint in ipairs(record.rig) do
        local p = joint.part
        if p.Parent then
            local name = joint.name
            local transform = CFrame.new(0, rise, 0)
            if name == "Leg" or name == "ScorpionLeg" then
                local side = joint.offset.Position.X >= 0 and 1 or -1
                transform = transform * CFrame.Angles(math.sin(phase + (side == 1 and 0 or math.pi)) * (creature == "scorpion" and 0.42 or 0.32) * intensity, 0, 0)
            elseif name == "Arm" or name == "Claw" then
                local side = joint.offset.Position.X >= 0 and 1 or -1
                transform = transform * CFrame.Angles(math.sin(phase + (side == 1 and math.pi or 0)) * 0.24 * intensity - attackWave, 0, side * attackWave)
            elseif name == "Tail" or name == "Stinger" or name == "StingerTip" or name == "TailSegment" then
                transform = transform * CFrame.Angles(math.sin(phase * 0.6) * 0.15 - (creature == "scorpion" and windup * 0.45 or 0), math.sin(phase * 0.7) * 0.25, 0)
            elseif name == "Head" or name == "HelmetCrest" or name == "CrownHorn" or name == "Hood" or name == "Mask" then
                transform = transform * CFrame.Angles(-attackWave * 0.7, math.sin(phase * 0.35) * 0.08, 0)
            elseif name == "SpiritFlame" or name == "MireSpike" or name == "SpiritCore" or name == "InnerCore" then
                transform = transform * CFrame.new(0, math.sin(phase + joint.offset.Position.X) * 0.4, 0)
            end
            if stagger > 0 then transform = transform * CFrame.Angles(math.rad(14) * stagger, 0, math.rad(10) * stagger) end
            p.CFrame = root * joint.offset * transform
        end
    end
end

local mobIndex = 0
for _, model in ipairs(world.Enemies:GetChildren()) do
	local config = Config.Enemies[model:GetAttribute("EnemyType")]
	if model:IsA("Model") and model.PrimaryPart and config then
        mobIndex += 1
		local record = {
			model=model, index=mobIndex, config=config, health=config.health, home=model:GetPivot(),
			appearance=savedAppearance(model), rig=captureEnemyRig(model), phase=#model.Name * 0.71, nextAttack=0, attack=nil, target=nil,
		}
		mobs[model] = record
		model:SetAttribute("Alive", true)
		model:SetAttribute("MaxHealth", config.health)
		updateEnemyLabel(record)
	end
end

local function hurtEnemy(player, record, amount)
	if record.health <= 0 then return end
	record.health = math.max(0, record.health - amount)
	record.target = player
    record.lastHit = os.clock()
	updateEnemyLabel(record)
	if record.health > 0 then return end
	cancelMonsterAttack(record)
	record.model:SetAttribute("Alive", false)
    record.model:SetAttribute("AttackState", "Dead")
    record.model:PivotTo(record.model:GetPivot() * CFrame.Angles(math.rad(62), 0, math.rad(10)))
    task.delay(0.4, function()
        if record.model.Parent and record.health <= 0 then visibility(record.model, false, record.appearance) end
    end)
	local profile = Profiles.Get(player)
	if profile then
		profile.stats.kills += 1
		local ok = Economy.Grant(profile, record.config.loot, record.config.silver, record.config.xp)
		if not ok then
			Economy.Grant(profile, {}, record.config.silver, record.config.xp)
			notify(player, "Mochila cheia: recebeu prata e experiência, mas perdeu o saque.")
		end
		update(player, "+" .. record.config.xp .. " XP · +" .. record.config.silver .. " prata")
	end
	task.delay(record.config.respawn, function()
		if not record.model.Parent or closing then return end
		record.model:PivotTo(record.home)
		record.health, record.target, record.nextAttack, record.attack = record.config.health, nil, 0, nil
		record.model:SetAttribute("Alive", true)
        record.model:SetAttribute("AttackState", "Idle")
        record.lastHit = nil
		visibility(record.model, true, record.appearance)
		updateEnemyLabel(record)
	end)
end

local function lineOfSight(character, target)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not target.PrimaryPart then return false end
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character, target}
	local origin = root.Position + Vector3.new(0, 1, 0)
	return workspace:Raycast(origin, target.PrimaryPart.Position - origin, parameters) == nil
end

local function attack(player, payload)
	local root = body(player)
	local profile = Profiles.Get(player)
	if not root or not profile then return end
	local skill = payload.skill or "basic"
	if skill ~= "basic" and skill ~= "cleave" then return end
	local range = skill == "cleave" and 18 or 15
	local target = payload.target
	if target == nil then
		local closest = range
		for model, record in pairs(mobs) do
			if record.health > 0 and model.PrimaryPart then
				local distance = (root.Position - model.PrimaryPart.Position).Magnitude
				if distance < closest then target, closest = model, distance end
			end
		end
	end
	local record = typeof(target) == "Instance" and mobs[target] or nil
	if not record or record.health <= 0 or not target.PrimaryPart
		or (root.Position - target.PrimaryPart.Position).Magnitude > range
		or not lineOfSight(player.Character, target) then return end
	local session, now = sessions[player], os.clock()
	if now < (session.cooldowns.attack or 0) or now < (session.cooldowns[skill] or 0) then return end
	session.cooldowns.attack = now + 0.65
	session.cooldowns[skill] = now + (skill == "cleave" and 5 or 0.65)
	fxRemote:FireAllClients("playerAttack", {player=player, skill=skill, target=target})
	local damage = Economy.Stats(profile).damage
	local attackingCharacter = player.Character
	task.delay(skill == "cleave" and 0.22 or 0.14, function()
		if closing or player.Parent ~= Players or player.Character ~= attackingCharacter
			or not Profiles.Get(player) then return end
		local strikeRoot = body(player)
		if not strikeRoot then return end
		if skill == "cleave" then
			effect(strikeRoot.Position, Color3.fromRGB(231, 188, 102), 24)
			for model, other in pairs(mobs) do
				if other.health > 0 and model.PrimaryPart
					and (strikeRoot.Position - model.PrimaryPart.Position).Magnitude <= range
					and lineOfSight(attackingCharacter, model) then
					hurtEnemy(player, other, math.floor(damage * 1.6))
				end
			end
		elseif record.health > 0 and target.Parent == world.Enemies and target.PrimaryPart
			and (strikeRoot.Position - target.PrimaryPart.Position).Magnitude <= range
			and lineOfSight(attackingCharacter, target) then
			effect(target.PrimaryPart.Position, Color3.fromRGB(246, 233, 185), 4)
			hurtEnemy(player, record, damage)
		end
	end)
end

local nodeAppearances = {}
local function gather(player, node)
	local root = body(player)
	local profile = Profiles.Get(player)
	if not root or not profile or typeof(node) ~= "Instance" or node.Parent ~= world.Resources
		or not node:IsA("Model") or not node.PrimaryPart or node:GetAttribute("Available") ~= true
		or (root.Position - node.PrimaryPart.Position).Magnitude > 14 then return end
	local config = Config.Nodes[node:GetAttribute("NodeType")]
	if not config or not cooldown(player, "gather", 1.25) then return end
	local ok, message = Economy.Grant(profile, {[config.item]=config.amount}, 0, config.xp)
	if not ok then notify(player, message); return end
	profile.stats.gathered += config.amount
	fxRemote:FireAllClients("playerAction", {player=player, action="gather", target=node})
	node:SetAttribute("Available", false)
	visibility(node, false, nodeAppearances[node])
	effect(node.PrimaryPart.Position, Color3.fromRGB(106, 221, 173), 5)
	update(player, "+" .. config.amount .. " " .. Config.Items[config.item].name .. " · +" .. config.xp .. " XP")
	task.delay(config.respawn, function()
		if node.Parent and not closing then
			node:SetAttribute("Available", true)
			visibility(node, true, nodeAppearances[node])
		end
	end)
end

local function travel(player, id)
	if type(id) ~= "string" then return end
	local root = body(player)
	if not root then return end
	local destination
	for _, region in ipairs(Config.Regions) do
		if region.id == id then destination = region; break end
	end
	if not destination then return end
	local validPortal = false
	for _, portal in ipairs(world.Portals:GetChildren()) do
		if portal:GetAttribute("Region") == id and portal.PrimaryPart
			and (root.Position - portal.PrimaryPart.Position).Magnitude <= 18 then
			validPortal = true; break
		end
	end
	if not validPortal then notify(player, "Aproxime-se do portal dessa região."); return end
	if not cooldown(player, "travel", 2) then return end
	local position = Vector3.new(table.unpack(destination.center)) + Vector3.new(0, 5, 20)
	player.Character:PivotTo(CFrame.new(position))
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	sessions[player].region = id
	player:SetAttribute("Region", id)
	update(player, "Você chegou a " .. destination.name .. ".")
end

for _, node in ipairs(world.Resources:GetChildren()) do
	if node:IsA("Model") then
		nodeAppearances[node] = savedAppearance(node)
		local prompt = node:FindFirstChild("GatherPrompt", true)
		if prompt then prompt.Triggered:Connect(function(player)
			if allowRequest(player) then gather(player, node) end
		end) end
	end
end
for _, portal in ipairs(world.Portals:GetChildren()) do
	local prompt = portal:FindFirstChild("TravelPrompt", true)
	if prompt then prompt.Triggered:Connect(function(player)
		if allowRequest(player) then travel(player, portal:GetAttribute("Region")) end
	end) end
end

-- The book is local to this server. Escrow is returned on cancellation/disconnect.
-- Profiles also recover persisted unsold escrow after an unclean shutdown.
local function returnListing(profile, listing)
	profile.inventory[listing.item] = (profile.inventory[listing.item] or 0) + listing.count
	if profile.marketEscrow then profile.marketEscrow[listing.id] = nil end
	listings[listing.id] = nil
end

local function marketAction(player, name, payload)
	local profile = Profiles.Get(player)
	if not profile then return end
	if not nearStation(player, "market") then notify(player, "Visite o mercado de Porto Bruma."); return end
	if name == "list" then
		if type(payload.item) ~= "string" or not Config.Items[payload.item]
			or not integer(payload.count, 99) or not integer(payload.price, 100000) then return end
		local ownCount = 0
		for _, listing in pairs(listings) do if listing.seller == player then ownCount += 1 end end
		if ownCount >= Config.MaxListings then notify(player, "Limite de anúncios atingido."); return end
		local ok, message = Economy.Remove(profile, payload.item, payload.count)
		if not ok then notify(player, message); return end
		local id = HttpService:GenerateGUID(false)
		listings[id] = {
			id=id, item=payload.item, count=payload.count, price=payload.price,
			seller=player, sellerId=player.UserId, sellerName=player.DisplayName,
		}
		profile.marketEscrow = profile.marketEscrow or {}
		profile.marketEscrow[id] = {item=payload.item, count=payload.count}
		updateMarket()
		notify(player, "Anúncio criado. Taxa na venda: " .. math.floor(Config.MarketTax * 100) .. "%.")
	elseif type(payload.id) == "string" then
		local listing = listings[payload.id]
		if not listing then notify(player, "Este anúncio já foi encerrado."); return end
		if name == "cancelListing" then
			if listing.seller ~= player then return end
			returnListing(profile, listing)
			updateMarket()
			notify(player, "Anúncio cancelado; itens devolvidos.")
		elseif name == "buyListing" then
			if listing.seller == player then notify(player, "Este anúncio é seu."); return end
			local sellerProfile = Profiles.Get(listing.seller)
			local sellerSession = sessions[listing.seller]
			if not sellerProfile or not sellerSession or not sellerSession.ready then
				notify(player, "Vendedor indisponível."); return
			end
			local total = listing.price * listing.count
			if profile.silver < total then notify(player, "Prata insuficiente."); return end
			local proceeds = total - math.floor(total * Config.MarketTax)
			if sellerProfile.silver + proceeds > 1000000000 then
				notify(player, "O vendedor atingiu o limite de prata."); return
			end
			local ok, message = Economy.Add(profile, listing.item, listing.count)
			if not ok then notify(player, message); return end
			profile.silver -= total
			sellerProfile.silver += proceeds
			sellerProfile.marketEscrow[listing.id] = nil
			listings[listing.id] = nil
			updateMarket()
			notify(player, "Compra concluída.")
			notify(listing.seller, "Venda concluída: " .. Config.Items[listing.item].name .. ".")
		end
	end
end

local function handleAction(player, name, payload)
	if not allowRequest(player) or type(name) ~= "string" or type(payload) ~= "table" then return end
	local profile = Profiles.Get(player)
	local _, humanoid = body(player)
	if not profile or not humanoid then return end
	if name == "attack" then attack(player, payload); return end
	if name == "gather" then gather(player, payload.node); return end
	if name == "travel" then travel(player, payload.region); return end
	if name == "list" or name == "buyListing" or name == "cancelListing" then
		marketAction(player, name, payload); return
	end
	local ok, message
	if name == "buy" or name == "sell" then
		if not nearStation(player, "shop") then notify(player, "Aproxime-se do mercador."); return end
		if type(payload.item) ~= "string" or not integer(payload.count, 99) then return end
		if name == "buy" then ok, message = Economy.Buy(profile, payload.item, payload.count)
		else ok, message = Economy.Sell(profile, payload.item, payload.count) end
	elseif name == "craft" then
		if not nearStation(player, "craft") then notify(player, "Aproxime-se da forja."); return end
		if type(payload.recipe) ~= "string" or not integer(payload.count, 99) then return end
		ok, message = Economy.Craft(profile, payload.recipe, payload.count)
	elseif name == "equip" then
		if type(payload.item) ~= "string" then return end
		ok, message = Economy.Equip(profile, payload.item)
		if ok then equipmentVisual(player) end
	elseif name == "use" then
		if type(payload.item) ~= "string" then return end
		if humanoid.Health >= humanoid.MaxHealth then notify(player, "Sua vida já está completa."); return end
		if not cooldown(player, "use", 2) then return end
		local healing
		ok, message, healing = Economy.Consume(profile, payload.item)
		if ok then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healing)
			fxRemote:FireAllClients("playerAction", {player=player, action="potion"})
			effect(player.Character.HumanoidRootPart.Position, Color3.fromRGB(93, 230, 158), 6)
		end
	elseif name == "claim" then
		if not nearStation(player, "quest") then notify(player, "Fale com o guia em Porto Bruma."); return end
		ok, message = Economy.ClaimQuest(profile)
	else return end
	if ok then update(player, message) else notify(player, message or "Ação indisponível.") end
end

actionRemote.OnServerEvent:Connect(function(player, name, payload)
	local ok, message = pcall(handleAction, player, name, payload)
	if not ok then warn("[Brumavale] Ação rejeitada por erro interno:", message) end
end)
getState.OnServerInvoke = function(player)
	if not allowRequest(player) then return nil end
	return snapshot(player)
end

local function characterReady(player, character)
	if character:GetAttribute("BrumavaleConfigured") then return end
	character:SetAttribute("BrumavaleConfigured", true)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root then return end
	while sessions[player] and not sessions[player].ready and player.Parent == Players do task.wait(0.1) end
	local profile = Profiles.Get(player)
	if not profile or player.Character ~= character then return end
	local spawn = world:FindFirstChild("TownSpawn", true)
	if spawn then character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0)) end
	humanoid.MaxHealth = Economy.Stats(profile).maxHealth
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = 19
	sessions[player].region = "town"
	player:SetAttribute("Region", "town")
	equipmentVisual(player)
	humanoid.Died:Connect(function()
		local current = Profiles.Get(player)
		if not current then return end
		local lost = math.floor(current.silver * 0.1)
		current.silver -= lost
		update(player, "Você caiu. Retornará à cidade e perdeu " .. lost .. " prata (10%).")
	end)
	update(player)
end

local function playerAdded(player)
	if sessions[player] then return end
	sessions[player] = {ready=false, region="town", cooldowns={}, tokens=20, lastToken=os.clock()}
	player:SetAttribute("ProfileReady", false)
	player.CharacterAdded:Connect(function(character) task.spawn(characterReady, player, character) end)
	local profile, message = Profiles.Load(player)
	if not profile then
		sessions[player] = nil
		if player.Parent == Players then player:Kick("Não foi possível carregar seus dados com segurança. Tente novamente. " .. (message or "")) end
		return
	end
	if player.Parent ~= Players or closing then
		Profiles.Remove(player)
		sessions[player] = nil
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name, leaderstats.Parent = "leaderstats", player
	end
	for _, name in ipairs({"Prata", "Nível"}) do
		if not leaderstats:FindFirstChild(name) then
			local value = Instance.new("IntValue")
			value.Name, value.Parent = name, leaderstats
		end
	end
	sessions[player].ready = true
	player:SetAttribute("ProfileReady", true)
	player:SetAttribute("PersistenceEnabled", Profiles.IsPersistent(player))
	local spawn = world:FindFirstChild("TownSpawn", true)
	if spawn and spawn:IsA("SpawnLocation") then player.RespawnLocation = spawn end
	if player.Character then task.spawn(characterReady, player, player.Character) end
	update(player, Profiles.IsPersistent(player) and "Bem-vindo a Brumavale!" or "Modo de teste: progresso desta sessão não será salvo.")
end

local function playerRemoving(player)
	local session = sessions[player]
	if not session then return end
	session.ready = false
	local profile = Profiles.Get(player)
	local owned = {}
	for _, listing in pairs(listings) do
		if listing.seller == player then table.insert(owned, listing) end
	end
	for _, listing in ipairs(owned) do
		if profile then returnListing(profile, listing) else listings[listing.id] = nil end
	end
	updateMarket()
	Profiles.Remove(player)
	sessions[player] = nil
end
Players.PlayerAdded:Connect(function(player) task.spawn(playerAdded, player) end)
Players.PlayerRemoving:Connect(playerRemoving)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(playerAdded, player) end

-- Fixed-rate lightweight AI; anchored mobs never receive client network ownership.
local accumulator, regionAccumulator = 0, 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	regionAccumulator += dt
	if accumulator < 0.15 or closing then return end
	local step = math.min(accumulator, 0.3)
	accumulator = 0
	local now = os.clock()
	for model, record in pairs(mobs) do
		if record.health <= 0 or not model.PrimaryPart then
			cancelMonsterAttack(record)
			continue
		end
		if record.attack then
			animateMonsterAttack(record, now)
			poseEnemy(record, now, false, 0)
			continue
		end
		local position = model.PrimaryPart.Position
		local target, nearest = nil, record.config.aggro
		for player, session in pairs(sessions) do
			local root = session.ready and body(player)
			local region = root and regionAt(root.Position)
			if root and region and not region.safe and math.abs(root.Position.Y - position.Y) < 15 then
				local distance = (root.Position - position).Magnitude
				if distance < nearest and (root.Position - record.home.Position).Magnitude < 95 then
					target, nearest = player, distance
				end
			end
		end
		record.target = target
		local targetRoot, targetHumanoid
		if target then targetRoot, targetHumanoid = body(target) end
		local goal = targetRoot and targetRoot.Position or record.home.Position
		local flat = Vector3.new(goal.X - position.X, 0, goal.Z - position.Z)
		local attackDefinition = record.config.attack or {range=5.5}
		local attackRange = attackDefinition.range or attackDefinition.radius or 5.5
		local stopDistance = targetRoot and math.max(3.2, math.min(attackRange * 0.82, attackRange - 0.35)) or 0.5
        -- Attack first: an enemy already within its attack radius should not
        -- freeze indefinitely while trying to move toward the exact same point.
        local inRange = targetRoot ~= nil and flat.Magnitude <= attackRange
        if targetHumanoid and inRange and now >= (record.nextAttack or 0)
            and (lineOfSight(target.Character, model) or flat.Magnitude < 7) then
            startMonsterAttack(record, targetRoot, now)
        else
            -- Soft separation keeps enemies from occupying each other's space.
            -- All models are anchored, so Roblox physics cannot separate them.
            local push = Vector3.zero
            local neighbors = 0
            for otherModel, other in pairs(mobs) do
                if other ~= record and other.health > 0 and otherModel.PrimaryPart then
                    local difference = position - otherModel.PrimaryPart.Position
                    local horizontal = Vector3.new(difference.X, 0, difference.Z)
                    local distance = horizontal.Magnitude
                    local clearance = (record.config.health >= 300 or other.config.health >= 300) and 9 or 6.8
                    if distance < clearance then
                        if distance < 0.1 then
                            local angle = record.index * 2.399963 + other.index * 0.71
                            horizontal = Vector3.new(math.cos(angle), 0, math.sin(angle))
                            distance = 1
                        end
                        push += horizontal.Unit * ((clearance - distance) / clearance)
                        neighbors += 1
                    end
                end
            end
            if neighbors > 0 then push = push / math.sqrt(neighbors) end
            local seek = flat.Magnitude > stopDistance and flat.Unit or Vector3.zero
            local desired = seek + push * 2.4
            if desired.Magnitude > 0.02 then
                local velocity = desired.Unit * math.min(record.config.speed * step, math.max(2, flat.Magnitude))
                local nextPosition = model:GetPivot().Position + velocity
                model:PivotTo(CFrame.lookAt(nextPosition, nextPosition + desired.Unit))
            end
        end
		poseEnemy(record, now, flat.Magnitude > stopDistance, target and nearest or math.huge)
		if not target and (model:GetPivot().Position - record.home.Position).Magnitude < 1 and record.health < record.config.health then
			record.health = record.config.health
			updateEnemyLabel(record)
		end
	end
	if regionAccumulator >= 1 then
		local elapsed = math.min(regionAccumulator, 2)
		regionAccumulator = 0
		for player, session in pairs(sessions) do
			local root, humanoid = body(player)
			if root and session.ready then
				local region = regionAt(root.Position)
				local id = region and region.id or "wilds"
				if id ~= session.region then
					session.region = id
					player:SetAttribute("Region", id)
					update(player)
				end
				if region and region.safe then humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + elapsed * 5) end
			end
		end
	end
end)

task.spawn(function()
	while not closing do
		task.wait(Config.SaveInterval)
		for player, session in pairs(sessions) do
			if session.ready then task.spawn(function()
				local ok = Profiles.Save(player)
				if not ok and player.Parent == Players then
					session.ready = false
					player:Kick("Não foi possível salvar seu progresso com segurança. Reconecte para tentar novamente.")
				end
			end) end
		end
	end
end)

game:BindToClose(function()
	closing = true
	for _, record in pairs(mobs) do cancelMonsterAttack(record) end
	-- Stop economic mutations before recovering each seller's unsold inventory.
	for player, session in pairs(sessions) do
		session.ready = false
		local profile = Profiles.Get(player)
		if profile then
			local owned = {}
			for _, listing in pairs(listings) do
				if listing.seller == player then table.insert(owned, listing) end
			end
			for _, listing in ipairs(owned) do returnListing(profile, listing) end
		end
	end
	Profiles.Shutdown()
end)

shared:SetAttribute("ServerRuntime", "Ready")
print("[Brumavale] Servidor v" .. tostring(Config.Version) .. " iniciado: 5 regiões, economia, combate, coleta e mercado local.")
