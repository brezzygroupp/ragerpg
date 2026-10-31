-- Brumavale: all balance data is shared; only the server changes player state.
local Config = {}
Config.Version = 3
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
	{id="town",name="Porto Bruma",center={0,0,0},size=240,safe=true,level=1,color={74,113,104}},
	{id="meadow",name="Prados do Sol",center={0,0,270},size=240,safe=false,level=1,color={109,151,77}},
	{id="forest",name="Bosque Âmbar",center={270,0,0},size=240,safe=false,level=2,color={55,101,78}},
	{id="quarry",name="Pedreira Cinzenta",center={-270,0,0},size=240,safe=false,level=3,color={116,119,129}},
	{id="ruins",name="Ruínas da Aurora",center={0,0,-270},size=240,safe=false,level=4,color={77,82,113}},
}
Config.Enemies = {
	slime = {name="Gosma do prado",health=42,damage=6,speed=8,xp=22,silver=8,loot={fiber=2},aggro=35,respawn=18,attack={name="Salto viscoso",shape="circle",range=6,radius=6,windup=0.9,cooldown=1.9}},
	wolf = {name="Lobo âmbar",health=78,damage=11,speed=13,xp=40,silver=14,loot={hide=2},aggro=40,respawn=23,attack={name="Bote",shape="cone",range=9,angle=70,windup=0.7,cooldown=1.7}},
	bandit = {name="Saqueador",health=105,damage=14,speed=10,xp=58,silver=22,loot={ore=2},aggro=38,respawn=26,attack={name="Corte frontal",shape="line",range=12,width=5,windup=1.0,cooldown=2.2}},
	guardian = {name="Sentinela da aurora",health=240,damage=21,speed=8,xp=130,silver=60,loot={crystal=3},aggro=40,respawn=40,attack={name="Ruptura rúnica",shape="circle",range=14,radius=14,windup=1.5,cooldown=3.1}},
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
