-- Brumavale: a deterministic, self-contained world built entirely from primitives.
-- No uploaded models, HTTP access or asset permissions are required.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Brumavale"):WaitForChild("Config"))

local World = {}
local VERSION = 6
local C = {
    stone = Color3.fromRGB(113, 125, 133), darkStone = Color3.fromRGB(55, 66, 78),
    wood = Color3.fromRGB(99, 65, 46), paleWood = Color3.fromRGB(160, 113, 66),
    plaster = Color3.fromRGB(221, 207, 170), roof = Color3.fromRGB(43, 89, 100),
    gold = Color3.fromRGB(228, 181, 82), teal = Color3.fromRGB(85, 216, 190),
    ink = Color3.fromRGB(23, 36, 47), cream = Color3.fromRGB(246, 236, 202),
    grass = Color3.fromRGB(92, 139, 82), leaf = Color3.fromRGB(55, 113, 82),
}

local function rgb(t, fallback)
    if type(t) ~= "table" then return fallback end
    return Color3.fromRGB(t[1] or t.r or 120, t[2] or t.g or 120, t[3] or t.b or 120)
end

local function vector(t)
    return Vector3.new(t[1] or t.x or 0, t[2] or t.y or 0, t[3] or t.z or 0)
end

local function part(parent, name, size, pos, color, material, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = typeof(pos) == "CFrame" and pos or CFrame.new(pos)
    p.Color = color or C.stone
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end

local function noCollision(p)
    p.CanCollide = false
    return p
end

local function folder(parent, name)
    local f = Instance.new("Folder")
    f.Name = name
    f.Parent = parent
    return f
end

local function model(parent, name)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent
    return m
end

local function text(parent, name, content, color, size, position)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Size = size or UDim2.fromScale(1, 1)
    label.Position = position or UDim2.fromScale(0, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = content
    label.TextColor3 = color or C.cream
    label.TextSize = 14
    label.TextStrokeColor3 = C.ink
    label.TextStrokeTransparency = 0.25
    label.Parent = parent
    return label
end

local function billboard(adornee, title, subtitle, color, offset)
    local b = Instance.new("BillboardGui")
    b.Name = "WorldLabel"
    b.Adornee = adornee
    b.Size = UDim2.fromOffset(220, 60)
    b.StudsOffsetWorldSpace = Vector3.new(0, offset or 5, 0)
    b.MaxDistance = 110
    b.AlwaysOnTop = false
    b.Parent = adornee
    text(b, "Title", title, color, UDim2.fromScale(1, 0.55))
    local sub = text(b, "Subtitle", subtitle or "", C.cream, UDim2.fromScale(1, 0.45), UDim2.fromScale(0, 0.55))
    sub.TextSize = 11
    return b
end

local function prompt(adornee, name, action, object, hold)
    local p = Instance.new("ProximityPrompt")
    p.Name = name
    p.ActionText = action
    p.ObjectText = object
    p.KeyboardKeyCode = Enum.KeyCode.E
    p.GamepadKeyCode = Enum.KeyCode.ButtonX
    p.MaxActivationDistance = 12
    p.RequiresLineOfSight = false
    p.HoldDuration = hold or 0
    p.Parent = adornee
    return p
end

local function lantern(parent, pos)
    local pole = part(parent, "LanternPost", Vector3.new(0.6, 8, 0.6), pos + Vector3.new(0, 4, 0), C.wood, Enum.Material.Wood)
    local lamp = noCollision(part(parent, "Lantern", Vector3.new(1.3, 1.8, 1.3), pos + Vector3.new(0, 8, 0), C.gold, Enum.Material.Neon))
    part(parent, "LanternCap", Vector3.new(2, 0.35, 2), pos + Vector3.new(0, 9.1, 0), C.darkStone)
    local light = Instance.new("PointLight")
    light.Color = C.gold
    light.Range = 16
    light.Brightness = 0.8
    light.Shadows = false
    light.Parent = lamp
    return pole
end

local function crate(parent, pos, size)
    size = size or 3
    local m = model(parent, "SupplyCrate")
    part(m, "Box", Vector3.new(size, size, size), pos + Vector3.new(0, size / 2, 0), C.paleWood, Enum.Material.WoodPlanks)
    for _, dy in ipairs({0.3, size - 0.3}) do
        part(m, "IronBand", Vector3.new(size + 0.1, 0.35, size + 0.1), pos + Vector3.new(0, dy, 0), C.darkStone, Enum.Material.Metal)
    end
    return m
end

local function tree(parent, pos, rng, autumn)
    local m = model(parent, "WildTree")
    local height = rng:NextNumber(12, 18)
    local trunk = part(m, "Trunk", Vector3.new(2.2, height * 0.65, 2.2), pos + Vector3.new(0, height * 0.325, 0), C.wood, Enum.Material.Wood)
    local color = autumn and Color3.fromRGB(192, 127, 65) or C.leaf
    for i = 1, 3 do
        local leaf = noCollision(part(m, "Crown", Vector3.new(10 - i, 7 - i * 0.5, 10 - i), pos + Vector3.new((i - 2) * 2, height * 0.62 + i * 1.6, (i % 2) * 1.8), color, Enum.Material.Grass, Enum.PartType.Ball))
        leaf.CFrame = leaf.CFrame * CFrame.Angles(0, i, 0)
    end
    m.PrimaryPart = trunk
    return m
end

local function pine(parent, pos, rng)
    local m = model(parent, "Pine")
    local h = rng:NextNumber(17, 24)
    m.PrimaryPart = part(m, "Trunk", Vector3.new(2, h * 0.65, 2), pos + Vector3.new(0, h * 0.325, 0), C.wood, Enum.Material.Wood)
    for i = 1, 4 do
        local width = 15 - i * 2.4
        noCollision(part(m, "Bough", Vector3.new(width, 5, width), CFrame.new(pos + Vector3.new(0, h * 0.35 + i * 3, 0)) * CFrame.Angles(0, math.pi / 4, 0), Color3.fromRGB(39 + i * 6, 88 + i * 7, 73 + i * 4), Enum.Material.Grass))
    end
    return m
end

local function resource(parent, kind, pos, index, rng)
    local def = Config.Nodes[kind]
    assert(def, "Missing resource configuration: " .. kind)
    local m
    if kind == "tree" then
        m = tree(parent, pos, rng, false)
    else
        m = model(parent, "Resource")
        local color = rgb(def.color, C.stone)
        if kind == "fiber" then
            m.PrimaryPart = noCollision(part(m, "Stem", Vector3.new(0.7, 2.5, 0.7), pos + Vector3.new(0, 1.25, 0), color, Enum.Material.Grass))
            for n = 1, 5 do
                local angle = n * math.pi * 0.4
                local stem = noCollision(part(m, "FiberLeaf", Vector3.new(0.7, 3, 0.7), CFrame.new(pos + Vector3.new(math.cos(angle) * 1.1, 1.5, math.sin(angle) * 1.1)) * CFrame.Angles(math.sin(angle) * 0.4, 0, math.cos(angle) * 0.4), color, Enum.Material.Grass))
                noCollision(part(m, "Bloom", Vector3.new(1.2, 0.8, 1.2), stem.Position + Vector3.new(0, 1.3, 0), C.cream, Enum.Material.SmoothPlastic, Enum.PartType.Ball))
            end
        elseif kind == "crystal" then
            m.PrimaryPart = part(m, "CrystalBase", Vector3.new(4, 2, 4), pos + Vector3.new(0, 1, 0), C.darkStone, Enum.Material.Slate, Enum.PartType.Ball)
            for n = 1, 4 do
                local angle = n * math.pi / 2
                noCollision(part(m, "CrystalShard", Vector3.new(1.1, 3 + n * 0.5, 1.1), CFrame.new(pos + Vector3.new(math.cos(angle), 2.2 + n * 0.2, math.sin(angle))) * CFrame.Angles(math.sin(angle) * 0.25, math.pi / 4, math.cos(angle) * 0.25), color, Enum.Material.Neon))
            end
        else
            m.PrimaryPart = part(m, "Boulder", Vector3.new(5.5, 4, 5), CFrame.new(pos + Vector3.new(0, 1.7, 0)) * CFrame.Angles(0.2, rng:NextNumber(0, 6), 0.2), kind == "ore" and C.darkStone or color, Enum.Material.Slate)
            if kind == "ore" then
                for n = 1, 5 do
                    noCollision(part(m, "OreVein", Vector3.new(1, 0.6, 1), pos + Vector3.new(rng:NextNumber(-1.9, 1.9), 3.8, rng:NextNumber(-1.8, 1.8)), color, Enum.Material.Metal))
                end
            end
        end
    end
    m.Name = kind .. "_" .. tostring(index)
    m:SetAttribute("NodeType", kind)
    m:SetAttribute("Available", true)
    m:SetAttribute("SpawnPosition", m.PrimaryPart.Position)
    prompt(m.PrimaryPart, "GatherPrompt", "Coletar", def.name, 0.8)
    return m
end

local function enemyLabel(m, def)
    local b = Instance.new("BillboardGui")
    b.Name = "EnemyLabel"
    b.Size = UDim2.fromOffset(150, 52)
    b.Adornee = m.PrimaryPart
    b.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
    b.MaxDistance = 90
    b.AlwaysOnTop = true
    b.Parent = m.PrimaryPart
    local name = text(b, "NameLabel", def.name, C.cream, UDim2.fromScale(1, 0.5))
    name.TextSize = 12
    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.BorderSizePixel = 0
    bar.BackgroundColor3 = C.ink
    bar.Size = UDim2.fromScale(0.84, 0.22)
    bar.Position = UDim2.fromScale(0.08, 0.52)
    bar.Parent = b
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BorderSizePixel = 0
    fill.BackgroundColor3 = Color3.fromRGB(214, 95, 88)
    fill.Size = UDim2.fromScale(1, 1)
    fill.Parent = bar
    local health = text(b, "HealthLabel", tostring(def.health) .. " / " .. tostring(def.health), C.cream, UDim2.fromScale(1, 0.24), UDim2.fromScale(0, 0.76))
    health.TextSize = 10
end

local function enemy(parent, kind, pos, index)
    local def = Config.Enemies[kind]
    assert(def, "Missing enemy configuration: " .. kind)
    local m = model(parent, kind .. "_" .. tostring(index))
    if kind == "slime" or kind == "bogling" or kind == "wisp" then
        m.PrimaryPart = noCollision(part(m, "Root", Vector3.new(4.5, 3.1, 4.5), pos + Vector3.new(0, 1.7, 0), (kind == "wisp" and Color3.fromRGB(112,220,242) or kind == "bogling" and Color3.fromRGB(90,133,83) or Color3.fromRGB(114,191,135)), kind == "wisp" and Enum.Material.Neon or Enum.Material.SmoothPlastic, Enum.PartType.Ball))
        for _, x in ipairs({-0.8, 0.8}) do
            noCollision(part(m, "Eye", Vector3.new(0.65, 0.7, 0.3), pos + Vector3.new(x, 2.1, -2), C.ink, Enum.Material.SmoothPlastic, Enum.PartType.Ball))
        end
    elseif kind == "wolf" or kind == "icewolf" or kind == "boar" or kind == "scorpion" then
        m.PrimaryPart = noCollision(part(m, "Root", Vector3.new(2.8, 2.4, 5), pos + Vector3.new(0, 2.7, 0), (kind == "icewolf" and Color3.fromRGB(196,215,231) or kind == "boar" and Color3.fromRGB(111,75,58) or kind == "scorpion" and Color3.fromRGB(147,62,52) or Color3.fromRGB(132,142,148)), Enum.Material.Slate))
        noCollision(part(m, "Head", Vector3.new(2.5, 2.3, 2.4), pos + Vector3.new(0, 3.5, -2.8), Color3.fromRGB(161, 169, 173)))
        noCollision(part(m, "Muzzle", Vector3.new(1.6, 1, 1.3), pos + Vector3.new(0, 3.1, -4.2), C.darkStone))
        for _, x in ipairs({-1, 1}) do
            for _, z in ipairs({-1.6, 1.6}) do
                noCollision(part(m, "Leg", Vector3.new(0.65, 1.9, 0.65), pos + Vector3.new(x, 1, z), C.darkStone))
            end
            noCollision(part(m, "Ear", Vector3.new(0.65, 1.3, 0.65), pos + Vector3.new(x * 0.8, 4.9, -2.8), C.darkStone))
            noCollision(part(m, "Eye", Vector3.new(0.4, 0.4, 0.2), pos + Vector3.new(x * 0.7, 3.8, -4.05), C.gold, Enum.Material.Neon))
        end
        noCollision(part(m, "Tail", Vector3.new(0.9, 0.9, 2.5), CFrame.new(pos + Vector3.new(0, 3, 3.1)) * CFrame.Angles(-0.25, 0, 0), C.darkStone))
    elseif kind == "guardian" or kind == "ashgolem" or kind == "ancient" then
        m.PrimaryPart = noCollision(part(m, "Root", Vector3.new(5.5, 6, 3.5), pos + Vector3.new(0, 5.7, 0), C.darkStone, Enum.Material.Slate))
        noCollision(part(m, "Head", Vector3.new(3.2, 3, 3), pos + Vector3.new(0, 10, 0), C.stone, Enum.Material.Slate))
        noCollision(part(m, "Rune", Vector3.new(1.6, 2.2, 0.25), pos + Vector3.new(0, 6, -1.9), Color3.fromRGB(157, 124, 235), Enum.Material.Neon))
        for _, x in ipairs({-1, 1}) do
            noCollision(part(m, "Arm", Vector3.new(2, 5.5, 2), CFrame.new(pos + Vector3.new(x * 4, 5.2, 0)) * CFrame.Angles(0, 0, x * 0.15), C.stone, Enum.Material.Slate))
            noCollision(part(m, "Leg", Vector3.new(2.2, 3, 2.4), pos + Vector3.new(x * 1.6, 1.5, 0), C.stone, Enum.Material.Slate))
            noCollision(part(m, "Eye", Vector3.new(0.75, 0.45, 0.2), pos + Vector3.new(x * 0.8, 10.2, -1.6), C.teal, Enum.Material.Neon))
        end
    else
        local armorColor = kind == "knight" and Color3.fromRGB(56, 74, 102) or Color3.fromRGB(105, 62, 68)
        local rootPart = part(m, "Root", Vector3.new(2.8, 3, 1.8), pos + Vector3.new(0, 3.9, 0), armorColor)
        m.PrimaryPart = noCollision(rootPart)
        noCollision(part(m, "Head", Vector3.new(1.8, 1.8, 1.8), pos + Vector3.new(0, 6.3, 0), Color3.fromRGB(196, 156, 118)))
        noCollision(part(m, "Hood", Vector3.new(2, 0.7, 2), pos + Vector3.new(0, 7.35, 0), C.darkStone))
        noCollision(part(m, "Mask", Vector3.new(1.9, 0.7, 0.3), pos + Vector3.new(0, 5.95, -0.95), C.darkStone))
        for _, x in ipairs({-1, 1}) do
            noCollision(part(m, "Arm", Vector3.new(0.9, 2.8, 1), pos + Vector3.new(x * 1.9, 3.8, 0), C.wood))
            noCollision(part(m, "Leg", Vector3.new(1, 2.4, 1.2), pos + Vector3.new(x * 0.75, 1.2, 0), C.darkStone))
        end
        noCollision(part(m, "Blade", Vector3.new(0.35, 4, 0.65), pos + Vector3.new(2.4, 4, -0.5), C.stone, Enum.Material.Metal))
    end

    -- Distinct silhouettes and readable weak-point accents, entirely offline.
    local function ornament(name, size, offset, color, material, shape)
        local p = noCollision(part(m, name, size, pos + offset, color, material or Enum.Material.SmoothPlastic, shape))
        p.CanTouch = false
        p.CanQuery = false
        return p
    end
    if kind == "boar" then
        for _, x in ipairs({-1, 1}) do
            ornament("Tusk", Vector3.new(0.65, 1.6, 0.65), Vector3.new(x * 0.85, 2.9, -4.45), C.cream)
            ornament("Bristle", Vector3.new(0.55, 1.65, 0.7), Vector3.new(x * 0.55, 4.25, -0.7), C.wood)
        end
        ornament("Snout", Vector3.new(2.1, 1.2, 0.7), Vector3.new(0, 3, -4.7), Color3.fromRGB(153, 98, 90))
    elseif kind == "scorpion" then
        for side = -1, 1 do
            for index = 1, 4 do
                ornament("ScorpionLeg", Vector3.new(2.7, 0.4, 0.55), Vector3.new(side * 2.35, 1.7, (index-2.5)*1.1), Color3.fromRGB(116,48,44))
            end
            ornament("Claw", Vector3.new(2, 1, 1.5), Vector3.new(side * 2.7, 2, -3.8), Color3.fromRGB(192,81,61))
        end
        ornament("Stinger", Vector3.new(0.9, 4.5, 0.9), Vector3.new(0, 5.6, 3.1), Color3.fromRGB(191,76,53))
        ornament("StingerTip", Vector3.new(0.8, 1.4, 0.8), Vector3.new(0, 8, 3.4), C.ink)
    elseif kind == "wolf" or kind == "icewolf" then
        local fur = kind == "icewolf" and Color3.fromRGB(221,237,246) or Color3.fromRGB(86,105,111)
        for side = -1, 1 do
            ornament("FurTuft", Vector3.new(1.1, 1.45, 1.2), Vector3.new(side * 1.25, 3.4, -1.2), fur)
            ornament("Fang", Vector3.new(0.3, 0.8, 0.3), Vector3.new(side * 0.65, 2.8, -4.5), C.cream)
        end
    elseif kind == "bogling" then
        for index = 1, 5 do
            local angle = index * math.pi * 2 / 5
            ornament("MireSpike", Vector3.new(0.6, 2.2, 0.6), Vector3.new(math.cos(angle)*1.3, 3.15, math.sin(angle)*1.3), Color3.fromRGB(47,91,59))
        end
    elseif kind == "wisp" then
        for index = 1, 5 do
            local angle = index * math.pi * 2 / 5
            ornament("SpiritFlame", Vector3.new(0.85, 2.7, 0.85), Vector3.new(math.cos(angle)*2.1, 2.6, math.sin(angle)*2.1), Color3.fromRGB(140,232,255), Enum.Material.Neon, Enum.PartType.Ball)
        end
    elseif kind == "guardian" or kind == "ashgolem" or kind == "ancient" then
        local glow = kind == "ashgolem" and Color3.fromRGB(255,110,54) or kind == "ancient" and Color3.fromRGB(196,126,255) or C.teal
        for side = -1, 1 do
            ornament("ShoulderPlate", Vector3.new(3.3, 2.1, 3), Vector3.new(side*3.8, 8, 0), C.darkStone, Enum.Material.Slate)
            ornament("ArmRune", Vector3.new(0.5, 2.3, 0.3), Vector3.new(side*4, 5.7, -1.15), glow, Enum.Material.Neon)
        end
        ornament("HeartRune", Vector3.new(2.3, 2.8, 0.35), Vector3.new(0, 6, -2.1), glow, Enum.Material.Neon)
        if kind == "ancient" then
            for side = -1, 1 do ornament("CrownHorn", Vector3.new(1.1, 4, 1.1), Vector3.new(side*1.45, 12.6, 0), C.darkStone, Enum.Material.Slate) end
        end
    elseif kind == "knight" or kind == "bandit" then
        ornament("Breastplate", Vector3.new(3.1, 2.6, 0.45), Vector3.new(0, 4.05, -1.15), kind == "knight" and C.stone or C.wood, Enum.Material.Metal)
        ornament("Pauldron", Vector3.new(1.65, 1.2, 1.8), Vector3.new(1.85, 5.1, 0), C.darkStone, Enum.Material.Metal)
        if kind == "knight" then ornament("HelmetCrest", Vector3.new(0.5, 1, 2.2), Vector3.new(0, 7.6, 0), C.gold, Enum.Material.Metal) end
    end
    -- Species-specific readable details, without requiring external assets.
    if kind == "boar" then
        ornament("Mane", Vector3.new(2.5, 1.1, 2.9), Vector3.new(0, 4.2, 0.6), C.wood, Enum.Material.Slate)
        ornament("Nose", Vector3.new(1.6, 0.65, 0.35), Vector3.new(0, 3.05, -5.1), Color3.fromRGB(204,125,117))
    elseif kind == "scorpion" then
        for i = 1, 3 do
            ornament("TailSegment", Vector3.new(1.1, 1.1, 1.3), Vector3.new(0, 3.3 + i*1.2, 3.3+i*0.23), Color3.fromRGB(139,56,49), Enum.Material.Slate)
        end
    elseif kind == "slime" then
        ornament("InnerCore", Vector3.new(2.1, 1.9, 2.1), Vector3.new(0, 2, 0), Color3.fromRGB(152,241,178), Enum.Material.Neon, Enum.PartType.Ball)
    elseif kind == "wisp" then
        ornament("SpiritCore", Vector3.new(1.3, 1.3, 1.3), Vector3.new(0, 1.9, -0.3), C.cream, Enum.Material.Neon, Enum.PartType.Ball)
    elseif kind == "icewolf" then
        ornament("IceCrest", Vector3.new(1.05, 1.4, 2.8), Vector3.new(0, 4.25, 0.5), Color3.fromRGB(165,218,247), Enum.Material.Ice)
    elseif kind == "ashgolem" or kind == "ancient" then
        local glow = kind == "ashgolem" and Color3.fromRGB(244,91,44) or Color3.fromRGB(190,104,245)
        for i = 1, 4 do
            ornament("RiftGlow", Vector3.new(0.35, 1.5, 0.25), Vector3.new((i-2.5)*0.95, 4.2+i*0.5, -2.25), glow, Enum.Material.Neon)
        end
    elseif kind == "knight" then
        ornament("Shield", Vector3.new(2.6, 3.5, 0.55), Vector3.new(-2.55, 3.8, -0.7), Color3.fromRGB(60,85,111), Enum.Material.Metal)
        ornament("ShieldSigil", Vector3.new(1.25, 1.5, 0.15), Vector3.new(-2.55, 3.8, -1.05), C.gold, Enum.Material.Neon)
    end
    m:SetAttribute("EnemyType", kind)
    m:SetAttribute("Health", def.health)
    m:SetAttribute("MaxHealth", def.health)
    m:SetAttribute("Alive", true)
    m:SetAttribute("SpawnPosition", m.PrimaryPart.Position)
    enemyLabel(m, def)
    return m
end

local function npc(parent, pos, coat, name)
    local m = model(parent, name)
    m.PrimaryPart = noCollision(part(m, "Torso", Vector3.new(2, 2.5, 1.3), pos + Vector3.new(0, 3.45, 0), coat))
    noCollision(part(m, "Head", Vector3.new(1.5, 1.5, 1.5), pos + Vector3.new(0, 5.5, 0), Color3.fromRGB(200, 160, 118)))
    noCollision(part(m, "Hair", Vector3.new(1.6, 0.55, 1.6), pos + Vector3.new(0, 6.35, 0), C.wood))
    for _, x in ipairs({-1, 1}) do
        noCollision(part(m, "Arm", Vector3.new(0.7, 2.4, 0.8), pos + Vector3.new(x * 1.4, 3.4, 0), coat))
        noCollision(part(m, "Leg", Vector3.new(0.8, 2.2, 0.9), pos + Vector3.new(x * 0.55, 1.1, 0), C.darkStone))
        noCollision(part(m, "Eye", Vector3.new(0.15, 0.18, 0.1), pos + Vector3.new(x * 0.3, 5.55, -0.8), C.ink))
    end
    return m
end

local function stall(parent, pos, stationId, title, color)
    local m = model(parent, title)
    m:SetAttribute("Station", stationId)
    -- The counter is deliberately close to its prompt, with a clear approach.
    m.PrimaryPart = part(m, "Counter", Vector3.new(13, 2.5, 3), pos + Vector3.new(0, 1.25, 0), C.paleWood, Enum.Material.WoodPlanks)
    for _, x in ipairs({-6, 6}) do
        part(m, "Post", Vector3.new(0.55, 8, 0.55), pos + Vector3.new(x, 4, 2.5), C.wood, Enum.Material.Wood)
    end
    for n = -3, 3 do
        part(m, "Canopy", Vector3.new(2, 0.5, 8), CFrame.new(pos + Vector3.new(n * 2, 8, 1)) * CFrame.Angles(-0.12, 0, 0), n % 2 == 0 and color or C.cream, Enum.Material.Fabric)
    end
    billboard(m.PrimaryPart, title, "E • Interagir", color, 9)
    prompt(m.PrimaryPart, "StationPrompt", "Abrir", title)
    npc(m, pos + Vector3.new(0, 0, 4.5), color, "Keeper")
    crate(m, pos + Vector3.new(-9, 0, 2), 3)
    return m
end

local function house(parent, pos, rotation, color)
    local m = model(parent, "TownHouse")
    local cf = CFrame.new(pos) * CFrame.Angles(0, rotation, 0)
    local function block(name, size, offset, tint, material)
        return part(m, name, size, cf * CFrame.new(offset), tint, material)
    end
    block("Foundation", Vector3.new(23, 2, 19), Vector3.new(0, 1, 0), C.darkStone, Enum.Material.Cobblestone)
    block("Walls", Vector3.new(21, 13, 17), Vector3.new(0, 8, 0), C.plaster)
    for _, x in ipairs({-10, 10}) do
        for _, z in ipairs({-8, 8}) do
            block("Timber", Vector3.new(0.8, 13, 0.8), Vector3.new(x, 8, z), C.wood, Enum.Material.Wood)
        end
    end
    block("Beam", Vector3.new(22, 0.8, 18), Vector3.new(0, 11, 0), C.wood, Enum.Material.Wood)
    for _, x in ipairs({-1, 1}) do
        part(m, "Roof", Vector3.new(13, 1.1, 21), cf * CFrame.new(x * 5.5, 17, 0) * CFrame.Angles(0, 0, -x * 0.45), color, Enum.Material.WoodPlanks)
        block("Window", Vector3.new(3, 3, 0.3), Vector3.new(x * 6, 7.5, -8.6), C.gold, Enum.Material.Glass)
    end
    block("Door", Vector3.new(4.2, 6.5, 0.5), Vector3.new(0, 5.25, -8.8), C.wood, Enum.Material.WoodPlanks)
    block("Chimney", Vector3.new(3, 8, 3), Vector3.new(6, 18, 5), C.darkStone, Enum.Material.Brick)
    return m
end

local function portal(parent, pos, region, name, color, rotation)
    local m = model(parent, "Gate_" .. region)
    m:SetAttribute("Region", region)
    m:SetAttribute("Gateway", true)
    m.PrimaryPart = noCollision(part(m, "TravelStone", Vector3.new(9, 0.5, 9), pos + Vector3.new(0, 0.25, 0), color, Enum.Material.Neon))
    for _, x in ipairs({-6.4, 6.4}) do
        part(m, "Pillar", Vector3.new(2.4, 11, 3), pos + Vector3.new(x, 5.5, 0), C.darkStone, Enum.Material.Slate)
        noCollision(part(m, "Rune", Vector3.new(1, 4, 0.15), pos + Vector3.new(x, 7, -1.6), color, Enum.Material.Neon))
    end
    part(m, "Arch", Vector3.new(15, 2, 3.2), pos + Vector3.new(0, 11.5, 0), C.stone, Enum.Material.Slate)
    billboard(m.PrimaryPart, name, "E • Viajar", color, 14)
    prompt(m.PrimaryPart, "TravelPrompt", "Viajar", name, 0.4)
    if rotation then m:PivotTo(m.PrimaryPart.CFrame * CFrame.Angles(0, rotation, 0)) end
    return m
end

local function mountainRim(ground, decorations, region, center, size, rng)
    local rim = model(ground, "BiomeCliffs_" .. region.id)
    local palette = {
        frost={Color3.fromRGB(151,183,205),Enum.Material.Ice},
        ash={Color3.fromRGB(78,67,68),Enum.Material.Basalt},
        canyon={Color3.fromRGB(169,98,69),Enum.Material.Sandstone},
        forest={Color3.fromRGB(73,94,78),Enum.Material.Rock},
        marsh={Color3.fromRGB(70,91,75),Enum.Material.Ground},
        grove={Color3.fromRGB(79,130,107),Enum.Material.Grass},
        meadow={Color3.fromRGB(116,145,90),Enum.Material.Ground},
    }
    local style = palette[region.id] or {C.darkStone,Enum.Material.Rock}
    for side=1,4 do
        for i=1,20 do
            local segment=size/20+2
            local h=rng:NextNumber(90,175)
            local axis=(i-.5)*size/20-size/2
            local pos,sz
            if side<3 then
                pos=center+Vector3.new(axis,h/2,(side==1 and -1 or 1)*(size/2-20))
                sz=Vector3.new(segment,h,54)
            else
                pos=center+Vector3.new((side==3 and -1 or 1)*(size/2-20),h/2,axis)
                sz=Vector3.new(54,h,segment)
            end
            part(rim,"RockFace",sz,pos,style[1],style[2])
            local wedge=Instance.new("WedgePart")
            wedge.Name="Ridgeline"
            wedge.Anchored=true
            wedge.Size=Vector3.new(sz.X,rng:NextNumber(15,42),sz.Z)
            wedge.Color=style[1]
            wedge.Material=style[2]
            wedge.CFrame=CFrame.new(pos+Vector3.new(0,h/2+wedge.Size.Y/2,0))*CFrame.Angles(0,side<3 and 0 or math.pi/2,0)
            wedge.Parent=rim
        end
    end
    for i=1,30 do
        local x,z=rng:NextNumber(-size*.4,size*.4),rng:NextNumber(-size*.4,size*.4)
        if math.abs(x)>110 and math.abs(z)>110 then
            local hill=Instance.new("WedgePart")
            hill.Name="Hillside"
            hill.Anchored=true
            hill.Size=Vector3.new(rng:NextNumber(55,115),rng:NextNumber(14,48),rng:NextNumber(75,140))
            hill.CFrame=CFrame.new(center+Vector3.new(x,hill.Size.Y/2,z))*CFrame.Angles(0,rng:NextNumber(0,6.28),0)
            hill.Color=rgb(region.color,C.grass)
            hill.Material=region.id=="frost" and Enum.Material.Snow or style[2]
            hill.Parent=decorations
        end
    end
end

local function bridge(parent, pos, alongX)
    local cf = CFrame.new(pos) * CFrame.Angles(0, alongX and math.pi / 2 or 0, 0)
    part(parent, "BridgeDeck", Vector3.new(20, 1, 36), cf * CFrame.new(0, -0.5, 0), C.paleWood, Enum.Material.WoodPlanks)
    for _, side in ipairs({-1, 1}) do
        part(parent, "BridgeRail", Vector3.new(0.6, 0.6, 36), cf * CFrame.new(side * 10, 3.5, 0), C.wood, Enum.Material.Wood)
        for n = -2, 2 do
            part(parent, "BridgePost", Vector3.new(0.8, 5, 0.8), cf * CFrame.new(side * 10, 1.5, n * 8), C.wood, Enum.Material.Wood)
        end
    end
end

local function ruins(parent, center)
    local m = model(parent, "AncientSanctum")
    local p = center + Vector3.new(65, 0, -55)
    part(m, "SanctumFloor", Vector3.new(50, 0.3, 44), p + Vector3.new(0, 0.15, 0), C.darkStone, Enum.Material.Cobblestone)
    for _, x in ipairs({-20, 20}) do
        for _, z in ipairs({-16, 16}) do
            local height = z == 16 and 12 or 21
            part(m, "ColumnBase", Vector3.new(7, 2, 7), p + Vector3.new(x, 1, z), C.stone, Enum.Material.Slate)
            part(m, "Column", Vector3.new(4, height, 4), p + Vector3.new(x, 2 + height / 2, z), C.darkStone, Enum.Material.Slate)
            part(m, "Capital", Vector3.new(6.5, 2, 6.5), p + Vector3.new(x, 3 + height, z), C.stone, Enum.Material.Slate)
        end
    end
    part(m, "BrokenArch", Vector3.new(48, 3, 6), p + Vector3.new(0, 26, -16), C.darkStone, Enum.Material.Slate)
    for n = 1, 4 do
        noCollision(part(m, "Rune", Vector3.new(2, 0.25, 8), CFrame.new(p + Vector3.new((n - 2.5) * 6, 0.45, 0)) * CFrame.Angles(0, 0.3, 0), Color3.fromRGB(157, 124, 235), Enum.Material.Neon))
    end
    return m
end

local function regionTitle(parent, region, center)
    local sign = part(parent, "RegionSign", Vector3.new(14, 5, 1), center + Vector3.new(17, 4.5, 0), C.wood, Enum.Material.WoodPlanks)
    part(parent, "SignPost", Vector3.new(0.8, 7, 0.8), center + Vector3.new(17, 3.5, 0), C.darkStone)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.CanvasSize = Vector2.new(420, 150)
    gui.Parent = sign
    local title = text(gui, "Name", string.upper(region.name), C.cream, UDim2.fromScale(0.96, 0.6), UDim2.fromScale(0.02, 0))
    title.TextScaled = true
    title.TextWrapped = true
    local subtitle = region.safe and "SANTUÁRIO • COMÉRCIO" or ("EXPEDIÇÃO • NÍVEL " .. tostring(region.level))
    local sub = text(gui, "Difficulty", subtitle, C.gold, UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0.65))
    sub.TextScaled = true
end

function World.Build()
    local previous = Workspace:FindFirstChild("BrumavaleWorld")
    if previous then
        assert(previous:IsA("Folder") and previous:GetAttribute("BrumavaleGenerated") == true and previous:GetAttribute("Version") == VERSION,
            "BrumavaleWorld already exists and is not a compatible generated world; move it manually before installing.")
        return previous
    end
    local root = Instance.new("Folder")
    root.Name = "BrumavaleWorld"
    root:SetAttribute("BrumavaleGenerated", true)
    root:SetAttribute("Version", VERSION)
    local ground = folder(root, "TerrainParts")
    local decor = folder(root, "Decorations")
    local resources = folder(root, "Resources")
    local enemies = folder(root, "Enemies")
    local stations = folder(root, "Stations")
    local portals = folder(root, "Portals")
    local rng = Random.new(17429)
    local regionsById = {}
    for _, region in ipairs(Config.Regions) do regionsById[region.id] = region end

    -- Water and cliff skirts unify the region silhouettes without touching Terrain.
    -- The lagoon sits just above Roblox's default Baseplate, while all playable
    -- surfaces are lifted one stud below. A fresh Baseplate template therefore
    -- looks intentional without deleting or editing any user-owned object.
    local water = noCollision(part(ground, "Lagoon", Vector3.new(12500, 1, 12500), Vector3.new(0, -0.9, 0), Color3.fromRGB(43, 100, 119), Enum.Material.Glass))
    water.Transparency = 0.25
    water.CastShadow = false
    water.CanTouch = false
    for _, region in ipairs(Config.Regions) do
        local center = vector(region.center)
        local size = region.size or 240
        local color = rgb(region.color, C.grass)
        local land = part(ground, "Island_" .. region.id, Vector3.new(size, 8, size), center + Vector3.new(0, -3.95, 0), color, region.id == "quarry" and Enum.Material.Slate or Enum.Material.Grass)
        land:SetAttribute("Region", region.id)
        mountainRim(ground, decor, region, center, size, rng)
        part(ground, "Cliff_" .. region.id, Vector3.new(size - 6, 18, size - 6), center + Vector3.new(0, -15, 0), C.darkStone, Enum.Material.Slate)
        -- The cardinal roads align with all inter-island bridges and remain clear.
        part(ground, "RoadNS", Vector3.new(14, 0.12, size), center + Vector3.new(0, 0.06, 0), region.safe and Color3.fromRGB(153, 153, 132) or Color3.fromRGB(154, 141, 104), region.safe and Enum.Material.Cobblestone or Enum.Material.Ground)
        part(ground, "RoadEW", Vector3.new(size, 0.1, 14), center + Vector3.new(0, 0.05, 0), region.safe and Color3.fromRGB(153, 153, 132) or Color3.fromRGB(154, 141, 104), region.safe and Enum.Material.Cobblestone or Enum.Material.Ground)
        regionTitle(decor, region, center)
        -- Border portals are placed by the adjacency graph below.
    end
    -- Expanded islands are connected through travel portals instead of short bridges.

    -- Town square: readable approaches, service counters, fountain and waystones.
    part(ground, "TownSquare", Vector3.new(116, 0.16, 116), Vector3.new(0, 0.08, 10), Color3.fromRGB(159, 155, 130), Enum.Material.Cobblestone)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "TownSpawn"
    spawn.Size = Vector3.new(12, 0.4, 12)
    spawn.Position = Vector3.new(0, 0.3, 20)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 3
    spawn.Transparency = 1
    spawn.CanCollide = false
    spawn.Parent = root
    local fountain = model(decor, "Fountain")
    part(fountain, "Basin", Vector3.new(15, 2, 15), Vector3.new(0, 1, -27), C.darkStone, Enum.Material.Slate)
    noCollision(part(fountain, "Water", Vector3.new(12, 0.4, 12), Vector3.new(0, 2, -27), C.teal, Enum.Material.Glass))
    part(fountain, "Pedestal", Vector3.new(3, 6, 3), Vector3.new(0, 4, -27), C.stone, Enum.Material.Slate)
    noCollision(part(fountain, "Crest", Vector3.new(3.5, 3.5, 3.5), CFrame.new(0, 8, -27) * CFrame.Angles(0, 0, math.pi / 4), C.gold, Enum.Material.Metal))
    stall(stations, Vector3.new(-35, 0, 0), "shop", "EMPÓRIO DA BRUMA", Color3.fromRGB(91, 158, 150))
    local forge = stall(stations, Vector3.new(35, 0, 0), "craft", "FORJA & OFICINA", Color3.fromRGB(204, 129, 82))
    part(forge, "AnvilBase", Vector3.new(3, 2, 3), Vector3.new(43, 1, -4), C.wood, Enum.Material.Wood)
    part(forge, "Anvil", Vector3.new(5, 1.2, 2.5), Vector3.new(43, 2.6, -4), C.darkStone, Enum.Material.Metal)
    local coal = noCollision(part(forge, "Coals", Vector3.new(3, 0.5, 3), Vector3.new(43, 0.8, 4), Color3.fromRGB(245, 142, 65), Enum.Material.Neon))
    local glow = Instance.new("PointLight")
    glow.Color = coal.Color
    glow.Range = 12
    glow.Brightness = 0.7
    glow.Parent = coal
    stall(stations, Vector3.new(-35, 0, 45), "market", "MERCADO DOS VIAJANTES", C.gold)
    stall(stations, Vector3.new(35, 0, 45), "quest", "MURAL DE CONTRATOS", Color3.fromRGB(141, 128, 188))
    for _, location in ipairs({{-70, -53, 0}, {65, -55, 0}, {-72, 65, math.pi}, {70, 69, math.pi}}) do
        house(decor, Vector3.new(location[1], 0, location[2]), location[3], C.roof)
    end
    for _, location in ipairs({{-18, 15}, {18, 15}, {-56, 24}, {56, 24}, {-20, -50}, {20, -50}}) do
        lantern(decor, Vector3.new(location[1], 0, location[2]))
    end
    -- Each gate connects physically neighboring provinces, not a city hub.
    for _, origin in ipairs(Config.Regions) do
        local c=vector(origin.center)
        for _, dest in ipairs(Config.Regions) do
            local dx=dest.center[1]-origin.center[1]
            local dz=dest.center[3]-origin.center[3]
            if (math.abs(dx)==2200 and dz==0) or (math.abs(dz)==2200 and dx==0) then
                local dir=Vector3.new(dx==0 and 0 or dx/math.abs(dx),0,dz==0 and 0 or dz/math.abs(dz))
                local gate=portal(portals,c+dir*(origin.size*.36),dest.id,dest.name,rgb(dest.color,C.teal),dx~=0 and math.pi/2 or nil)
                gate:SetAttribute("OriginRegion",origin.id)
                local roadCenter=c+dir*(origin.size*.21)
                local roadSize=dx~=0 and Vector3.new(origin.size*.34,.14,15) or Vector3.new(15,.14,origin.size*.34)
                part(ground,"GateTrail",roadSize,roadCenter+Vector3.new(0,.12,0),C.paleWood,Enum.Material.Ground)
            end
        end
    end

    -- Resource placements are curated around the roads, never on arrival areas.
    local resourceIndex = 0
    local function node(regionId, kind, x, z)
        resourceIndex = resourceIndex + 1
        return resource(resources, kind, vector(regionsById[regionId].center) + Vector3.new(x, 0, z), resourceIndex, rng)
    end
    local layouts = {
        meadow = {{"tree", -40, 45}, {"tree", 45, 40}, {"tree", -75, -20}, {"fiber", 25, 46}, {"fiber", 35, 55}, {"fiber", -35, 65}, {"fiber", 65, -35}, {"rock", -50, -50}, {"rock", 55, -55}},
        forest = {{"tree", -45, 45}, {"tree", 40, 40}, {"tree", 65, -35}, {"tree", -55, -50}, {"tree", 85, 60}, {"tree", -80, 75}, {"fiber", 30, -40}, {"fiber", -35, 50}, {"rock", -70, -70}},
        quarry = {{"rock", -40, 45}, {"rock", 40, 40}, {"rock", 68, -35}, {"ore", -55, -50}, {"ore", 65, 65}, {"ore", -80, 70}, {"ore", 30, -45}, {"ore", -35, 65}, {"crystal", -85, -80}},
        ruins = {{"crystal", -45, 40}, {"crystal", 40, 50}, {"crystal", -65, -40}, {"ore", -85, 65}, {"rock", 75, 75}, {"fiber", 25, -40}},
        marsh = {{"fiber",-100,90},{"tree",95,-100},{"rock",120,120}},
        highlands = {{"tree",105,105},{"rock",-120,-110},{"fiber",90,-90}},
        frost = {{"rock",-120,95},{"ore",105,-110},{"crystal",130,100}},
        ash = {{"ore",110,120},{"rock",-125,-125},{"crystal",110,-100}},
        canyon = {{"ore",115,95},{"rock",-110,-120},{"crystal",125,-90}},
        grove = {{"fiber",105,110},{"tree",-115,-100},{"crystal",110,-100}},
        citadel = {{"crystal",120,-120},{"ore",-120,105},{"rock",-105,-105}},
    }
    for _, region in ipairs(Config.Regions) do
        for _, row in ipairs(layouts[region.id] or {}) do node(region.id, row[1], row[2], row[3]) end
        if not region.safe then
            local kinds = region.id == "marsh" and {"fiber","tree","rock"} or
                region.id == "grove" and {"fiber","tree","crystal"} or
                region.id == "meadow" and {"fiber","tree","rock"} or
                region.id == "forest" and {"tree","fiber","rock"} or {"rock","ore","crystal"}
            for n = 1, 15 do
                local x, z = rng:NextNumber(-208,208), rng:NextNumber(-208,208)
                if math.abs(x) > 24 and math.abs(z) > 24 then
                    node(region.id, kinds[(n % #kinds)+1], x, z)
                end
            end
        end
    end
    -- Low-density border vegetation creates silhouettes while limiting draw calls.
    for _, region in ipairs(Config.Regions) do
        local center = vector(region.center)
        if region.id == "town" or region.id == "meadow" or region.id == "forest" or region.id == "grove" or region.id == "marsh" or region.id == "highlands" then
            for n = 1, 24 do
                local angle = n * math.pi / 12 + 0.17
                local pos = center + Vector3.new(math.cos(angle) * 208, 0, math.sin(angle) * 208)
                if region.id == "forest" then pine(decor, pos, rng) else tree(decor, pos, rng, region.id == "town") end
            end
        else
            for n = 1, 24 do
                local angle = n * math.pi / 12 + 0.17
                local pos = center + Vector3.new(math.cos(angle) * 208, 0, math.sin(angle) * 208)
                part(decor, "CliffBoulder", Vector3.new(rng:NextNumber(9, 16), rng:NextNumber(7, 16), rng:NextNumber(9, 16)), CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0.1, angle, 0.15), C.darkStone, Enum.Material.Slate)
            end
        end
    end
    local quarryCenter = vector(regionsById.quarry.center)
    local mining = model(decor, "MiningCamp")
    for _, x in ipairs({-5, 5}) do
        part(mining, "PitSupport", Vector3.new(1.6, 12, 1.6), quarryCenter + Vector3.new(65 + x, 6, -65), C.wood, Enum.Material.Wood)
    end
    part(mining, "PitBeam", Vector3.new(14, 1.8, 2), quarryCenter + Vector3.new(65, 12, -65), C.wood, Enum.Material.Wood)
    crate(mining, quarryCenter + Vector3.new(80, 0, -65), 4)
    crate(mining, quarryCenter + Vector3.new(84, 0, -59), 3)
    ruins(decor, vector(regionsById.ruins.center))
    local forestCenter = vector(regionsById.forest.center)
    for n = 1, 4 do
        noCollision(part(decor, "ForestMushroom", Vector3.new(2.6, 1.3, 2.6), forestCenter + Vector3.new(-65 + n * 4, 1.5, 35), Color3.fromRGB(155, 110, 181), Enum.Material.SmoothPlastic, Enum.PartType.Ball))
    end

    -- Three recognizable landmarks per wilderness region.
    for _, region in ipairs(Config.Regions) do
        if not region.safe then
            local center = vector(region.center)
            local landmark = model(decor, "Landmark_" .. region.id)
            for n = 1, 3 do
                local position = center + Vector3.new((n-2)*65+85, 0, n%2==0 and 140 or -140)
                if region.id == "ruins" or region.id == "citadel" or region.id == "ash" then
                    for k = 1, 4 do
                        part(landmark, "AncientColumn", Vector3.new(4, 8+k*2, 4), position+Vector3.new(k*7,4+k,0),C.darkStone,Enum.Material.Slate)
                    end
                elseif region.id == "quarry" or region.id == "canyon" or region.id == "frost" then
                    for k = 1, 5 do
                        part(landmark,"RockFormation",Vector3.new(7+k,6+k*2,7+k),position+Vector3.new(k*7,3+k,0),C.stone,Enum.Material.Slate)
                    end
                else
                    house(landmark, position, n*0.7,C.roof)
                    lantern(landmark,position+Vector3.new(18,0,9))
                end
                crate(landmark,position+Vector3.new(-12,0,14),3)
            end
        end
    end
    local enemyIndex = 0
    local spawns = {
        meadow = {{"slime", -68, 40}, {"slime", 65, 50}, {"slime", 45, -70}, {"slime", -65, -65}},
        forest = {{"wolf", -70, 42}, {"wolf", 72, 40}, {"wolf", 45, -75}, {"bandit", -65, -70}},
        quarry = {{"bandit", -70, 40}, {"bandit", 75, 40}, {"bandit", 45, -72}},
        ruins = {{"bandit", -70, 40}, {"bandit", -60, -65}, {"guardian", 65, -55}},
        marsh = {{"bogling",-110,110},{"bogling",100,-120},{"boar",125,100}},
        highlands = {{"boar",-120,100},{"wolf",120,-120},{"bandit",100,120}},
        frost = {{"icewolf",-120,110},{"icewolf",120,-110},{"wisp",110,120}},
        ash = {{"ashgolem",-120,105},{"wisp",120,-115},{"ashgolem",110,110}},
        canyon = {{"scorpion",-120,110},{"scorpion",120,-100},{"knight",115,120}},
        grove = {{"wisp",-120,105},{"boar",120,-120},{"wisp",110,110}},
        citadel = {{"knight",-120,100},{"knight",120,-110},{"ancient",105,115}},
    }
    for _, region in ipairs(Config.Regions) do
        if not region.safe then
            local entries = spawns[region.id] or {}
            for _, row in ipairs(entries) do
                enemyIndex += 1
                local m = enemy(enemies,row[1],vector(region.center)+Vector3.new(row[2],0,row[3]),enemyIndex)
                m:SetAttribute("Region",region.id)
            end
            for n = 1, 5 do
                local kind = entries[(n % #entries)+1][1]
                local x,z = rng:NextNumber(-205,205),rng:NextNumber(-205,205)
                if math.abs(x) < 24 then x += 50 end
                if math.abs(z) < 24 then z += 50 end
                enemyIndex += 1
                local m = enemy(enemies,kind,vector(region.center)+Vector3.new(x,0,z),enemyIndex)
                m:SetAttribute("Region",region.id)
            end
        end
    end

    -- Keep the world above the default Baseplate, preserving every pre-existing
    -- place object while avoiding z-fighting and grey gaps between islands.
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") then descendant.CFrame = descendant.CFrame + Vector3.new(0, 1, 0) end
    end
    for _, collection in ipairs({resources, enemies}) do
        for _, object in ipairs(collection:GetChildren()) do
            if object:IsA("Model") and object.PrimaryPart then object:SetAttribute("SpawnPosition", object.PrimaryPart.Position) end
        end
    end

    -- Only publish the finished hierarchy, keeping an interrupted build isolated.
    root.Parent = Workspace
    return root
end

return World
