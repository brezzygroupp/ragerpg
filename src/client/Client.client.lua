-- Brumavale • interface e controles. Toda alteração de jogo é validada pelo servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local package = ReplicatedStorage:WaitForChild("Brumavale")
local Config = require(package:WaitForChild("Config"))
local Action = package:WaitForChild("Action")
local State = package:WaitForChild("State")
local GetState = package:WaitForChild("GetState")
local FX = package:WaitForChild("FX")
local world = workspace:WaitForChild("BrumavaleWorld")
local mouse = player:GetMouse()
local palette = {
    ink = Color3.fromRGB(14, 23, 32), panel = Color3.fromRGB(22, 35, 45),
    raised = Color3.fromRGB(30, 47, 58), edge = Color3.fromRGB(58, 77, 85),
    text = Color3.fromRGB(235, 232, 217), muted = Color3.fromRGB(158, 177, 181),
    gold = Color3.fromRGB(222, 182, 98), teal = Color3.fromRGB(87, 194, 174),
    red = Color3.fromRGB(218, 103, 98), green = Color3.fromRGB(123, 187, 132),
}
local snapshot
local selectedItem = "sword1"
local selectedRecipe = "plank"
local activeTab = "inventory"
local selectedEnemy
local isometric = false
local cooldowns = { basic = 0, cleave = 0, potion = 0 }
local normalCameraType
local normalCameraSubject
local panelOpen = false
local quantityText, priceText
local renderPage, updateHUD, openPanel, toast
local combatAnimations = {}
local cameraShake = 0

local gui = Instance.new("ScreenGui")
gui.Name = "BrumavaleUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")
gui:SetAttribute("Version", Config.Version)

local damageFlash = Instance.new("Frame")
damageFlash.Name = "DamageFlash"
damageFlash.Size = UDim2.fromScale(1, 1)
damageFlash.BackgroundColor3 = Color3.fromRGB(205, 53, 55)
damageFlash.BackgroundTransparency = 1
damageFlash.BorderSizePixel = 0
damageFlash.ZIndex = 90
damageFlash.Parent = gui

