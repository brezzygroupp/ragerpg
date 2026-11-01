-- BRUMAVALE · instalador offline para a Command Bar do Roblox Studio
-- Cole TODO este arquivo em View/Exibir > Command Bar, fora do modo Play.
-- Código-fonte original, sem HTTP, require(assetId), plugins ou assets externos.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Execute na Command Bar do Studio, com o teste parado.")
local Sources = {}

Sources.Config = [=[
-- Brumavale: all balance data is shared; only the server changes player state.
local Config = {}
Config.Version = 6
Config.StartingSilver = 120
Config.Capacity = 160
Config.MarketTax = 0.05
Config.MaxListings = 5
Config.DataStoreName = "Brumavale_Profiles_v1"
Config.SaveInterval = 60
Config.ProfileLeaseSeconds = 180
Config.Items = {
	wood = {name="Madeira",kind="resource",tier=1,buy=7,sell=3,weight=1},
	stone = {name="Pedra",kind="resource",tier=1,buy=6,sell=2,weight=1},
	fiber = {name="Fibra",kind="resource",tier=1,buy=6,sell=2,weight=0.5},
	ore = {name="Minério de ferro",kind="resource",tier=2,buy=14,sell=6,weight=2},
	hide = {name="Couro",kind="resource",tier=2,buy=16,sell=7,weight=1},
	crystal = {name="Cristal de bruma",kind="resource",tier=3,buy=45,sell=20,weight=1},
	plank = {name="Tábua",kind="resource",tier=1,buy=20,sell=8,weight=1},
	ingot = {name="Lingote",kind="resource",tier=2,buy=40,sell=16,weight=2},
	cloth = {name="Tecido",kind="resource",tier=1,buy=18,sell=7,weight=0.5},
	sword1 = {name="Espada de viajante",kind="weapon",tier=1,buy=85,sell=30,weight=4,damage=14},
	sword2 = {name="Lâmina de ferro",kind="weapon",tier=2,buy=290,sell=110,weight=5,damage=24},
	sword3 = {name="Lâmina da aurora",kind="weapon",tier=3,buy=850,sell=320,weight=5,damage=38},
	armor1 = {name="Colete de viajante",kind="armor",tier=1,buy=70,sell=25,weight=5,defense=3},
	armor2 = {name="Armadura de ferro",kind="armor",tier=2,buy=350,sell=130,weight=8,defense=8},
	potion = {name="Poção de cura",kind="consumable",tier=1,buy=28,sell=10,weight=0.5,heal=55},
}
Config.ItemOrder = {"wood","stone","fiber","ore","hide","crystal","plank","ingot","cloth","sword1","sword2","sword3","armor1","armor2","potion"}
Config.Recipes = {
	plank = {ingredients={wood=3},amount=1,fee=1,level=1},
	ingot = {ingredients={ore=3,wood=1},amount=1,fee=3,level=2},
	cloth = {ingredients={fiber=3},amount=1,fee=1,level=1},
	sword1 = {ingredients={wood=4,stone=3},amount=1,fee=8,level=1},
	armor1 = {ingredients={cloth=3,hide=1},amount=1,fee=10,level=1},
	potion = {ingredients={fiber=3},amount=1,fee=5,level=1},
	sword2 = {ingredients={ingot=4,plank=2},amount=1,fee=25,level=2},
	armor2 = {ingredients={ingot=5,cloth=3,hide=3},amount=1,fee=30,level=3},
	sword3 = {ingredients={ingot=6,plank=3,crystal=6},amount=1,fee=90,level=4},
}
Config.Regions = {
	{id="town",name="Porto Bruma",center={0,0,0},size=1800,safe=true,level=1,color={74,113,104}},
	{id="meadow",name="Prados do Sol",center={0,0,2200},size=1800,safe=false,level=1,color={109,151,77}},
	{id="forest",name="Bosque Âmbar",center={2200,0,0},size=1800,safe=false,level=2,color={55,101,78}},
	{id="quarry",name="Pedreira Cinzenta",center={-2200,0,0},size=1800,safe=false,level=3,color={116,119,129}},
	{id="ruins",name="Ruínas da Aurora",center={0,0,-2200},size=1800,safe=false,level=4,color={77,82,113}},
	{id="marsh",name="Pântano Esquecido",center={-2200,0,2200},size=1800,safe=false,level=3,color={68,105,86}},
	{id="highlands",name="Planalto dos Ventos",center={2200,0,2200},size=1800,safe=false,level=3,color={119,143,102}},
	{id="frost",name="Picos de Gelo",center={2200,0,-2200},size=1800,safe=false,level=5,color={170,195,204}},
	{id="ash",name="Ermos de Cinza",center={-2200,0,-2200},size=1800,safe=false,level=5,color={95,83,79}},
	{id="canyon",name="Desfiladeiro Rubro",center={4400,0,0},size=1800,safe=false,level=5,color={161,100,77}},
	{id="grove",name="Jardim Luminoso",center={0,0,4400},size=1800,safe=false,level=4,color={82,148,127}},
	{id="citadel",name="Cidadela Perdida",center={0,0,-4400},size=1800,safe=false,level=6,color={81,74,105}},
}
Config.Enemies = {
	slime = {name="Gosma do prado",health=42,damage=6,speed=8,xp=22,silver=8,loot={fiber=2},aggro=35,respawn=18,attack={name="Salto viscoso",shape="circle",range=6,radius=6,windup=0.9,cooldown=1.9}},
	wolf = {name="Lobo âmbar",health=78,damage=11,speed=13,xp=40,silver=14,loot={hide=2},aggro=40,respawn=23,attack={name="Bote",shape="cone",range=9,angle=70,windup=0.7,cooldown=1.7}},
	bandit = {name="Saqueador",health=105,damage=14,speed=10,xp=58,silver=22,loot={ore=2},aggro=38,respawn=26,attack={name="Corte frontal",shape="line",range=12,width=5,windup=1.0,cooldown=2.2}},
	guardian = {name="Sentinela da aurora",health=240,damage=21,speed=8,xp=130,silver=60,loot={crystal=3},aggro=40,respawn=40,attack={name="Ruptura rúnica",shape="circle",range=14,radius=14,windup=1.5,cooldown=3.1}},
	bogling = {name="Rastejante do pântano",health=82,damage=12,speed=9,xp=44,silver=15,loot={fiber=2},aggro=38,respawn=22,attack={name="Maré tóxica",shape="circle",radius=7,range=7,windup=1.2,cooldown=2.5}},
	boar = {name="Javali selvagem",health=115,damage=17,speed=15,xp=63,silver=24,loot={hide=3},aggro=43,respawn=25,attack={name="Investida",shape="line",range=13,width=5,windup=0.8,cooldown=2.4}},
	wisp = {name="Espírito errante",health=70,damage=14,speed=12,xp=58,silver=22,loot={crystal=1},aggro=42,respawn=24,attack={name="Clarão",shape="circle",radius=9,range=9,windup=1.1,cooldown=2.8}},
	icewolf = {name="Lobo da geada",health=144,damage=20,speed=15,xp=83,silver=35,loot={hide=3},aggro=45,respawn=29,attack={name="Mordida congelante",shape="cone",range=10,angle=80,windup=0.8,cooldown=2.2}},
	ashgolem = {name="Golem de cinzas",health=310,damage=28,speed=7,xp=165,silver=73,loot={ore=4},aggro=40,respawn=42,attack={name="Impacto vulcânico",shape="circle",radius=15,range=15,windup=1.6,cooldown=3.4}},
	scorpion = {name="Escorpião rubro",health=155,damage=24,speed=12,xp=100,silver=40,loot={ore=2},aggro=44,respawn=30,attack={name="Ferrão",shape="cone",range=11,angle=65,windup=0.9,cooldown=2.6}},
	knight = {name="Cavaleiro exilado",health=220,damage=29,speed=11,xp=140,silver=65,loot={ingot=2},aggro=43,respawn=35,attack={name="Golpe pesado",shape="line",range=15,width=7,windup=1.2,cooldown=2.8}},
	ancient = {name="Colosso ancestral",health=650,damage=39,speed=7,xp=350,silver=180,loot={crystal=5},aggro=48,respawn=80,attack={name="Onda ancestral",shape="circle",radius=19,range=19,windup=2,cooldown=4.5}},
}
Config.Nodes = {
	tree = {name="Árvore",item="wood",amount=3,respawn=18,xp=9,color={111,79,50}},
	rock = {name="Rocha",item="stone",amount=3,respawn=20,xp=9,color={135,141,150}},
	fiber = {name="Fibras silvestres",item="fiber",amount=3,respawn=16,xp=8,color={191,185,105}},
	ore = {name="Veio de ferro",item="ore",amount=2,respawn=25,xp=15,color={156,127,107}},
	crystal = {name="Cristal de bruma",item="crystal",amount=1,respawn=35,xp=22,color={95,221,228}},
}
Config.Quests = {
	{id="first_harvest",title="Mãos à obra",description="Colete 12 unidades de recursos nos prados.",stat="gathered",target=12,rewardSilver=45,rewardXP=40},
	{id="first_hunt",title="Caminhos seguros",description="Derrote 4 inimigos nas regiões selvagens.",stat="kills",target=4,rewardSilver=80,rewardXP=70},
	{id="artisan",title="Aprendiz da forja",description="Fabrique 5 itens na forja de Porto Bruma.",stat="crafted",target=5,rewardSilver=120,rewardXP=100},
	{id="explorer",title="Guardião dos caminhos",description="Derrote 15 inimigos ao todo.",stat="kills",target=15,rewardSilver=250,rewardXP=200},
}
function Config.XPForLevel(level)
	return 75 * (level - 1) * level
end
function Config.LevelForXP(xp)
	return math.min(50, math.floor((1 + math.sqrt(1 + 4 * math.max(0,xp) / 75)) / 2))
end
return Config
]=]

