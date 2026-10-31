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