local function create(className, parent, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function rounded(object, radius)
    create("UICorner", object, { CornerRadius = UDim.new(0, radius or 8) })
end
local function stroke(object, color)
    return create("UIStroke", object, { Color = color or palette.edge, Thickness = 1, Transparency = 0.3 })
end
local function frame(parent, properties)
    properties.BorderSizePixel = 0
    local object = create("Frame", parent, properties)
    rounded(object)
    return object
end
local function label(parent, text, properties)
    local defaults = {
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = text,
        TextColor3 = palette.text, Font = Enum.Font.Gotham, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
    }
    for key, value in pairs(properties or {}) do defaults[key] = value end
    return create("TextLabel", parent, defaults)
end
local function button(parent, text, properties, callback)
    local defaults = {
        BorderSizePixel = 0, BackgroundColor3 = palette.raised, Text = text,
        TextColor3 = palette.text, Font = Enum.Font.GothamBold, TextSize = 13,
        AutoButtonColor = true,
    }
    for key, value in pairs(properties or {}) do defaults[key] = value end
    local object = create("TextButton", parent, defaults)
    rounded(object, 6)
    if callback then object.Activated:Connect(callback) end
    return object
end
local function shortNumber(value)
    value = math.floor(tonumber(value) or 0)
    if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if value >= 10000 then return string.format("%.1fk", value / 1000) end
    return tostring(value)
end
local function itemName(id)
    return Config.Items[id] and Config.Items[id].name or tostring(id)
end
local function quantity()
    return math.clamp(math.floor(tonumber(quantityText and quantityText.Text) or 1), 1, 99)
end
local function send(action, payload)
    if not snapshot then toast("Seu aventureiro ainda está carregando.") return end
    Action:FireServer(action, payload or {})
end
local function regionById(id)
    for _, region in ipairs(Config.Regions) do
        if region.id == id then return region end
    end
    return Config.Regions[1]
end
local function characterParts()
    local character = player.Character
    if not character then return nil, nil end
    return character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
end

-- Combat animation is procedural so the project needs no uploaded animation IDs.
-- Motor6D.Transform is written locally after the default Animator and released at
-- the end of each short action, preserving Roblox's normal locomotion afterward.
local clientEffects = Instance.new("Folder")
clientEffects.Name = "BrumavaleClientEffects"
clientEffects.Parent = world

local function motor(character, ...)
    local names = {}
    for index = 1, select("#", ...) do names[select(index, ...)] = true end
    -- Some custom avatars rename Motor6D joints; search both name and Part1.
    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("Motor6D") and names[object.Name] then return object end
    end
    local requested = select(1, ...)
    local target = requested == "RightShoulder" and {"RightUpperArm", "Right Arm"}
        or requested == "LeftShoulder" and {"LeftUpperArm", "Left Arm"}
        or requested == "Waist" and {"UpperTorso", "Torso"}
        or requested == "Neck" and {"Head"} or {}
    for _, partName in ipairs(target) do
        for _, object in ipairs(character:GetDescendants()) do
            if object:IsA("Motor6D") and object.Part1 and object.Part1.Name == partName then
                return object
            end
        end
    end
    return nil
end

-- Animate Motor6D.C0, not Transform: Roblox's Animator can overwrite Transform
-- before the pose reaches the screen. Store each rig's original C0 for recovery.
local function resetCombatAnimation(state)
    for _, entry in pairs(state.motors or {}) do
        if entry and entry.joint and entry.joint.Parent then
            entry.joint.C0 = entry.original
        end
    end
end
local function jointEntry(character, ...)
    local joint = motor(character, ...)
    return joint and {joint=joint, original=joint.C0} or nil
end
local function poseJoint(entry, offset)
    if entry and entry.joint and entry.joint.Parent then
        entry.joint.C0 = entry.original * offset
    end
end

-- Use native Roblox AnimationTracks as the primary animation path.
-- Default Roblox sword slash/lunge are keyframed and work on standard R15/R6 rigs.
local nativeTracks = {}
local comboIndex = {}
local lastComboAt = {}
local nativeIds = {
    R15 = {basic="522635514", cleave="522638767", gather="522635514", hit="522638767"},
    R6 = {basic="129967390", cleave="129967478", gather="129967390", hit="129967478"},
}
local function playNativeAnimation(actor, action)
    local character = actor.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false, "sem Humanoid" end
    local rigType = humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
    local combo = comboIndex[character] or 1
    local id = nativeIds[rigType][action]
    -- Deliberately avoid the spinning lunge; short horizontal slashes read as swordplay.
    if action == "basic" and combo == 3 then id = nativeIds[rigType].basic end
    if action == "cleave" then id = nativeIds[rigType].basic end
    if not id then return false, "sem animacao para " .. action end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    local slot = nativeTracks[character]
    if slot and slot.track then pcall(function() slot.track:Stop(0.08) end) end
    local animation = Instance.new("Animation")
    animation.Name = "Brumavale_" .. action
    animation.AnimationId = "rbxassetid://" .. id
    local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
    animation:Destroy()
    if not ok or not track then
        return false, tostring(track)
    end
    track.Priority = Enum.AnimationPriority.Action4
    track.Looped = false
    local played, err = pcall(function() track:Play(0.10, 1, action == "cleave" and 0.72 or (action == "basic" and (combo == 2 and 1.08 or combo == 3 and 0.88 or 0.98) or 1)) end)
    if not played then return false, tostring(err) end
    nativeTracks[character] = {track=track, action=action}
    track.Stopped:Once(function()
        if nativeTracks[character] and nativeTracks[character].track == track then nativeTracks[character] = nil end
        track:Destroy()
    end)
    return true, "AnimationTrack " .. tostring(id)
end
local animationDurations = {basic=0.52, cleave=0.82, gather=0.68, potion=0.72, hit=0.34}
local attackCombo = {}
local lastLocalAttack = 0
local swordVisuals = {}
local swordSwings = {}
local function swingSword(character, action, combo)
    local sword = swordVisuals[character]
    local grip = sword and sword:FindFirstChild("Grip")
    local weld = grip and grip:FindFirstChild("HandMount")
    if not weld or not weld:IsA("Weld") then return end
    local base = weld:GetAttribute("BrumavaleBase") -- position is held in script state below
    local swing = swordSwings[character]
    if swing and swing.weld == weld then
        for _, tween in ipairs(swing.tweens) do tween:Cancel() end
        weld.C0 = swing.base
    end
    local rest = swing and swing.weld == weld and swing.base or weld.C0
    local direction = combo == 2 and -1 or 1
    local windup = action == "cleave" and 0.23 or 0.17
    local release = action == "cleave" and 0.32 or 0.23
    local raised = rest * CFrame.Angles(math.rad(-24), 0, math.rad(25 * direction))
    local follow = rest * CFrame.Angles(math.rad(36), math.rad(12 * direction), math.rad(-48 * direction))
    local sequence = {weld=weld, base=rest, tweens={}}
    swordSwings[character] = sequence
    local function tween(goal, seconds, easing)
        local tw = TweenService:Create(weld, TweenInfo.new(seconds, easing or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {C0=goal})
        table.insert(sequence.tweens, tw)
        return tw
    end
    local up = tween(raised, windup, Enum.EasingStyle.Quad)
    up.Completed:Connect(function(state)
        if state ~= Enum.PlaybackState.Completed or swordSwings[character] ~= sequence then return end
        local strike = tween(follow, release)
        strike.Completed:Connect(function(finished)
            if finished ~= Enum.PlaybackState.Completed or swordSwings[character] ~= sequence then return end
            local recovery = tween(rest, 0.20, Enum.EasingStyle.Sine)
            recovery.Completed:Connect(function()
                if swordSwings[character] == sequence then swordSwings[character] = nil end
            end)
            recovery:Play()
        end)
        strike:Play()
    end)
    up:Play()
end

local function ensureSwordVisual(character)
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if not hand or not hand:IsA("BasePart") then return end
    local existing = swordVisuals[character]
    if existing and existing.Parent and existing:FindFirstChild("Grip") then return end
    local sword = Instance.new("Model")
    sword.Name = "BrumavaleCombatSword"
    local function segment(name, size, color, material, offset)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.Color = color
        p.Material = material
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.Massless = true
        p.Anchored = false
        p.CFrame = hand.CFrame * offset
        p.Parent = sword
        return p
    end
    local grip = segment("Grip", Vector3.new(0.35, 1.35, 0.35), Color3.fromRGB(72, 48, 35), Enum.Material.Wood, CFrame.new(0, -0.65, -0.15))
    local guard = segment("Crossguard", Vector3.new(1.7, 0.3, 0.35), Color3.fromRGB(225, 178, 83), Enum.Material.Metal, CFrame.new(0, -1.55, -0.15))
    local blade = segment("Blade", Vector3.new(0.42, 3.9, 0.16), Color3.fromRGB(208, 225, 230), Enum.Material.Metal, CFrame.new(0, -3.6, -0.15))
    local point = segment("BladeTip", Vector3.new(0.28, 0.7, 0.12), Color3.fromRGB(239, 246, 255), Enum.Material.Metal, CFrame.new(0, -5.8, -0.15))
    for _, p in ipairs({guard, blade, point}) do
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = grip
        weld.Part1 = p
        weld.Parent = p
    end
    local handWeld = Instance.new("Weld")
    handWeld.Name = "HandMount"
    handWeld.Part0 = hand
    handWeld.Part1 = grip
    handWeld.C0 = hand.CFrame:ToObjectSpace(grip.CFrame)
    handWeld.Parent = grip
    sword.Parent = character
    swordVisuals[character] = sword
end
local function startCombatAnimation(actor, action)
    if typeof(actor) ~= "Instance" or not actor:IsA("Player") or actor.Parent ~= Players or type(action) ~= "string" then return end
    local character = actor.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid or humanoid.Health <= 0 or not animationDurations[action] then return end
    local localRoot = characterParts()
    local actorRoot = character:FindFirstChild("HumanoidRootPart")
    if actor ~= player and (not localRoot or not actorRoot or (localRoot.Position - actorRoot.Position).Magnitude > 160) then return end
    local previous = combatAnimations[character]
    if previous then resetCombatAnimation(previous) end
    if action == "basic" then
        local now = os.clock()
        if now - (lastComboAt[character] or -10) > 1.4 then attackCombo[character] = 0 end
        attackCombo[character] = ((attackCombo[character] or 0) % 3) + 1
        lastComboAt[character] = now
        comboIndex[character] = attackCombo[character]
    end
    if action == "basic" or action == "cleave" then
        ensureSwordVisual(character)
        swingSword(character, action, attackCombo[character] or 1)
    end
    local nativeOK, nativeMessage = playNativeAnimation(actor, action)
    if actor == player then
        gui:SetAttribute("NativeAnimation", nativeOK and nativeMessage or "FALHOU: " .. nativeMessage)
        if not nativeOK then warn("[Brumavale Anim] Falha no Animator: " .. nativeMessage) end
    end
    local joints = {
        right=jointEntry(character, "RightShoulder", "Right Shoulder"),
        left=jointEntry(character, "LeftShoulder", "Left Shoulder"),
        waist=jointEntry(character, "Waist", "RootJoint", "Root Joint"),
        neck=jointEntry(character, "Neck"),
    }
    local rig = humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
    local count = 0
    for _, entry in pairs(joints) do if entry then count += 1 end end
    if actor == player then
        gui:SetAttribute("CombatRig", rig)
        gui:SetAttribute("CombatJoints", count)
        gui:SetAttribute("CombatAction", action)
        if count == 0 then
            warn("[Brumavale Anim] Nenhuma junta encontrada em " .. character:GetFullName())
        end
    end
    combatAnimations[character] = {
        action=action, combo=attackCombo[character] or 1, started=os.clock(), duration=animationDurations[action],
        motors=joints,
    }
end

-- Diagnostic stays visible: proves whether a real avatar rig receives poses.
local animStatus = Instance.new("TextLabel")
animStatus.Name = "AnimationStatus"
animStatus.Size = UDim2.fromOffset(350, 26)
animStatus.AnchorPoint = Vector2.new(0.5, 0)
animStatus.Position = UDim2.new(0.5, 0, 0, 70)
animStatus.BackgroundTransparency = 0.3
animStatus.BackgroundColor3 = Color3.fromRGB(20, 30, 39)
animStatus.TextColor3 = Color3.fromRGB(255, 223, 142)
animStatus.TextSize = 13
animStatus.Font = Enum.Font.GothamBold
animStatus.Text = "Brumavale Anim: aguardando teste"
animStatus.Parent = gui
local function refreshAnimationStatus()
    animStatus.Text = string.format("ANIM %s | joints %s | %s",
        tostring(gui:GetAttribute("CombatRig") or "?"),
        tostring(gui:GetAttribute("CombatJoints") or "?"),
        tostring(gui:GetAttribute("NativeAnimation") or "aguardando"))
end
gui:GetAttributeChangedSignal("CombatAction"):Connect(refreshAnimationStatus)
gui:GetAttributeChangedSignal("NativeAnimation"):Connect(refreshAnimationStatus)
local animTest = Instance.new("TextButton")
animTest.Name = "TestPlayerAnimation"
animTest.Size = UDim2.fromOffset(170, 30)
animTest.AnchorPoint = Vector2.new(0.5, 0)
animTest.Position = UDim2.new(0.5, 0, 0, 99)
animTest.BackgroundColor3 = Color3.fromRGB(52, 81, 91)
animTest.TextColor3 = Color3.new(1, 1, 1)
animTest.TextSize = 13
animTest.Font = Enum.Font.GothamBold
animTest.Text = "TESTAR ANIMACAO"
animTest.Parent = gui
animTest.Activated:Connect(function()
    startCombatAnimation(player, "cleave")
end)

local function effectPart(size, cframe, color, life, shape)
    if #clientEffects:GetChildren() >= 150 then return nil end
    local part = Instance.new("Part")
    part.Name = "CombatFX"
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = Enum.Material.Neon
    part.Transparency = 0.18
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    if shape then part.Shape = shape end
    part.Parent = clientEffects
    Debris:AddItem(part, life or 0.5)
    return part
end

local function burst(position, color, radius)
    if typeof(position) ~= "Vector3" then return end
    local localRoot = characterParts()
    if not localRoot or (localRoot.Position - position).Magnitude > 170 then return end
    radius = math.clamp(tonumber(radius) or 5, 2, 18)
    for index = 1, 8 do
        local angle = index * math.pi * 0.25
        local direction = Vector3.new(math.cos(angle), 0.35 + (index % 2) * 0.2, math.sin(angle)).Unit
        local part = effectPart(Vector3.new(0.28, 0.28, 2.4), CFrame.lookAt(position, position + direction), color, 0.42)
        if part then
            TweenService:Create(part, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CFrame=part.CFrame + direction * radius, Transparency=1, Size=Vector3.new(0.08, 0.08, 0.8),
            }):Play()
        end
    end
end

local function actionEffect(actor, action, target)
    local character = actor.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local localRoot = characterParts()
    if actor ~= player and (not localRoot or (localRoot.Position - root.Position).Magnitude > 160) then return end
    if action == "basic" then
		local strikeCFrame = root.CFrame
		if typeof(target) == "Instance" and target:IsA("Model") and target.PrimaryPart then
			local delta = Vector3.new(target.PrimaryPart.Position.X - root.Position.X, 0, target.PrimaryPart.Position.Z - root.Position.Z)
			if delta.Magnitude > 0.05 then strikeCFrame = CFrame.lookAt(root.Position, root.Position + delta.Unit) end
		end
        for index = -1, 1 do
            local part = effectPart(Vector3.new(0.14, 5.5, 0.65), strikeCFrame * CFrame.new(index * 0.45, 1.2, -4.2) * CFrame.Angles(0, 0, math.rad(48 + index * 7)), palette.gold, 0.36)
            if part then
                TweenService:Create(part, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Transparency=1, Size=Vector3.new(0.05, 7, 0.2),
                }):Play()
            end
        end
    elseif action == "cleave" then
        for index = 1, 18 do
            local angle = index * math.pi * 2 / 18
            local position = root.Position + Vector3.new(math.cos(angle) * 6.3, -2.65, math.sin(angle) * 6.3)
            local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
            local part = effectPart(Vector3.new(0.35, 0.16, 2.6), CFrame.lookAt(position, position + tangent), palette.gold, 0.52)
            if part then
                TweenService:Create(part, TweenInfo.new(0.45), {Transparency=1, Size=Vector3.new(0.1, 0.08, 3.8)}):Play()
            end
        end
    elseif action == "gather" then
        burst(root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 1.2, 0), palette.teal, 3.5)
    elseif action == "potion" then
        local orb = effectPart(Vector3.new(1.2, 1.2, 1.2), root.CFrame * CFrame.new(0, 1, -1.2), palette.green, 0.75, Enum.PartType.Ball)
        if orb then
            TweenService:Create(orb, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CFrame=orb.CFrame + Vector3.new(0, 3.5, 0), Size=Vector3.new(3.5, 3.5, 3.5), Transparency=1,
            }):Play()
        end
    end