Sources.CombatMath = [=[
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
]=]

Sources.Economy = [=[
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
]=]

Sources.Profiles = [=[
-- Server-only persistence. Studio deliberately uses disposable profiles.
-- A lease protects one account from concurrent servers; it is not a two-account
-- transaction protocol. The session market must not be advertised as durable.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Brumavale"):WaitForChild("Config"))
local Economy = require(script.Parent:WaitForChild("Economy"))

local Profiles = {}
local sessions = {}
local loading = {}
local shuttingDown = false
local persistent = not RunService:IsStudio()
local leaseSeconds = math.max(90, Config.ProfileLeaseSeconds or 180)
local store
local storeError

if persistent then
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName or "BrumavaleProfiles_v1")
	end)
	if ok then
		store = result
	else
		storeError = "O armazenamento de dados não está disponível. Tente entrar novamente."
		warn("[Brumavale] DataStore initialization failed; no player data will be overwritten.")
	end
end

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[key] = copy(item)
	end
	return result
end

local function validInteger(value, maximum)
	return type(value) == "number" and value == value and value > 0
		and value <= maximum and value % 1 == 0
end

local function escrowCopy(value)
	local result = {}
	if type(value) ~= "table" then
		return result
	end
	local count = 0
	for id, listing in pairs(value) do
		if type(id) == "string" and #id <= 100 and type(listing) == "table"
			and type(listing.item) == "string" and Config.Items[listing.item]
			and validInteger(listing.count, 99) then
			count = count + 1
			if count > 100 then
				break
			end
			result[id] = { item = listing.item, count = listing.count }
		end
	end
	return result
