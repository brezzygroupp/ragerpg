-- Pure, deterministic transactions. The server supplies all trusted configuration.
local Config
if script then
	Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Brumavale"):WaitForChild("Config"))
else
	Config = require("../shared/Config")
end
local Economy = {}
local MAX_VALUE = 1000000000

local function integer(value, limit)
	return type(value) == "number" and value == value and value >= 1 and value <= (limit or 99) and value % 1 == 0
end
local function bounded(value, fallback, ceiling)
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then return fallback end
	return math.min(math.floor(value), ceiling or MAX_VALUE)
end
local function validItem(item)
	return type(item) == "string" and Config.Items[item] ~= nil
end
local function copyInventory(inventory)
	local result = {}
	for id, count in pairs(inventory) do result[id] = count end
	return result
end
local function protected(profile, item)
	return profile.equipment.weapon == item or profile.equipment.armor == item
end
local function canRemove(profile, item, count)
	if not validItem(item) or not integer(count) then return false, "Quantidade ou item inválido." end
	if (profile.inventory[item] or 0) < count then return false, "Você não possui essa quantidade." end
	if protected(profile, item) and profile.inventory[item] == count then return false, "Equipe outro item antes de remover este." end
	return true
end
function Economy.NewProfile()
	return {
		version=1, silver=Config.StartingSilver, xp=0,
		inventory={sword1=1,armor1=1,potion=3},
		equipment={weapon="sword1",armor="armor1"},
		stats={gathered=0,kills=0,crafted=0}, questIndex=1,
	}