end

local function animateCombat(now)
    for character, state in pairs(combatAnimations) do
        local elapsed = now - state.started
        local progress = math.clamp(elapsed / state.duration, 0, 1)
        local motors = state.motors
        local right, left, waist, neck = CFrame.new(), CFrame.new(), CFrame.new(), CFrame.new()
        if state.action == "basic" then
            local direction = state.combo == 2 and -1 or 1
            if progress < 0.28 then
                local alpha = progress / 0.28
                right = CFrame.new():Lerp(CFrame.Angles(math.rad(-80), math.rad(-20), math.rad(55 * direction)), alpha)
                waist = CFrame.Angles(0, math.rad(35 * alpha * direction), math.rad(8 * alpha))
            elseif progress < 0.62 then
                local alpha = (progress - 0.28) / 0.34
                right = CFrame.Angles(math.rad(-80), math.rad(-20), math.rad(55 * direction)):Lerp(CFrame.Angles(math.rad(55), math.rad(20), math.rad(-70 * direction)), alpha)
                waist = CFrame.Angles(0, math.rad((35 - 85 * alpha) * direction), math.rad(-12 * math.sin(alpha * math.pi)))
            else
                local alpha = (progress - 0.62) / 0.38
                right = CFrame.Angles(math.rad(55), math.rad(20), math.rad(-70 * direction)):Lerp(CFrame.new(), alpha)
                waist = CFrame.Angles(0, math.rad(-50 * (1 - alpha) * direction), 0)
            end
        elseif state.action == "cleave" then
            local swing = math.sin(progress * math.pi)
            local spin = progress < 0.82 and (-55 + 190 * progress / 0.82) or (135 * (1 - (progress - 0.82) / 0.18))
            right = CFrame.Angles(math.rad(-65 * swing), 0, math.rad(75 * swing))
            left = CFrame.Angles(math.rad(-35 * swing), 0, math.rad(-35 * swing))
            waist = CFrame.Angles(0, math.rad(spin), 0)
        elseif state.action == "gather" then
            local swing = math.sin(progress * math.pi)
            right = CFrame.Angles(math.rad(-125 * swing), 0, math.rad(28 * swing))
            left = CFrame.Angles(math.rad(-35 * swing), 0, math.rad(-18 * swing))
            waist = CFrame.Angles(math.rad(-12 * swing), math.rad(-18 * swing), 0)
        elseif state.action == "potion" then
            local lift = math.sin(progress * math.pi)
            right = CFrame.Angles(math.rad(-120 * lift), 0, math.rad(-35 * lift))
            neck = CFrame.Angles(math.rad(-15 * lift), math.rad(8 * lift), 0)
        elseif state.action == "hit" then
            local recoil = math.sin(progress * math.pi)
            right = CFrame.Angles(math.rad(35 * recoil), 0, math.rad(25 * recoil))
            left = CFrame.Angles(math.rad(35 * recoil), 0, math.rad(-25 * recoil))
            waist = CFrame.Angles(math.rad(-18 * recoil), 0, math.rad(12 * recoil))
        end
        -- Elbow and body poses remain visible even while the default idle/run
        -- tracks play, and the original joints are restored after each action.
        poseJoint(motors.right, right)
        poseJoint(motors.left, left)
        poseJoint(motors.waist, waist)
        poseJoint(motors.neck, neck)
        if elapsed >= state.duration or not character.Parent then
            resetCombatAnimation(state)
            combatAnimations[character] = nil
        end
    end
end

RunService:BindToRenderStep("BrumavaleCombatAnimation", Enum.RenderPriority.Character.Value + 1, function()
    animateCombat(os.clock())
end)

FX.OnClientEvent:Connect(function(event, payload)
    if type(event) ~= "string" or type(payload) ~= "table" then return end
    if event == "playerAttack" or event == "playerAction" then
        local actor = payload.player
        local action = payload.skill or payload.action
        if typeof(actor) == "Instance" and actor:IsA("Player") and actor.Parent == Players and type(action) == "string" then
            -- Local prediction already started this attack: avoid rewinding its pose.
            if actor ~= player or (event ~= "playerAttack" or os.clock() - lastLocalAttack > 1.1) then
                startCombatAnimation(actor, action)
            end
            actionEffect(actor, action, payload.target)
        end
    elseif event == "monsterWindup" then
		local monster = payload.monster
		local enemies = world:FindFirstChild("Enemies")
		if typeof(monster) == "Instance" and monster:IsA("Model") and enemies and monster.Parent == enemies then
			local highlight = Instance.new("Highlight")
			highlight.Name = "WindupHighlight"
			highlight.Adornee = monster
			highlight.FillColor = palette.red
			highlight.OutlineColor = palette.gold
			highlight.FillTransparency = 0.88
			highlight.OutlineTransparency = 0.25
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.Parent = clientEffects
			local life = math.clamp(tonumber(payload.windup) or 0.8, 0.3, 3)
			TweenService:Create(highlight, TweenInfo.new(life), {FillTransparency=0.55, OutlineTransparency=0.05}):Play()
			Debris:AddItem(highlight, life + 0.12)
		end
    elseif event == "monsterImpact" then
        local position = payload.position
        if typeof(position) ~= "Vector3" and typeof(payload.monster) == "Instance" and payload.monster:IsA("Model") and payload.monster.PrimaryPart then
            position = payload.monster.PrimaryPart.Position
        end
        burst(position, palette.red, payload.radius or 6)
    elseif event == "playerHit" then
        local victim = payload.player
        if typeof(victim) ~= "Instance" or not victim:IsA("Player") or victim.Parent ~= Players then return end
        startCombatAnimation(victim, "hit")
        local character = victim.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then burst(root.Position, palette.red, 3.5) end
        if victim == player then
            cameraShake = math.min(1.2, cameraShake + math.clamp((tonumber(payload.damage) or 8) / 22, 0.25, 0.8))
            damageFlash.BackgroundTransparency = 0.78
            TweenService:Create(damageFlash, TweenInfo.new(0.45), {BackgroundTransparency=1}):Play()
        end
    end
end)