end

local function payload(profile)
	-- Whitelist persisted fields through the pure economy module. Never save
	-- Instances, player objects, client payloads or the live mutable table.
	local safe = Economy.Sanitize(copy(profile))
	safe.marketEscrow = escrowCopy(profile.marketEscrow)
	return safe
end

local function storedProfile(record)
	if record == nil then
		local fresh = Economy.NewProfile()
		fresh.marketEscrow = {}
		return fresh
	end
	if type(record) ~= "table" or record.schema ~= 1 or type(record.data) ~= "table"
		or type(record.data.inventory) ~= "table" or type(record.data.silver) ~= "number"
		or type(record.data.xp) ~= "number" then
		return nil, "Os dados salvos precisam de revisão; nenhuma alteração foi gravada."
	end
	local profile = Economy.Sanitize(copy(record.data))
	-- Unsold listings belong to one server session. Recover their reserved
	-- inventory on the next session, even when the backpack is now over capacity.
	for _, listing in pairs(escrowCopy(record.data.marketEscrow)) do
		profile.inventory[listing.item] = (profile.inventory[listing.item] or 0) + listing.count
	end
	profile.marketEscrow = {}
	return profile
end

local function active(session)
	if not session or not session.active or session.closing then
		return false
	end
	if session.persistent and os.time() >= session.expires then
		session.active = false
		return false
	end
	return true
