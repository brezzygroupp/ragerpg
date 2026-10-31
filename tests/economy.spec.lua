local Economy = require("../src/server/Economy")
local Config = require("../src/shared/Config")
local passed = 0
local function test(name, run)
	local ok, message = pcall(run)
	assert(ok, name .. ": " .. tostring(message))
	passed = passed + 1
	print("PASS " .. name)
end
local function fingerprint(value)
	if type(value) ~= "table" then return tostring(value) end
	local keys = {}
	for key in pairs(value) do table.insert(keys,key) end
	table.sort(keys)
	local parts = {}
	for _, key in ipairs(keys) do table.insert(parts,tostring(key).."="..fingerprint(value[key])) end
	return "{"..table.concat(parts,",").."}"
end
local function unchanged(profile, fn)
	local before = fingerprint(profile)
	assert(fn() == false,"invalid operation succeeded")
	assert(fingerprint(profile) == before,"failed operation mutated state")
end
test("starter equipment, stats and capacity",function()
	local p = Economy.NewProfile()
	assert(p.silver == 120 and Economy.Weight(p) == 10.5)
	assert(Economy.Stats(p).damage == 14 and Economy.Stats(p).maxHealth == 100)
	assert(p.inventory.sword1 == 1 and p.equipment.weapon == "sword1")
end)
test("independent profiles",function()
	local a,b=Economy.NewProfile(),Economy.NewProfile()
	a.inventory.potion=0
	assert(b.inventory.potion==3)
end)
test("buy charges exact unit price",function()
	local p=Economy.NewProfile()
	assert(Economy.Buy(p,"wood",3))
	assert(p.silver==99 and p.inventory.wood==3)
end)
test("sell credits correct amount",function()
	local p=Economy.NewProfile()
	assert(Economy.Add(p,"ore",5))
	assert(Economy.Sell(p,"ore",3))
	assert(p.inventory.ore==2 and p.silver==138)
end)
test("insufficient money is atomic",function()
	local p=Economy.NewProfile()
	unchanged(p,function() return Economy.Buy(p,"sword3",1) end)
end)
test("insufficient inventory is atomic",function()
	local p=Economy.NewProfile()
	unchanged(p,function() return Economy.Sell(p,"ore",1) end)
end)
test("full inventory purchase is atomic",function()
	local p=Economy.NewProfile(); p.inventory.wood=149
	unchanged(p,function() return Economy.Buy(p,"wood",1) end)
end)
test("negative zero fractional infinite NaN and string counts rejected",function()
	local invalid={-1,0,0.5,100,math.huge,0/0,"3",true,{}}
	for _,n in ipairs(invalid) do
		local p=Economy.NewProfile(); p.inventory.wood=30
		unchanged(p,function() return Economy.Buy(p,"wood",n) end)
		unchanged(p,function() return Economy.Sell(p,"wood",n) end)
		unchanged(p,function() return Economy.Add(p,"wood",n) end)
		unchanged(p,function() return Economy.Remove(p,"wood",n) end)
		unchanged(p,function() return Economy.Craft(p,"plank",n) end)
	end
end)
test("unknown identifiers never mutate profiles",function()
	local p=Economy.NewProfile()
	for _,id in ipairs({"nope",{},12,true}) do
		unchanged(p,function() return Economy.Buy(p,id,1) end)
		unchanged(p,function() return Economy.Craft(p,id,1) end)
		unchanged(p,function() return Economy.Equip(p,id) end)
	end
end)
test("last equipped copy cannot be sold",function()
	local p=Economy.NewProfile()
	unchanged(p,function() return Economy.Sell(p,"sword1",1) end)
	assert(Economy.Add(p,"sword1",1))
	assert(Economy.Sell(p,"sword1",1))
	assert(p.inventory.sword1==1)
end)
test("equipment swap makes old equipment sellable",function()
	local p=Economy.NewProfile()
	assert(Economy.Add(p,"sword2",1)); assert(Economy.Equip(p,"sword2"))
	assert(Economy.Sell(p,"sword1",1))
	assert(Economy.Stats(p).damage==24)
end)
test("resources cannot be equipped",function()
	local p=Economy.NewProfile(); p.inventory.wood=1
	unchanged(p,function() return Economy.Equip(p,"wood") end)
end)
test("craft atomically spends materials and fee",function()
	local p=Economy.NewProfile(); p.inventory.wood=6
	assert(Economy.Craft(p,"plank",2))
	assert(p.inventory.wood==nil and p.inventory.plank==2 and p.silver==118)
	assert(p.stats.crafted==2 and p.xp==12)
end)
test("craft checks level before material consumption",function()
	local p=Economy.NewProfile(); p.inventory.ore=3; p.inventory.wood=1
	unchanged(p,function() return Economy.Craft(p,"ingot",1) end)
end)
test("craft checks all ingredients before mutation",function()
	local p=Economy.NewProfile(); p.xp=150; p.inventory.ore=3
	unchanged(p,function() return Economy.Craft(p,"ingot",1) end)
end)
test("craft checks fee before mutation",function()
	local p=Economy.NewProfile(); p.silver=0; p.inventory.wood=3
	unchanged(p,function() return Economy.Craft(p,"plank",1) end)
end)
test("capacity checked after consuming crafting ingredients",function()
	local p=Economy.NewProfile(); p.inventory.wood=149
	assert(Economy.Craft(p,"plank",1))
	assert(Economy.Weight(p)<Config.Capacity)
end)
test("consumable returns healing and consumes one",function()
	local p=Economy.NewProfile()
	local ok,_,heal=Economy.Consume(p,"potion")
	assert(ok and heal==55 and p.inventory.potion==2)
	unchanged(p,function() return Economy.Consume(p,"sword1") end)
end)
test("multi-item loot rejects entire grant if capacity exceeded",function()
	local p=Economy.NewProfile(); p.inventory.wood=149
	unchanged(p,function() return Economy.Grant(p,{ore=2,fiber=3},12,20) end)
end)
test("loot currency and experience awarded together",function()
	local p=Economy.NewProfile()
	assert(Economy.Grant(p,{hide=2},14,40))
	assert(p.inventory.hide==2 and p.silver==134 and p.xp==40)
end)
test("recovered escrow overcapacity still permits currency-only rewards",function()
	local p=Economy.NewProfile(); p.inventory.wood=200
	assert(Economy.Grant(p,{},14,40))
	assert(p.silver==134 and p.xp==40)
	unchanged(p,function() return Economy.Grant(p,{wood=1},14,40) end)
end)
test("invalid reward cannot inject currency or items",function()
	local p=Economy.NewProfile()
	unchanged(p,function() return Economy.Grant(p,{wood=-1},10,0) end)
	unchanged(p,function() return Economy.Grant(p,{},math.huge,0) end)
	unchanged(p,function() return Economy.Grant(p,{},0,0/0) end)
end)
test("quests claim exactly once and progress cumulatively",function()
	local p=Economy.NewProfile()
	unchanged(p,function() return Economy.ClaimQuest(p) end)
	p.stats.gathered=12
	assert(Economy.Quest(p).complete)
	assert(Economy.ClaimQuest(p))
	assert(p.silver==165 and p.xp==40 and p.questIndex==2)
	unchanged(p,function() return Economy.ClaimQuest(p) end)
end)
test("quest completion has stable final state",function()
	local p=Economy.NewProfile(); p.stats={gathered=99,kills=99,crafted=99}
	for _=1,#Config.Quests do assert(Economy.ClaimQuest(p)) end
	assert(Economy.Quest(p).id=="done")
	unchanged(p,function() return Economy.ClaimQuest(p) end)
end)
test("level thresholds and level cap",function()
	for level=1,50 do
		assert(Config.LevelForXP(Config.XPForLevel(level))==level)
		if level>1 then assert(Config.LevelForXP(Config.XPForLevel(level)-1)==level-1) end
	end
	assert(Config.LevelForXP(1000000000)==50)
end)
test("stored data is sanitized without unknown fields or invalid gear",function()
	local p=Economy.Sanitize({silver=-5,xp=0/0,inventory={wood=3.9,unknown=100,ore=-9},equipment={weapon="sword3"},stats={kills=math.huge},questIndex=9999,admin=true})
	assert(p.silver==120 and p.xp==0 and p.inventory.wood==3)
	assert(p.inventory.unknown==nil and p.inventory.ore==nil and p.equipment.weapon==nil)
	assert(p.stats.kills==0 and p.questIndex==#Config.Quests+1 and p.admin==nil)
end)
test("currency overflow is atomic",function()
	local p=Economy.NewProfile(); p.silver=1000000000; p.inventory.wood=1
	unchanged(p,function() return Economy.Sell(p,"wood",1) end)
	unchanged(p,function() return Economy.Grant(p,{},1,0) end)
end)
test("balance tables contain valid references and no direct buy-sell arbitrage",function()
	for id,item in pairs(Config.Items) do
		assert(item.buy>item.sell and item.sell>=0 and item.weight>0,id)
	end
	for id,recipe in pairs(Config.Recipes) do
		assert(Config.Items[id] and recipe.amount>=1 and recipe.fee>=0,id)
		for ingredient,amount in pairs(recipe.ingredients) do assert(Config.Items[ingredient] and amount>0) end
	end
	for _,node in pairs(Config.Nodes) do assert(Config.Items[node.item]) end
	for _,enemy in pairs(Config.Enemies) do
		for id in pairs(enemy.loot) do assert(Config.Items[id]) end
	end
end)
print(string.format("%d tests passed",passed))