-- HUD discreto, com áreas livres para o joystick e salto do Roblox.
local identity = frame(gui, {Position = UDim2.fromOffset(16, 10), Size = UDim2.fromOffset(252, 102), BackgroundColor3 = palette.ink, BackgroundTransparency = 0.08})
stroke(identity)
local brandLabel = label(identity, "BRUMAVALE", {Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -72, 0, 21), TextSize = 18, Font = Enum.Font.GothamBold, TextColor3 = palette.gold})
local levelLabel = label(identity, "NV 1", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(52, 20), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = palette.teal, Font = Enum.Font.GothamBold})
local regionLabel = label(identity, "Preparando aventura…", {Position = UDim2.fromOffset(14, 32), Size = UDim2.new(1, -28, 0, 18), TextSize = 11, TextColor3 = palette.muted})
local hpBack = frame(identity, {Position = UDim2.fromOffset(14, 58), Size = UDim2.new(1, -28, 0, 16), BackgroundColor3 = palette.raised})
local hpFill = frame(hpBack, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = palette.red})
local hpLabel = label(hpBack, "100 / 100", {Size = UDim2.fromScale(1, 1), TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, ZIndex = 3})
local xpBack = frame(identity, {Position = UDim2.fromOffset(14, 83), Size = UDim2.new(1, -28, 0, 5), BackgroundColor3 = palette.raised})
local xpFill = frame(xpBack, {Size = UDim2.fromScale(0, 1), BackgroundColor3 = palette.teal})

local wallet = frame(gui, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 10), Size = UDim2.fromOffset(186, 78), BackgroundColor3 = palette.ink, BackgroundTransparency = 0.08})
stroke(wallet)
local silverLabel = label(wallet, "○  0 PRATA", {Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 23), TextColor3 = palette.gold, Font = Enum.Font.GothamBold, TextSize = 16})
local weightLabel = label(wallet, "Mochila 0 / 100", {Position = UDim2.fromOffset(14, 36), Size = UDim2.new(1, -28, 0, 17), TextSize = 11, TextColor3 = palette.muted})
local persistenceLabel = label(wallet, "Carregando…", {Position = UDim2.fromOffset(14, 55), Size = UDim2.new(1, -28, 0, 14), TextSize = 9, TextColor3 = palette.muted})

local questCard = frame(gui, {Position = UDim2.fromOffset(16, 122), Size = UDim2.fromOffset(252, 116), BackgroundColor3 = palette.ink, BackgroundTransparency = 0.15})
stroke(questCard)
label(questCard, "JORNADA DO AVENTUREIRO", {Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 16), TextSize = 9, TextColor3 = palette.gold, Font = Enum.Font.GothamBold})
local questTitle = label(questCard, "Bem-vindo a Brumavale", {Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 20), TextSize = 12, Font = Enum.Font.GothamBold})
local questProgress = label(questCard, "Explore a praça para começar.", {Position = UDim2.fromOffset(12, 51), Size = UDim2.new(1, -24, 0, 28), TextSize = 11, TextColor3 = palette.muted, TextWrapped = true})
local claimButton = button(questCard, "Ver jornada", {Position = UDim2.fromOffset(12, 84), Size = UDim2.new(1, -24, 0, 23), TextSize = 10}, function()
    if snapshot and snapshot.quest and snapshot.quest.complete then send("claim") else openPanel("help") end
end)

local toastFrame = frame(gui, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 114), Size = UDim2.fromOffset(430, 48), BackgroundColor3 = palette.ink, Visible = false, ZIndex = 30})
stroke(toastFrame, palette.gold)
local toastText = label(toastFrame, "", {Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 1, -12), TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31})
local toastSequence = 0
toast = function(message)
    if type(message) ~= "string" or message == "" then return end
    toastSequence = toastSequence + 1
    local sequence = toastSequence
    toastText.Text = message
    toastFrame.Visible = true
    task.delay(4, function() if toastSequence == sequence then toastFrame.Visible = false end end)
end

local targetFrame = frame(gui, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(230, 56), BackgroundColor3 = palette.ink, Visible = false})
local targetName = label(targetFrame, "", {Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 20), TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center})
local targetHealth = label(targetFrame, "", {Position = UDim2.fromOffset(12, 29), Size = UDim2.new(1, -24, 0, 18), TextSize = 11, TextColor3 = palette.red, TextXAlignment = Enum.TextXAlignment.Center})
local targetHighlight = create("Highlight", world, {Name = "LocalTargetHighlight", Enabled = false, FillColor = palette.red, FillTransparency = 0.85, OutlineColor = palette.gold, OutlineTransparency = 0.15, DepthMode = Enum.HighlightDepthMode.Occluded})

local function validEnemy(model)
    local enemies = world:FindFirstChild("Enemies")
    return typeof(model) == "Instance" and model:IsA("Model") and enemies and model.Parent == enemies and model.PrimaryPart and model:GetAttribute("Alive") ~= false and (model:GetAttribute("Health") or 0) > 0
end
local function nearestEnemy(range)
    local root = characterParts()
    local enemies = world:FindFirstChild("Enemies")
    if not root or not enemies then return nil end
    local nearest, distance = nil, range or 18
    for _, enemy in ipairs(enemies:GetChildren()) do
        if validEnemy(enemy) then
            local current = (root.Position - enemy.PrimaryPart.Position).Magnitude
            if current <= distance then nearest, distance = enemy, current end
        end
    end
    return nearest
end
local function setTarget(enemy)
    selectedEnemy = enemy
    targetHighlight.Adornee = enemy
    targetHighlight.Enabled = enemy ~= nil
end
local function attack(skill)
    if UserInputService:GetFocusedTextBox() then return end
    if os.clock() < cooldowns[skill] then return end
    local root, humanoid = characterParts()
    if not root or not humanoid or humanoid.Health <= 0 then return end
    if not validEnemy(selectedEnemy) then setTarget(nearestEnemy(skill == "cleave" and 18 or 15)) end
    if not selectedEnemy then toast("Aproxime-se de um inimigo e toque em Atacar.") return end
    if (root.Position - selectedEnemy.PrimaryPart.Position).Magnitude > (skill == "cleave" and 18 or 15) then
        toast("Aproxime-se do alvo para atacar.") return
    end
    cooldowns[skill] = os.clock() + (skill == "cleave" and 5 or 0.65)
    lastLocalAttack = os.clock()
    startCombatAnimation(player, skill)
    send("attack", {target = selectedEnemy, skill = skill})
end
local function usePotion()
    if os.clock() < cooldowns.potion then return end
    cooldowns.potion = os.clock() + 2
    send("use", {item = "potion"})
end

local hotbar = frame(gui, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(382, 66), BackgroundColor3 = palette.ink, BackgroundTransparency = 0.05})
stroke(hotbar)
local basicButton = button(hotbar, "ATACAR\nClique", {Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(88, 52), TextSize = 11, TextColor3 = palette.gold}, function() attack("basic") end)
local cleaveButton = button(hotbar, "Q  •  CORTE\nEm área", {Position = UDim2.fromOffset(100, 7), Size = UDim2.fromOffset(88, 52), TextSize = 11}, function() attack("cleave") end)
local potionButton = button(hotbar, "R  •  POÇÃO\nCurar", {Position = UDim2.fromOffset(193, 7), Size = UDim2.fromOffset(88, 52), TextSize = 11, TextColor3 = palette.teal}, usePotion)
button(hotbar, "I  •  BOLSA\nEquipar", {Position = UDim2.fromOffset(286, 7), Size = UDim2.fromOffset(88, 52), TextSize = 11}, function() openPanel("inventory") end)
local hotbarScale = create("UIScale", hotbar, {Scale = 1})

local navigation = frame(gui, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 96), Size = UDim2.fromOffset(186, 34), BackgroundTransparency = 1})
button(navigation, "Mapa", {Size = UDim2.fromOffset(58, 32), TextSize = 11}, function() openPanel("world") end)
local cameraButton = button(navigation, "Câmera", {Position = UDim2.fromOffset(64, 0), Size = UDim2.fromOffset(58, 32), TextSize = 10})
button(navigation, "Ajuda", {Position = UDim2.fromOffset(128, 0), Size = UDim2.fromOffset(58, 32), TextSize = 11}, function() openPanel("help") end)

-- Painéis partilham a mesma seleção e nunca alteram o inventário localmente.
local panel = frame(gui, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(820, 500), BackgroundColor3 = palette.ink, Visible = false, ZIndex = 10})
stroke(panel, palette.gold)
label(panel, "BRUMAVALE  /  AVENTUREIRO", {Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -72, 0, 20), TextSize = 11, TextColor3 = palette.gold, Font = Enum.Font.GothamBold, ZIndex = 11})
button(panel, "×", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 7), Size = UDim2.fromOffset(30, 28), TextSize = 22, ZIndex = 11}, function()
    panelOpen = false panel.Visible = false