end

function Profiles.Get(player)
	local session = sessions[player]
	if active(session) then
		return session.profile
	end
	return nil
end

function Profiles.IsPersistent(player)
	local session = sessions[player]
	return session ~= nil and session.persistent and active(session)
end

function Profiles.Load(player)
	if shuttingDown then
		return nil, "O servidor está encerrando. Entre novamente em instantes."
	end
	if sessions[player] or loading[player] then
		return Profiles.Get(player), "Este perfil já está sendo carregado."
	end
	if not persistent then
		local profile = Economy.NewProfile()
		profile.marketEscrow = {}
		sessions[player] = { profile = profile, persistent = false, active = true }
		return profile
	end
	if not store then
		return nil, storeError
	end
	loading[player] = true
	local owner = game.JobId .. ":" .. HttpService:GenerateGUID(false)
	local key = "player:" .. tostring(player.UserId)
	local result
	local failure = "Não foi possível carregar seu progresso. Tente entrar novamente."
	for attempt = 1, 3 do
		local denied
		local ok, response = pcall(function()
			return store:UpdateAsync(key, function(current)
				local now = os.time()
				if type(current) == "table" and type(current.lease) == "table"
					and current.lease.owner ~= owner and type(current.lease.expires) == "number"
					and current.lease.expires > now then
					denied = "Seu perfil ainda está aberto em outro servidor. Aguarde alguns minutos."
					return nil
				end
				local profile, message = storedProfile(current)
				if not profile then
					denied = message
					return nil
				end
				return {
					schema = 1,
					data = payload(profile),
					lease = { owner = owner, expires = now + leaseSeconds },
					updatedAt = now,
				}
			end)
		end)
		if ok and type(response) == "table" and type(response.lease) == "table"
			and response.lease.owner == owner then
			result = response
			break
		end
		if denied then
			failure = denied
			break
		end
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	loading[player] = nil
	if not result then
		warn("[Brumavale] Profile load refused for user " .. tostring(player.UserId) .. "; no fallback write.")
		return nil, failure
	end
	local profile = Economy.Sanitize(result.data)
	profile.marketEscrow = {}
	sessions[player] = {
		profile = profile, persistent = true, active = true, saving = false,
		owner = owner, key = key, expires = result.lease.expires,
	}
	if shuttingDown or player.Parent == nil then
		Profiles.Remove(player)
		return nil, "Conexão encerrada durante o carregamento."
	end
	return profile
end

function Profiles.Save(player, release)
	local session = sessions[player]
	if not session then
		return false, "Perfil não carregado."
	end
	if release then
		session.closing = true
	end
	-- Serialize writes per profile. A release waits for an in-flight autosave
	-- and then takes a fresh snapshot, including the returned market escrow.
	while session.saving do
		task.wait(0.05)
	end
	if not session.active then
		return false, "A sessão de dados foi interrompida. Entre novamente."
	end
	if not session.persistent then
		if release then
			session.active = false
		end
		return true
	end
	if os.time() >= session.expires then
		session.active = false
		return false, "A sessão de dados expirou. Entre novamente para proteger seu progresso."
	end
	session.saving = true
	local snapshot = payload(session.profile)
	local writeId = HttpService:GenerateGUID(false)
	local committed
	local failure = "Falha ao salvar o progresso. Reconecte para proteger seus dados."
	for attempt = 1, 3 do
		local denied = false
		local ok, result = pcall(function()
			return store:UpdateAsync(session.key, function(current)
				local now = os.time()
				if type(current) ~= "table" or type(current.lease) ~= "table"
					or current.lease.owner ~= session.owner
					or type(current.lease.expires) ~= "number" or current.lease.expires <= now then
					denied = true
					return nil
				end
				local nextRecord = { schema = 1, data = snapshot, updatedAt = now, writeId = writeId }
				if not release then
					nextRecord.lease = { owner = session.owner, expires = now + leaseSeconds }
				end
				return nextRecord
			end)
		end)
		if ok and not denied and type(result) == "table" and result.writeId == writeId
			and (release or (type(result.lease) == "table" and result.lease.owner == session.owner)) then
			committed = result
			break
		end
		if denied then
			failure = "Seu perfil foi aberto em outra sessão ou a sessão expirou. Reconecte."
			break
		end
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	session.saving = false
	if not committed then
		-- Never continue with mutable data after uncertain ownership/write state.
		session.active = false
		warn("[Brumavale] Profile save failed for user " .. tostring(player.UserId) .. "; session frozen.")
		return false, failure
	end
	if release then
		session.active = false
	else
		session.expires = committed.lease.expires
	end
	return true
