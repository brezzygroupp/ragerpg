#!/usr/bin/env python3
"""Bundle reviewed local Luau sources into one offline Studio Command Bar installer."""
from pathlib import Path
import argparse
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "Config": "src/shared/Config.lua",
    "Economy": "src/server/Economy.lua",
    "Profiles": "src/server/Profiles.lua",
    "World": "src/server/World.lua",
    "Main": "src/server/Main.server.lua",
    "Client": "src/client/Client.client.lua",
}


def long_string(source):
    for n in range(1, 16):
        separator = "=" * n
        if f"]{separator}]" not in source:
            return f"[{separator}[\n{source}]{separator}]"
    raise ValueError("Could not delimit source safely")


PRELUDE = '''-- BRUMAVALE · instalador offline para a Command Bar do Roblox Studio
-- Cole TODO este arquivo em View/Exibir > Command Bar, fora do modo Play.
-- Código-fonte original, sem HTTP, require(assetId), plugins ou assets externos.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Execute na Command Bar do Studio, com o teste parado.")
local Sources = {}
'''

INSTALLER = '''
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
    if object:IsA("Script") then object.Disabled = true end
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
    shared:SetAttribute("Version",1)
    make("ModuleScript","Config",shared,Sources.Config)
    make("RemoteEvent","Action",shared)
    make("RemoteEvent","State",shared)
    make("RemoteFunction","GetState",shared)
    local server = make("Folder","Brumavale",ServerScriptService)
    make("ModuleScript","Economy",server,Sources.Economy)
    make("ModuleScript","Profiles",server,Sources.Profiles)
    local worldModule = make("ModuleScript","World",server,Sources.World)
    local main = make("Script","Main",server,Sources.Main)
    make("LocalScript","BrumavaleClient",StarterScripts,Sources.Client)
    local world = require(worldModule).Build()
    assert(world and world.Parent == workspace,"A geração do mapa não retornou um mundo válido.")
    world:SetAttribute("BrumavaleGenerated",true)
    assert(world:FindFirstChild("TownSpawn",true),"Spawn não gerado.")
    main.Disabled = false
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
print("BRUMAVALE instalado! Pressione Play. I: mochila · C: forja · M: mapa · Q: golpe circular · R: poção.")
print("Explore os prados, colete com E, clique em inimigos e volte à cidade para fabricar e negociar.")
print("Studio usa progresso temporário. Em uma experiência publicada, o servidor usa DataStore com proteção de sessão.")
if #previous > 0 then print("Instalação anterior preservada em ServerStorage/" .. backup.Name) end
'''


def build():
    hashes = {}
    result = [PRELUDE]
    for name, relative in SOURCES.items():
        source = (ROOT / relative).read_text(encoding="utf-8")
        hashes[relative] = hashlib.sha256(source.encode()).hexdigest()
        result.append(f"Sources.{name} = {long_string(source)}\n")
    result.append(INSTALLER)
    return "\n".join(result), json.dumps({"version": 1, "sources": hashes}, indent=2) + "\n"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Fail when the committed bundle is stale")
    args = parser.parse_args()
    bundle, manifest = build()
    outputs = {"Brumavale.commandbar.lua": bundle, "manifest.json": manifest}
    for name, content in outputs.items():
        destination = ROOT / "dist" / name
        if args.check:
            if not destination.exists() or destination.read_text(encoding="utf-8") != content:
                raise SystemExit(f"Stale output: {destination}. Run python3 tools/build.py")
        else:
            destination.parent.mkdir(exist_ok=True)
            destination.write_text(content, encoding="utf-8")
    print("Bundle verified." if args.check else f"Built dist/Brumavale.commandbar.lua ({len(bundle.encode()):,} bytes).")
