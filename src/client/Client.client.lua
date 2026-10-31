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

local gui = Instance.new("ScreenGui")
gui.Name = "BrumavaleUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")
gui:SetAttribute("Version", Config.Version)

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
local function showInventory()
    pageTitle.Text = "Sua mochila"
    pageHint.Text = "Selecione equipamentos para vestir. Vendas exigem proximidade do mercador; anúncios, do mercado."
    local inventory = snapshot.inventory or {}
    local ids = sortedItems(function(id) return (inventory[id] or 0) > 0 end)
    if #ids == 0 then row(1, "Mochila vazia", "Colete recursos nas regiões próximas à cidade.", "·", palette.muted) end
    for index, id in ipairs(ids) do
        local equipped = snapshot.equipment and (snapshot.equipment.weapon == id or snapshot.equipment.armor == id)
        row(index, itemName(id) .. " ×" .. tostring(inventory[id]), itemDetails(id) .. (equipped and "  •  equipado" or ""), itemSymbols[id], equipped and palette.teal or palette.gold, "Selecionar", function() selectedItem = id renderPage() end, selectedItem == id)
    end
    local item = Config.Items[selectedItem]
    footerTitle.Text = item and item.name or "Selecione um item"
    footerHint.Text = item and ("Venda: " .. tostring(item.sell or 0) .. " prata/un.  •  Peso: " .. tostring(item.weight or 0) .. "  •  Dano " .. tostring(snapshot.damage or 0) .. " / Defesa " .. tostring(snapshot.defense or 0)) or ""
    footerAction(item and item.kind == "consumable" and "Usar" or "Equipar", function()
        if item and item.kind == "consumable" then send("use", {item = selectedItem}) else send("equip", {item = selectedItem}) end
    end, palette.teal, 3)
    footerAction("Vender", function() send("sell", {item = selectedItem, count = quantity()}) end, palette.gold, 3)
    footerAction("Anunciar", function() openPanel("market") end, palette.text, 3)
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
    row(3, "02  •  Equipe e lute", "I abre a mochila. Clique em um inimigo próximo para atacar; Q aplica corte em área; R usa uma poção. No celular, use os botões inferiores.", "02", palette.red, nil, nil, false, 105)
    row(4, "03  •  Construa sua economia", "Venda recursos ao mercador ou anuncie itens para jogadores deste servidor. Vendas e fabricação exigem proximidade das bancas.", "03", palette.gold, nil, nil, false, 100)
    row(5, "Controles", "WASD / joystick: mover · Espaço: saltar · E: interagir · I: inventário · C: fabricar · M: mapa · V: câmera · Esc: fechar painel.", "⌨", palette.muted, nil, nil, false, 104)
    row(6, "Sobre esta versão", "Protótipo original com combate PvE e mercado por servidor. No Studio, o progresso é temporário. Servidores publicados usam salvamento quando disponível.", "i", palette.muted, nil, nil, false, 104)
end
renderPage = function()
    if not snapshot or not panelOpen then return end
    local scroll = body.CanvasPosition
    clearList(body)
    resetFooter()
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