end)
local tabStrip = create("ScrollingFrame", panel, {Position = UDim2.fromOffset(12, 39), Size = UDim2.new(1, -24, 0, 40), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.fromOffset(642, 0), ZIndex = 11})
local tabDefinitions = {{"inventory", "Inventário"}, {"craft", "Fabricação"}, {"shop", "Mercador"}, {"market", "Mercado"}, {"world", "Regiões"}, {"help", "Jornada"}}
local tabButtons = {}
for index, definition in ipairs(tabDefinitions) do
    local tabId = definition[1]
    tabButtons[tabId] = button(tabStrip, definition[2], {Position = UDim2.fromOffset((index - 1) * 107, 0), Size = UDim2.fromOffset(102, 33), TextSize = 11, ZIndex = 12}, function() openPanel(tabId) end)
end
local pageTitle = label(panel, "", {Position = UDim2.fromOffset(18, 85), Size = UDim2.new(1, -36, 0, 20), Font = Enum.Font.GothamBold, TextSize = 15, ZIndex = 11})
local pageHint = label(panel, "", {Position = UDim2.fromOffset(18, 108), Size = UDim2.new(1, -36, 0, 36), TextSize = 11, TextWrapped = true, TextColor3 = palette.muted, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 11})
local body = create("ScrollingFrame", panel, {Position = UDim2.fromOffset(14, 148), Size = UDim2.new(1, -28, 1, -284), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = palette.edge, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 11})
create("UIListLayout", body, {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder})
create("UIPadding", body, {PaddingRight = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7)})
local footer = frame(panel, {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -12), Size = UDim2.new(1, -28, 0, 116), BackgroundColor3 = palette.panel, ZIndex = 11})
local footerTitle = label(footer, "Selecione um item", {Position = UDim2.fromOffset(12, 7), Size = UDim2.new(1, -24, 0, 22), TextSize = 12, Font = Enum.Font.GothamBold, ZIndex = 12})
local footerHint = label(footer, "", {Position = UDim2.fromOffset(12, 29), Size = UDim2.new(1, -24, 0, 21), TextSize = 10, TextColor3 = palette.muted, TextWrapped = true, ZIndex = 12})
local footerActions = frame(footer, {Position = UDim2.fromOffset(12, 56), Size = UDim2.new(1, -24, 0, 48), BackgroundTransparency = 1, ZIndex = 12})
local quantityHolder = frame(footerActions, {Size = UDim2.fromOffset(54, 44), BackgroundColor3 = palette.ink, ZIndex = 12})
label(quantityHolder, "QTD", {Size = UDim2.new(1, 0, 0, 15), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 8, TextColor3 = palette.muted, ZIndex = 13})
quantityText = create("TextBox", quantityHolder, {Position = UDim2.fromOffset(2, 15), Size = UDim2.new(1, -4, 0, 27), BackgroundTransparency = 1, Text = "1", ClearTextOnFocus = false, TextColor3 = palette.text, Font = Enum.Font.GothamBold, TextSize = 14, ZIndex = 13})
local priceHolder = frame(footerActions, {Position = UDim2.fromOffset(62, 0), Size = UDim2.fromOffset(74, 44), BackgroundColor3 = palette.ink, ZIndex = 12, Visible = false})
label(priceHolder, "PRATA / UN.", {Size = UDim2.new(1, 0, 0, 15), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 8, TextColor3 = palette.muted, ZIndex = 13})
priceText = create("TextBox", priceHolder, {Position = UDim2.fromOffset(2, 15), Size = UDim2.new(1, -4, 0, 27), BackgroundTransparency = 1, Text = "10", ClearTextOnFocus = false, TextColor3 = palette.gold, Font = Enum.Font.GothamBold, TextSize = 14, ZIndex = 13})
local actionContainer = frame(footerActions, {Position = UDim2.fromOffset(62, 0), Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, ZIndex = 12})
create("UIListLayout", actionContainer, {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})

local kindNames = {resource = "Recurso", weapon = "Arma", armor = "Armadura", consumable = "Consumível"}
local itemSymbols = {wood = "TR", stone = "PD", fiber = "FB", ore = "FE", hide = "CR", crystal = "CR", plank = "TB", ingot = "LG", cloth = "TC", sword1 = "I", sword2 = "II", sword3 = "III", armor1 = "I", armor2 = "II", potion = "+"}
local function clearList(container)
    for _, object in ipairs(container:GetChildren()) do
        if object:IsA("GuiObject") then object:Destroy() end
    end
end
local function row(order, title, description, symbol, accent, actionText, callback, chosen, height)
    local card = frame(body, {Size = UDim2.new(1, 0, 0, height or 65), BackgroundColor3 = chosen and palette.raised or palette.panel, LayoutOrder = order, ZIndex = 12})
    if chosen then stroke(card, palette.gold) end
    local icon = frame(card, {Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(40, 42), BackgroundColor3 = palette.ink, ZIndex = 13})
    label(icon, symbol or "·", {Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 16, Font = Enum.Font.GothamBold, TextColor3 = accent or palette.gold, ZIndex = 14})
    local rightSpace = actionText and 92 or 12
    label(card, title, {Position = UDim2.fromOffset(58, 9), Size = UDim2.new(1, -58 - rightSpace, 0, 22), TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Font = Enum.Font.GothamBold, ZIndex = 13})
    label(card, description, {Position = UDim2.fromOffset(58, 32), Size = UDim2.new(1, -58 - rightSpace, 1, -37), TextSize = 10, TextWrapped = true, TextColor3 = palette.muted, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 13})
    if actionText then
        button(card, actionText, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(76, 34), TextSize = 10, TextColor3 = accent or palette.teal, ZIndex = 14}, callback)
    end
    return card
end
local function footerAction(text, callback, color, count)
    return button(actionContainer, text, {Size = UDim2.new(1 / (count or 1), -(5 * ((count or 1) - 1) / (count or 1)), 1, -4), TextSize = 10, TextColor3 = color or palette.text, TextWrapped = true, ZIndex = 13}, callback)
end
local function sortedItems(filter)
    local ids = {}
    for id, item in pairs(Config.Items) do if not filter or filter(id, item) then table.insert(ids, id) end end
    table.sort(ids, function(a, b)
        local left, right = Config.Items[a], Config.Items[b]
        if left.tier ~= right.tier then return (left.tier or 1) < (right.tier or 1) end
        return left.name < right.name
    end)
    return ids
end
local function resetFooter()
    clearList(actionContainer)
    quantityHolder.Visible = true
    priceHolder.Visible = false
    actionContainer.Position = UDim2.fromOffset(62, 0)
    actionContainer.Size = UDim2.new(1, -62, 1, 0)
    footerTitle.Text = ""
    footerHint.Text = ""
    footer.Visible = true
    body.Size = UDim2.new(1, -28, 1, -284)
end
local function expandBody()
    footer.Visible = false
    body.Size = UDim2.new(1, -28, 1, -164)
end
local function itemDetails(id)
    local item = Config.Items[id]
    if not item then return "" end
    local details = "T" .. tostring(item.tier or 1) .. "  •  " .. (kindNames[item.kind] or "Item")
    if item.damage then details = details .. "  •  " .. item.damage .. " dano" end
    if item.defense then details = details .. "  •  " .. item.defense .. " defesa" end
    if item.heal then details = details .. "  •  +" .. item.heal .. " vida" end
    return details
end
-- Albion-inspired inventory composition: equipment left, item grid right.
-- Drag-and-drop equips on the server; local rearrangement is cosmetic only.
local inventoryPositions = {}
local dragState = nil
local function inventoryColor(id)
    local item = Config.Items[id]
    if not item then return palette.muted end
    if item.tier >= 3 then return Color3.fromRGB(157, 115, 222) end
    if item.tier == 2 then return Color3.fromRGB(92, 157, 204) end
    return palette.gold
end
local function within(point, guiObject)
    if not guiObject or not guiObject.Parent then return false end
    local origin, size = guiObject.AbsolutePosition, guiObject.AbsoluteSize
    return point.X >= origin.X and point.Y >= origin.Y and point.X <= origin.X + size.X and point.Y <= origin.Y + size.Y