end

function Profiles.Remove(player)
	local session = sessions[player]
	if not session then
		return true
	end
	if session.removing then
		while sessions[player] == session do
			task.wait(0.05)
		end
		return true
	end
	session.removing = true
	local ok, message = Profiles.Save(player, true)
	sessions[player] = nil
	return ok, message
end

function Profiles.Shutdown()
	shuttingDown = true
	local pending = 0
	for player in pairs(sessions) do
		pending = pending + 1
		task.spawn(function()
			Profiles.Remove(player)
			pending = pending - 1
		end)
	end
	local deadline = os.clock() + 25
	while (pending > 0 or next(loading) ~= nil) and os.clock() < deadline do
		task.wait(0.1)
	end
end

return Profiles
]=]

Sources.World = [=[
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
]=]

Sources.Main = [=[
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
		if portal:GetAttribute("Region") == id and portal:GetAttribute("OriginRegion") == (regionAt(root.Position) and regionAt(root.Position).id) and portal.PrimaryPart
			and (root.Position - portal.PrimaryPart.Position).Magnitude <= 16 then
			validPortal = true; break
		end
	end
	if not validPortal then notify(player, "Aproxime-se do portal dessa região."); return end
	if not cooldown(player, "travel", 2) then return end
	local previous = regionAt(root.Position)
    local arrivalCenter=Vector3.new(table.unpack(destination.center))
    local previousCenter=previous and Vector3.new(table.unpack(previous.center)) or Vector3.zero
    local incoming=previousCenter-arrivalCenter
    if incoming.Magnitude < 1 then return end
    local position=arrivalCenter+incoming.Unit*(destination.size*.32)+Vector3.new(0,7,0)
	player.Character:PivotTo(CFrame.new(position))
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	sessions[player].region = id
    sessions[player].lastPortalAt = os.clock()
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
                -- Never allow walking, jumping or falling into another map.
                -- Travel() is the only legitimate cross-region transfer.
                if not region or (session.region and region.id ~= session.region) then
                    local old
                    for _, defined in ipairs(Config.Regions) do
                        if defined.id == (session.region or "town") then old=defined break end
                    end
                    old=old or Config.Regions[1]
                    local safePoint = Vector3.new(table.unpack(old.center)) + Vector3.new(0,7, old.safe and -120 or 90)
                    player.Character:PivotTo(CFrame.new(safePoint))
                    root.AssemblyLinearVelocity=Vector3.zero
                    region=old
                end
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
]=]

Sources.Client = [=[
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
local inventoryDropConnection
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
        if pos and pos >= 1 and pos <= 32 and not order[pos] then order[pos]=id end
    end
    for _, id in ipairs(ids) do
        local found=false
        for _, occupied in pairs(order) do if occupied==id then found=true break end end
        if not found then for i=1,32 do if not order[i] then order[i]=id break end end end
    end
    local slotObjects = {}
    for i=1,32 do
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
    if inventoryDropConnection then inventoryDropConnection:Disconnect() end
    inventoryDropConnection=UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
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
    if inventoryDropConnection then inventoryDropConnection:Disconnect(); inventoryDropConnection=nil end
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
]=]


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local targets = {
    {parent=ReplicatedStorage,name="Brumavale"},
    {parent=ServerScriptService,name="Brumavale"},
    {parent=StarterScripts,name="BrumavaleClient"},
    {parent=workspace,name="BrumavaleWorld"},
}
-- Refuse to overwrite an unrelated object with a matching name.
for _, target in ipairs(targets) do
    local existing = target.parent:FindFirstChild(target.name)
    assert(not existing or existing:GetAttribute("BrumavaleGenerated") == true,
        "Objeto não reconhecido: " .. target.parent.Name .. "." .. target.name .. ". Renomeie-o antes de instalar.")