end
function Economy.Sanitize(raw)
	if type(raw) ~= "table" then return Economy.NewProfile() end
	local result = Economy.NewProfile()
	result.silver = bounded(raw.silver, Config.StartingSilver)
	result.xp = bounded(raw.xp, 0, Config.XPForLevel(50))
	result.inventory = {}
	if type(raw.inventory) == "table" then
		for id, count in pairs(raw.inventory) do
			if validItem(id) then
				local n = bounded(count, 0, 100000)
				if n > 0 then result.inventory[id] = n end
			end
		end
	end
	result.equipment = {}
	if type(raw.equipment) == "table" then
		for slot, kind in pairs({weapon="weapon",armor="armor"}) do
			local id = raw.equipment[slot]
			if validItem(id) and Config.Items[id].kind == kind and (result.inventory[id] or 0) > 0 then result.equipment[slot] = id end
		end
	end
	if type(raw.stats) == "table" then
		for id in pairs(result.stats) do result.stats[id] = bounded(raw.stats[id], 0) end
	end
	result.questIndex = math.max(1, bounded(raw.questIndex, 1, #Config.Quests + 1))
	return result
end
function Economy.Weight(profile)
	local weight = 0
	for id, count in pairs(profile.inventory) do
		local item = Config.Items[id]
		if item then weight = weight + item.weight * count end
	end
	return weight
end
function Economy.CanAdd(profile, item, count)
	if not validItem(item) or not integer(count) then return false, "Quantidade ou item inválido." end
	if Economy.Weight(profile) + Config.Items[item].weight * count > Config.Capacity then return false, "Mochila cheia. Venda ou use alguns itens." end
	return true
end
function Economy.Add(profile, item, count)
	local ok, message = Economy.CanAdd(profile, item, count)
	if not ok then return false, message end
	profile.inventory[item] = (profile.inventory[item] or 0) + count
	return true, "Item recebido."
end
function Economy.Remove(profile, item, count)
	local ok, message = canRemove(profile, item, count)
	if not ok then return false, message end
	local remaining = profile.inventory[item] - count
	profile.inventory[item] = remaining > 0 and remaining or nil
	return true, "Item removido."
end
function Economy.Buy(profile, item, count)
	local ok, message = Economy.CanAdd(profile, item, count)
	if not ok then return false, message end
	local price = Config.Items[item].buy * count
	if profile.silver < price then return false, "Prata insuficiente." end
	profile.silver = profile.silver - price
	profile.inventory[item] = (profile.inventory[item] or 0) + count
	return true, "Compra realizada."
end
function Economy.Sell(profile, item, count)
	local ok, message = canRemove(profile, item, count)
	if not ok then return false, message end
	local value = Config.Items[item].sell * count
	if profile.silver + value > MAX_VALUE then return false, "Limite de prata atingido." end
	Economy.Remove(profile, item, count)
	profile.silver = profile.silver + value
	return true, "Venda realizada."
end
function Economy.Craft(profile, recipeId, count)
	if type(recipeId) ~= "string" or not integer(count) then return false, "Receita ou quantidade inválida." end
	local recipe = Config.Recipes[recipeId]
	if not recipe then return false, "Receita desconhecida." end
	if Config.LevelForXP(profile.xp) < recipe.level then return false, "Seu nível ainda é baixo para esta receita." end
	local fee = recipe.fee * count
	if profile.silver < fee then return false, "Prata insuficiente para a fabricação." end
	local nextInventory = copyInventory(profile.inventory)
	for id, amount in pairs(recipe.ingredients) do
		local remaining = (nextInventory[id] or 0) - amount * count
		if remaining < 0 or (protected(profile,id) and remaining < 1) then return false, "Faltam materiais para fabricar." end
		nextInventory[id] = remaining > 0 and remaining or nil
	end
	nextInventory[recipeId] = (nextInventory[recipeId] or 0) + recipe.amount * count
	if Economy.Weight({inventory=nextInventory}) > Config.Capacity then return false, "Mochila cheia para o resultado." end
	profile.inventory = nextInventory
	profile.silver = profile.silver - fee
	profile.stats.crafted = math.min(MAX_VALUE, profile.stats.crafted + recipe.amount * count)
	profile.xp = math.min(Config.XPForLevel(50), profile.xp + 6 * count)
	return true, "Fabricação concluída."
end
function Economy.Equip(profile, item)
	if not validItem(item) or (profile.inventory[item] or 0) < 1 then return false, "Você não possui esse item." end
	local kind = Config.Items[item].kind
	if kind ~= "weapon" and kind ~= "armor" then return false, "Este item não pode ser equipado." end
	profile.equipment[kind] = item
	return true, Config.Items[item].name .. " equipado."
end
function Economy.Consume(profile, item)
	if not validItem(item) or Config.Items[item].kind ~= "consumable" then return false, "Consumível inválido." end
	local ok, message = Economy.Remove(profile, item, 1)
	if not ok then return false, message end
	return true, "Poção utilizada.", Config.Items[item].heal
end
function Economy.Grant(profile, loot, silver, xp)
	if type(loot) ~= "table" or type(silver) ~= "number" or type(xp) ~= "number"
		or silver ~= silver or xp ~= xp or silver < 0 or xp < 0 or silver > MAX_VALUE or xp > MAX_VALUE
		or silver % 1 ~= 0 or xp % 1 ~= 0 then return false, "Recompensa inválida." end
	local nextInventory = copyInventory(profile.inventory)
	for id, count in pairs(loot) do
		if not validItem(id) or not integer(count) then return false, "Recompensa inválida." end
		nextInventory[id] = (nextInventory[id] or 0) + count
	end
	local nextWeight = Economy.Weight({inventory=nextInventory})
	if nextWeight > Config.Capacity and nextWeight > Economy.Weight(profile) then return false, "Mochila cheia para o saque." end
	if profile.silver + silver > MAX_VALUE then return false, "Limite de prata atingido." end
	profile.inventory = nextInventory
	profile.silver = profile.silver + silver
	profile.xp = math.min(Config.XPForLevel(50), profile.xp + xp)
	return true, "Recompensa recebida."
end
function Economy.Stats(profile)
	local weapon = Config.Items[profile.equipment.weapon]
	local armor = Config.Items[profile.equipment.armor]
	local level = Config.LevelForXP(profile.xp)
	return {damage=(weapon and weapon.damage or 5) + (level - 1) * 2, defense=(armor and armor.defense or 0),maxHealth=100+(level-1)*8,level=level}
end
function Economy.Quest(profile)
	local quest = Config.Quests[profile.questIndex]
	if not quest then return {id="done",title="Viajante experiente",description="Todos os contratos foram concluídos. Explore e negocie!",current=0,target=0,rewardSilver=0,rewardXP=0,complete=false} end
	local current = math.min(quest.target, profile.stats[quest.stat] or 0)
	return {id=quest.id,title=quest.title,description=quest.description,current=current,target=quest.target,rewardSilver=quest.rewardSilver,rewardXP=quest.rewardXP,complete=current>=quest.target}
end
function Economy.ClaimQuest(profile)
	local quest = Economy.Quest(profile)
	if quest.id == "done" then return false, "Todos os contratos já foram concluídos." end
	if not quest.complete then return false, "Conclua o objetivo do contrato primeiro." end
	local ok, message = Economy.Grant(profile, {}, quest.rewardSilver, quest.rewardXP)
	if not ok then return false, message end
	profile.questIndex = profile.questIndex + 1
	return true, "Contrato concluído! Prata e experiência recebidas."
end
return Economy