end
local equipTargets = {}
local function showInventory()
    pageTitle.Text = "Equipamento e inventário"
    pageHint.Text = "Arraste armas ou armaduras para equipar. Arraste itens entre espaços para organizar a mochila."
    expandBody()
    body.ScrollingEnabled = false
    body.CanvasSize = UDim2.new()
    local contents = frame(body, {Size=UDim2.new(1, -6, 0, 322), BackgroundColor3=palette.panel, LayoutOrder=1, ZIndex=12})
    local equipment = frame(contents, {Position=UDim2.fromOffset(9, 9), Size=UDim2.fromOffset(220, 303), BackgroundColor3=palette.ink, ZIndex=13})
    label(equipment, "EQUIPAMENTO", {Position=UDim2.fromOffset(12, 8), Size=UDim2.fromOffset(192, 20), TextSize=12, Font=Enum.Font.GothamBold, TextColor3=palette.gold, ZIndex=14})
    label(equipment, "AVENTUREIRO", {Position=UDim2.fromOffset(12, 31), Size=UDim2.fromOffset(192, 15), TextSize=10, TextColor3=palette.muted, ZIndex=14})
    local itemCount = snapshot.inventory or {}
    equipTargets = {}
    local function makeSlot(parent, id, title, itemId, position, size)
        local tile = button(parent, "", {Position=position, Size=size, BackgroundColor3=palette.raised, Text="", ZIndex=15}, function()
            if id and id ~= "" then selectedItem=id end
        end)
        stroke(tile, itemId and inventoryColor(itemId) or palette.edge)
        label(tile, title, {Position=UDim2.fromOffset(6, 5), Size=UDim2.new(1,-12,0,15), TextSize=9, TextColor3=palette.muted, ZIndex=16})
        if itemId then
            label(tile, itemSymbols[itemId] or "◇", {Position=UDim2.fromOffset(6, 19), Size=UDim2.fromOffset(35,32), TextSize=21, Font=Enum.Font.GothamBold, TextColor3=inventoryColor(itemId), ZIndex=16})
            label(tile, itemName(itemId), {Position=UDim2.fromOffset(45,20), Size=UDim2.new(1,-49,0,31), TextSize=10, TextWrapped=true, ZIndex=16})
        end
        return tile
    end
    local eq = snapshot.equipment or {}
    equipTargets.weapon = makeSlot(equipment, eq.weapon, "ARMA", eq.weapon, UDim2.fromOffset(12, 59), UDim2.fromOffset(196, 62))
    equipTargets.armor = makeSlot(equipment, eq.armor, "ARMADURA", eq.armor, UDim2.fromOffset(12, 128), UDim2.fromOffset(196, 62))
    label(equipment, "DANO  " .. tostring(snapshot.damage or 0) .. "   |   DEFESA  " .. tostring(snapshot.defense or 0), {Position=UDim2.fromOffset(12,209), Size=UDim2.fromOffset(195,25), TextSize=10, TextColor3=palette.teal, ZIndex=14})
    label(equipment, "Arraste o item da mochila\npara o espaço correspondente.", {Position=UDim2.fromOffset(12,240), Size=UDim2.fromOffset(195,43), TextSize=10, TextWrapped=true, TextColor3=palette.muted, ZIndex=14})
    local bag = frame(contents, {Position=UDim2.fromOffset(240,9), Size=UDim2.new(1,-249,1,-18), BackgroundColor3=palette.ink, ZIndex=13})
    label(bag, "MOCHILA", {Position=UDim2.fromOffset(10,6), Size=UDim2.new(1,-20,0,21), TextSize=12, Font=Enum.Font.GothamBold, TextColor3=palette.gold, ZIndex=14})
    label(bag, "Peso " .. tostring(math.floor((snapshot.weight or 0)*10)/10) .. " / " .. tostring(Config.Capacity), {AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-10,0,8), Size=UDim2.fromOffset(125,17), TextSize=10, TextXAlignment=Enum.TextXAlignment.Right, TextColor3=palette.muted, ZIndex=14})
    local columns, cell, gap = 8, 51, 5
    local grid = frame(bag, {Position=UDim2.fromOffset(10,34), Size=UDim2.new(1,-20,1,-43), BackgroundTransparency=1, ZIndex=14})
    local ids = sortedItems(function(id) return (itemCount[id] or 0)>0 end)
    local order = {}
    for _, id in ipairs(ids) do
        local pos = inventoryPositions[id]
        if pos and pos >= 1 and pos <= 40 and not order[pos] then order[pos]=id end
    end
    for _, id in ipairs(ids) do
        local found=false
        for _, occupied in pairs(order) do if occupied==id then found=true break end end
        if not found then for i=1,40 do if not order[i] then order[i]=id break end end end
    end
    local slotObjects = {}
    for i=1,40 do
        local id=order[i]
        local col,rowIndex=(i-1)%columns, math.floor((i-1)/columns)
        local tile=button(grid,"",{Position=UDim2.fromOffset(col*(cell+gap),rowIndex*(cell+gap)),Size=UDim2.fromOffset(cell,cell),BackgroundColor3=palette.raised,Text="",ZIndex=15},function()
            if id then selectedItem=id end
        end)
        slotObjects[i]=tile
        if id then
            stroke(tile,inventoryColor(id))
            label(tile,itemSymbols[id] or "◆",{Position=UDim2.fromOffset(1,2),Size=UDim2.fromOffset(cell-2,27),TextSize=20,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,TextColor3=inventoryColor(id),ZIndex=16})
            label(tile,tostring(itemCount[id]),{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-4,1,-3),Size=UDim2.fromOffset(28,15),TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamBold,ZIndex=16})
            tile.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                    dragState={item=id,slot=i,origin=input.Position,targets=equipTargets,slots=slotObjects}
                end
            end)
        end
    end
    -- One-shot global pointer release avoids repeated connections every refresh.
    local connection
    connection=UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
        if connection then connection:Disconnect() end
        local dragging=dragState
        dragState=nil
        if not dragging or not panelOpen or activeTab~="inventory" then return end
        local point=Vector2.new(input.Position.X,input.Position.Y)
        local kind=Config.Items[dragging.item] and Config.Items[dragging.item].kind
        if kind=="weapon" and within(point,equipTargets.weapon) or kind=="armor" and within(point,equipTargets.armor) then
            send("equip",{item=dragging.item})
            return
        end
        for index,slot in ipairs(slotObjects) do
            if within(point,slot) and index~=dragging.slot then
                local occupant=order[index]
                if occupant then inventoryPositions[occupant]=dragging.slot end
                inventoryPositions[dragging.item]=index
                renderPage()
                return
            end
        end
        if within(point,dragging.slots[dragging.slot]) then
            selectedItem=dragging.item
            renderPage()
        end
    end)
    local item=Config.Items[selectedItem]
    if not item or (itemCount[selectedItem] or 0)==0 then selectedItem=ids[1] or "sword1";item=Config.Items[selectedItem] end
    label(contents,"Selecionado: "..(item and item.name or "nenhum").."   •   "..(item and itemDetails(selectedItem) or ""),{Position=UDim2.fromOffset(250,274),Size=UDim2.new(1,-260,0,28),TextSize=10,TextColor3=palette.teal,ZIndex=15})
end
local function showCraft()
    pageTitle.Text = "Forja & oficina"
    pageHint.Text = "Colete matérias-primas, refine e fabrique. Para concluir, aproxime-se da oficina da cidade."
    local recipes = {}
    for id in pairs(Config.Recipes) do table.insert(recipes, id) end
    table.sort(recipes, function(a, b) return (Config.Recipes[a].level or 1) == (Config.Recipes[b].level or 1) and itemName(a) < itemName(b) or (Config.Recipes[a].level or 1) < (Config.Recipes[b].level or 1) end)
    for index, id in ipairs(recipes) do
        local recipe = Config.Recipes[id]
        local ingredients = {}
        for ingredient, count in pairs(recipe.ingredients) do table.insert(ingredients, itemName(ingredient) .. " " .. tostring((snapshot.inventory or {})[ingredient] or 0) .. "/" .. count) end
        table.sort(ingredients)
        row(index, itemName(id) .. " ×" .. (recipe.amount or 1) .. "  •  Nv " .. (recipe.level or 1), table.concat(ingredients, " · "), itemSymbols[id], palette.teal, "Receita", function() selectedRecipe = id renderPage() end, selectedRecipe == id, 76)
    end
    local recipe = Config.Recipes[selectedRecipe]
    footerTitle.Text = itemName(selectedRecipe)
    footerHint.Text = recipe and ("Taxa por fabricação: " .. tostring(recipe.fee or 0) .. " prata  •  Nível " .. tostring(recipe.level or 1) .. " necessário") or "Selecione uma receita."
    footerAction("Fabricar", function() send("craft", {recipe = selectedRecipe, count = quantity()}) end, palette.teal)