end
local backup = Instance.new("Folder")
backup.Name = "BrumavaleBackup_" .. os.date("%Y%m%d_%H%M%S")
backup:SetAttribute("BrumavaleGenerated",true)
backup.Parent = ServerStorage
local previous = {}
local created = {}
local function make(class, name, parent, source)
    local object = Instance.new(class)
    object.Name = name
    object:SetAttribute("BrumavaleGenerated",true)
    -- LocalScript currently inherits Script in Roblox's class hierarchy. Keep
    -- every runnable script stopped until the complete installation succeeds.
    if object:IsA("BaseScript") then object.Enabled = false end
    if source then object.Source = source end
    object.Parent = parent
    table.insert(created, object)
    return object
end
pcall(function() ChangeHistoryService:SetWaypoint("Antes de instalar Brumavale") end)
local ok, problem = xpcall(function()
    for i, target in ipairs(targets) do
        local existing = target.parent:FindFirstChild(target.name)
        if existing then
            local slot = Instance.new("Folder")
            slot.Name = tostring(i) .. "_" .. target.parent.Name
            slot.Parent = backup
            table.insert(previous,{object=existing,parent=target.parent})
            existing.Parent = slot
        end
    end
    local shared = make("Folder","Brumavale",ReplicatedStorage)
    shared:SetAttribute("Version",6)
    make("ModuleScript","Config",shared,Sources.Config)
    make("ModuleScript","CombatMath",shared,Sources.CombatMath)
    make("RemoteEvent","Action",shared)
    make("RemoteEvent","State",shared)
    make("RemoteEvent","FX",shared)
    make("RemoteFunction","GetState",shared)
    local server = make("Folder","Brumavale",ServerScriptService)
    make("ModuleScript","Economy",server,Sources.Economy)
    make("ModuleScript","Profiles",server,Sources.Profiles)
    local worldModule = make("ModuleScript","World",server,Sources.World)
    local main = make("Script","Main",server,Sources.Main)
    local client = make("LocalScript","BrumavaleClient",StarterScripts,Sources.Client)
    local world = require(worldModule).Build()
    assert(world and world.Parent == workspace,"A geração do mapa não retornou um mundo válido.")
    world:SetAttribute("BrumavaleGenerated",true)
    assert(world:FindFirstChild("TownSpawn",true),"Spawn não gerado.")
    assert(world:GetAttribute("Version") == 6, "Mundo antigo gerado: versão incorreta.")
    assert(not world:FindFirstChild("PortalPlaza",true), "PortalPlaza antiga encontrada no novo mundo.")
    local portalCount = #world:WaitForChild("Portals"):GetChildren()
    assert(portalCount >= 12, "Rede de portais incompleta: " .. portalCount)
    print("[BRUMAVALE V6] Mundo verificado | Portais: " .. portalCount .. " | Sem PortalPlaza")
    main.Enabled = true
    client.Enabled = true
    assert(main.Enabled and client.Enabled, "Os scripts de runtime não foram ativados.")
end, debug.traceback)
if not ok then
    local world = workspace:FindFirstChild("BrumavaleWorld")
    if world and world:GetAttribute("BrumavaleGenerated") then world:Destroy() end
    for i = #created, 1, -1 do created[i]:Destroy() end
    for _, record in ipairs(previous) do record.object.Parent = record.parent end
    backup:Destroy()
    error("Instalação revertida. " .. tostring(problem),0)
end
if #previous == 0 then backup:Destroy() end
pcall(function() ChangeHistoryService:SetWaypoint("Brumavale instalado") end)
print("[BRUMAVALE WORLD V6] 12 REGIOES 1800x1800 | PORTAIS NAS FRONTEIRAS | SEM PORTALPLAZA")
print("I: mochila · C: forja · M: mapa · Q: golpe circular · R: poção.")
print("Explore os prados, colete com E, clique em inimigos e volte à cidade para fabricar e negociar.")
print("Studio usa progresso temporário. Em uma experiência publicada, o servidor usa DataStore com proteção de sessão.")
if #previous > 0 then print("Instalação anterior preservada em ServerStorage/" .. backup.Name) end