end
local function showShop()
    pageTitle.Text = "Mercador de Brumavale"
    pageHint.Text = "O mercador compra e vende por preços fixos. Fique próximo à banca para negociar."
    for index, id in ipairs(sortedItems(function(_, item) return type(item.buy) == "number" and item.buy > 0 end)) do
        local item = Config.Items[id]
        row(index, item.name, itemDetails(id) .. "  •  " .. item.buy .. " prata/un.", itemSymbols[id], palette.gold, "Selecionar", function() selectedItem = id renderPage() end, selectedItem == id)
    end
    local item = Config.Items[selectedItem]
    footerTitle.Text = itemName(selectedItem)
    footerHint.Text = item and ("Compra: " .. tostring(item.buy or "—") .. " prata/un.  •  Venda: " .. tostring(item.sell or "—") .. " prata/un.") or ""
    footerAction("Comprar", function() send("buy", {item = selectedItem, count = quantity()}) end, palette.teal, 2)
    footerAction("Vender", function() send("sell", {item = selectedItem, count = quantity()}) end, palette.gold, 2)
end
local function showMarket()
    pageTitle.Text = "Mercado dos viajantes"
    pageHint.Text = "Ofertas deste servidor. Itens ficam reservados; anúncios retornam ao sair. Taxa de venda: " .. tostring(math.floor((Config.MarketTax or 0.05) * 100)) .. "%."
    local listings = snapshot.market and snapshot.market.listings or {}
    for index, listing in ipairs(listings) do
        local own = listing.sellerId == player.UserId
        row(index, itemName(listing.item) .. " ×" .. listing.count, tostring(listing.price) .. "/un.  •  Total " .. shortNumber(listing.price * listing.count) .. " prata\n" .. tostring(listing.sellerName or "Viajante"), itemSymbols[listing.item], own and palette.gold or palette.teal, own and "Cancelar" or "Comprar", function()
            send(own and "cancelListing" or "buyListing", {id = listing.id})
        end, false, 80)
    end
    if #listings == 0 then row(1, "A primeira oferta pode ser sua", "Escolha um item na mochila, defina quantidade e preço e anuncie junto ao mercado.", "○", palette.gold, nil, nil, false, 90) end
    footerTitle.Text = "Anunciar: " .. itemName(selectedItem)
    footerHint.Text = "Escolha o item na aba Inventário. Preço por unidade; fique junto ao mercado."
    priceHolder.Visible = true
    actionContainer.Position = UDim2.fromOffset(144, 0)
    actionContainer.Size = UDim2.new(1, -144, 1, 0)
    footerAction("Anunciar", function()
        local price = math.clamp(math.floor(tonumber(priceText.Text) or 1), 1, 100000)
        send("list", {item = selectedItem, count = quantity(), price = price})
    end, palette.gold)
end
local function showWorld()
    pageTitle.Text = "Atlas de Brumavale"
    pageHint.Text = "A cidade liga quatro regiões. Aproxime-se de um portal correspondente para viajar ou percorra as pontes."
    expandBody()
    for index, region in ipairs(Config.Regions) do
        local current = snapshot.region == region.id
        local color = region.color and Color3.fromRGB(region.color[1], region.color[2], region.color[3]) or palette.teal
        row(index, region.name .. (current and "  •  você está aqui" or ""), (region.safe and "Cidade segura · comércio e fabricação" or "Exploração PvE · nível sugerido " .. tostring(region.level or 1)) .. "\nUse E no portal; viajar requer estar próximo dele.", region.safe and "⌂" or "◇", color, "Viajar", function() send("travel", {region = region.id}) end, current, 90)
    end
end
local function showHelp()
    pageTitle.Text = "Sua jornada"
    pageHint.Text = "Um mundo de recursos, equipamentos e expedições. Comece coletando, melhore sua espada e enfrente as ruínas."
    expandBody()
    local quest = snapshot.quest
    if quest then
        row(1, quest.title or "Jornada", (quest.description or "") .. "\n" .. tostring(quest.current or 0) .. "/" .. tostring(quest.target or 1) .. " · " .. tostring(quest.rewardSilver or 0) .. " prata / " .. tostring(quest.rewardXP or 0) .. " XP. Resgate junto ao mestre na cidade.", "!", palette.gold, quest.complete and "Resgatar" or nil, function() send("claim") end, false, 112)
    end
    row(2, "01  •  Colete e refine", "E nos recursos para coletar. Leve madeira, minério e fibras à oficina para refinar e fabricar equipamentos.", "01", palette.teal, nil, nil, false, 93)
    row(3, "02  •  Equipe, lute e desvie", "I abre a mochila. Clique em um inimigo próximo para atacar; Q usa corte em área; R usa poção. Saia dos círculos, cones e linhas vermelhas antes da barra do golpe inimigo completar.", "02", palette.red, nil, nil, false, 112)
    row(4, "03  •  Construa sua economia", "Venda recursos ao mercador ou anuncie itens para jogadores deste servidor. Vendas e fabricação exigem proximidade das bancas.", "03", palette.gold, nil, nil, false, 100)
    row(5, "Controles", "WASD / joystick: mover · Espaço: saltar · E: interagir · I: inventário · C: fabricar · M: mapa · V: câmera · Esc: fechar painel.", "⌨", palette.muted, nil, nil, false, 104)
    row(6, "Sobre esta versão", "Protótipo original com combate PvE e mercado por servidor. No Studio, o progresso é temporário. Servidores publicados usam salvamento quando disponível.", "i", palette.muted, nil, nil, false, 104)
end
renderPage = function()
    if not snapshot or not panelOpen then return end
    local scroll = body.CanvasPosition
    clearList(body)
    resetFooter()
    body.ScrollingEnabled = true
    for id, tab in pairs(tabButtons) do
        tab.BackgroundColor3 = id == activeTab and palette.gold or palette.raised
        tab.TextColor3 = id == activeTab and palette.ink or palette.text
    end
    if activeTab == "inventory" then showInventory()
    elseif activeTab == "craft" then showCraft()
    elseif activeTab == "shop" then showShop()
    elseif activeTab == "market" then showMarket()
    elseif activeTab == "world" then showWorld()
    else showHelp() end
    body.CanvasPosition = scroll
end
openPanel = function(tab)
    if not snapshot then toast("Aguardando seu aventureiro…") return end
    if activeTab ~= tab then body.CanvasPosition = Vector2.zero end
    activeTab = tab
    panelOpen = true
    panel.Visible = true
    renderPage()
end

local healthConnection
local maxHealthConnection
local function updateHealth()
    local _, humanoid = characterParts()
    if not humanoid then return end
    local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
    hpFill.Size = UDim2.fromScale(ratio, 1)
    hpLabel.Text = tostring(math.ceil(humanoid.Health)) .. " / " .. tostring(math.ceil(humanoid.MaxHealth))
end
local function onCharacter(character)
    if healthConnection then healthConnection:Disconnect() end
    if maxHealthConnection then maxHealthConnection:Disconnect() end
    setTarget(nil)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end
    healthConnection = humanoid.HealthChanged:Connect(updateHealth)
    maxHealthConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
    updateHealth()
    if not isometric and workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = humanoid end
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter, player.Character) end

updateHUD = function()
    if not snapshot then return end
    local level = snapshot.level or Config.LevelForXP(snapshot.xp or 0)
    levelLabel.Text = "NV " .. tostring(level)
    local region = regionById(snapshot.region or player:GetAttribute("Region") or "town")
    regionLabel.Text = region.name .. (region.safe and "  •  ZONA SEGURA" or "  •  EXPLORAÇÃO")
    silverLabel.Text = "○  " .. shortNumber(snapshot.silver) .. " PRATA"
    weightLabel.Text = "Mochila " .. string.format("%.1f", snapshot.weight or 0) .. " / " .. tostring(snapshot.capacity or Config.Capacity)
    weightLabel.TextColor3 = (snapshot.weight or 0) >= (snapshot.capacity or Config.Capacity) * 0.9 and palette.gold or palette.muted
    persistenceLabel.Text = snapshot.persistent and "PROGRESSO PERSISTENTE" or "SESSÃO TEMPORÁRIA"
    local floorXP = Config.XPForLevel(level)
    local ceilingXP = Config.XPForLevel(level + 1)
    xpFill.Size = UDim2.fromScale(math.clamp(((snapshot.xp or 0) - floorXP) / math.max(ceilingXP - floorXP, 1), 0, 1), 1)
    local quest = snapshot.quest
    if quest then
        questTitle.Text = quest.title or "Jornada"
        questProgress.Text = tostring(quest.current or 0) .. " / " .. tostring(quest.target or 1) .. "  •  " .. (quest.description or "")
        claimButton.Text = quest.complete and "Resgatar recompensa" or "Ver jornada"
        claimButton.TextColor3 = quest.complete and palette.gold or palette.text
    else
        questTitle.Text = "Jornada concluída"
        questProgress.Text = "Explore, fabrique e negocie livremente."
        claimButton.Text = "Abrir guia"
    end
end
local function acceptState(nextSnapshot, message)
    if type(nextSnapshot) == "table" then
        snapshot = nextSnapshot
        updateHUD()
        renderPage()
    end
    if message then toast(message) end
end
State.OnClientEvent:Connect(acceptState)
player:GetAttributeChangedSignal("Region"):Connect(function()
    if snapshot then snapshot.region = player:GetAttribute("Region") updateHUD() end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
    if triggeringPlayer and triggeringPlayer ~= player then return end
    if prompt.Name ~= "StationPrompt" then return end
    local model = prompt:FindFirstAncestorWhichIsA("Model")
    if not model or not model:IsDescendantOf(world) then return end
    local station = model:GetAttribute("Station")
    if station == "quest" then openPanel("help")
    elseif station == "shop" or station == "craft" or station == "market" then openPanel(station) end
end)

local function toggleCamera()
    local camera = workspace.CurrentCamera
    if not camera then return end
    isometric = not isometric
    if isometric then
        normalCameraType, normalCameraSubject = camera.CameraType, camera.CameraSubject
        camera.CameraType = Enum.CameraType.Scriptable
        cameraButton.TextColor3 = palette.teal
    else
        camera.CameraType = normalCameraType or Enum.CameraType.Custom
        local _, humanoid = characterParts()
        camera.CameraSubject = humanoid or normalCameraSubject
        cameraButton.TextColor3 = palette.text
    end
end
cameraButton.Activated:Connect(toggleCamera)
UserInputService.InputBegan:Connect(function(input, processed)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.Escape and panelOpen then panelOpen = false panel.Visible = false return end
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not panelOpen then
        local target = mouse.Target
        local enemy = target and target:FindFirstAncestorWhichIsA("Model")
        if validEnemy(enemy) then setTarget(enemy) attack("basic") end
    elseif input.KeyCode == Enum.KeyCode.Q then attack("cleave")
    elseif input.KeyCode == Enum.KeyCode.R then usePotion()
    elseif input.KeyCode == Enum.KeyCode.V then toggleCamera()
    elseif input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.M then
        local tab = input.KeyCode == Enum.KeyCode.I and "inventory" or input.KeyCode == Enum.KeyCode.C and "craft" or "world"
        if panelOpen and activeTab == tab then panelOpen = false panel.Visible = false else openPanel(tab) end
    end
end)

local function configureLayout()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local compact = viewport.X < 600
    local short = viewport.Y < 520
    identity.Size = UDim2.fromOffset(compact and math.min(190, math.floor((viewport.X - 24) * 0.56)) or 252, 102)
    wallet.Size = UDim2.fromOffset(compact and math.min(150, math.floor((viewport.X - 24) * 0.44)) or 186, 78)
    brandLabel.TextSize = compact and 13 or 18
    silverLabel.TextSize = compact and 13 or 16
    navigation.Size = UDim2.fromOffset(186, 34)
    if compact then
        wallet.Position = UDim2.new(1, -8, 0, 10)
        identity.Position = UDim2.fromOffset(8, 10)
        navigation.Position = UDim2.new(1, -8, 0, 122)
    else
        wallet.Position = UDim2.new(1, -16, 0, 10)
        identity.Position = UDim2.fromOffset(16, 10)
        navigation.Position = UDim2.new(1, -16, 0, 96)
    end
    questCard.Visible = not compact and not short and not panelOpen
    targetFrame.Position = UDim2.new(0.5, 0, 0, compact and 164 or 14)
    targetFrame.Size = UDim2.fromOffset(compact and 200 or 230, 56)
    toastFrame.Size = UDim2.fromOffset(math.min(430, viewport.X - 24), 48)
    toastFrame.Position = UDim2.new(0.5, 0, 0, compact and 224 or 114)
    panel.Size = UDim2.fromOffset(math.min(820, viewport.X - 24), math.min(560, viewport.Y - (short and 24 or 100)))
    hotbarScale.Scale = math.min(1, (viewport.X - (UserInputService.TouchEnabled and 110 or 24)) / 382)
    hotbar.Position = UDim2.new(0.5, 0, 1, UserInputService.TouchEnabled and -95 or -18)
end
local layoutClock = 0
RunService.RenderStepped:Connect(function(dt)
    local camera = workspace.CurrentCamera
    local root = characterParts()
    if isometric and camera and root then
        local focus = root.Position + Vector3.new(0, 2, 0)
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.lookAt(focus + Vector3.new(44, 54, 44), focus)
        camera.Focus = CFrame.new(focus)
    end
    if camera and cameraShake > 0 then
        local clock = os.clock() * 34
        local offset = Vector3.new(math.noise(clock, 0, 0), math.noise(0, clock, 0), 0) * cameraShake * 0.22
        camera.CFrame = camera.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.noise(clock, clock, 0) * cameraShake * 0.012)
        cameraShake = math.max(0, cameraShake - dt * 3.8)
    end
    layoutClock = layoutClock + dt
    if layoutClock < 0.1 then return end
    layoutClock = 0
    configureLayout()
    if validEnemy(selectedEnemy) then
        targetFrame.Visible = not panelOpen
        local enemyType = Config.Enemies[selectedEnemy:GetAttribute("EnemyType")]
        targetName.Text = enemyType and enemyType.name or selectedEnemy.Name
        targetHealth.Text = math.ceil(selectedEnemy:GetAttribute("Health") or 0) .. " / " .. tostring(selectedEnemy:GetAttribute("MaxHealth") or 0) .. " VIDA"
    else
        if selectedEnemy then setTarget(nil) end
        targetFrame.Visible = false
    end
    local now = os.clock()
    basicButton.Text = cooldowns.basic > now and "ATACAR\n" .. string.format("%.1fs", cooldowns.basic - now) or "ATACAR\nClique / toque"
    cleaveButton.Text = cooldowns.cleave > now and "CORTE\n" .. string.format("%.1fs", cooldowns.cleave - now) or "Q  •  CORTE\nEm área"
    local potions = snapshot and snapshot.inventory and snapshot.inventory.potion or 0
    potionButton.Text = cooldowns.potion > now and "POÇÃO\n" .. string.format("%.1fs", cooldowns.potion - now) or "R  •  POÇÃO\n×" .. tostring(potions)
end)

-- Feedback de dano apenas visual, baseado na vida replicada pelo servidor.
local function observeEnemy(enemy)
    if not enemy:IsA("Model") then return end
    local previous = enemy:GetAttribute("Health") or 0
    enemy:GetAttributeChangedSignal("Health"):Connect(function()
        local current = enemy:GetAttribute("Health") or 0
        local damage = previous - current
        previous = current
        local root = characterParts()
        if damage <= 0 or not root or not enemy.PrimaryPart or (root.Position - enemy.PrimaryPart.Position).Magnitude > 100 then return end
        local popup = create("BillboardGui", enemy.PrimaryPart, {Size = UDim2.fromOffset(80, 40), StudsOffsetWorldSpace = Vector3.new(0, 5, 0), AlwaysOnTop = true, MaxDistance = 100})
        local number = label(popup, "−" .. tostring(math.ceil(damage)), {Size = UDim2.fromScale(1, 1), TextSize = 23, Font = Enum.Font.GothamBold, TextColor3 = palette.gold, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4})
        TweenService:Create(popup, TweenInfo.new(0.8), {StudsOffsetWorldSpace = Vector3.new(0, 8, 0)}):Play()
        TweenService:Create(number, TweenInfo.new(0.8), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
        Debris:AddItem(popup, 0.9)
    end)
end
local enemies = world:WaitForChild("Enemies")
for _, enemy in ipairs(enemies:GetChildren()) do observeEnemy(enemy) end
enemies.ChildAdded:Connect(observeEnemy)
configureLayout()
player:SetAttribute("BrumavaleClientReady", true)
task.spawn(function()
    for _ = 1, 30 do
        if snapshot then break end
        local ok, result = pcall(function() return GetState:InvokeServer() end)
        if ok and type(result) == "table" then acceptState(result) break end
        task.wait(1)
    end
    if snapshot then
        toast("Bem-vindo a Brumavale! Use E para interagir e I para abrir sua mochila.")
    else
        toast("O perfil ainda não carregou. Confira o Output do servidor.")
    end
end)
