-- mapvote

util.AddNetworkString("ph_mapvote")
util.AddNetworkString("ph_mapvotevotes")

CreateConVar("ph_mapvote_choices", "6", bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY),
    "Nombre de maps proposées au vote (0 = toutes)")
CreateConVar("ph_mapvote_exclude_current", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY),
    "Exclure la map courante des choix de vote")
CreateConVar("ph_mapvote_recent_size", "3", bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY),
    "Nombre de maps récemment jouées à exclure du vote (0 = aucune)")
CreateConVar("ph_mapvote_time", "30", bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY),
    "Durée du vote de map en secondes")

GM.MapVoteTime = GAMEMODE && GAMEMODE.MapVoteTime || 30
GM.MapVoteStart = GAMEMODE && GAMEMODE.MapVoteStart || CurTime()

function GM:IsMapVoting()
	return self.MapVoting
end

function GM:GetMapVoteStart()
	return self.MapVoteStart
end

function GM:GetMapVoteRunningTime()
	return CurTime() - self.MapVoteStart
end

function GM:RotateMap()
	local list = self:GetFullMapList()
	local map = game.GetMap()
	local index
	for k, map2 in pairs(list) do
		if map == map2 then
			index = k
		end
	end

	if !index then index = 1 end
	index = index + 1

	if index > #list then
		index = 1
	end

	local nextMap = list[index]
	self:ChangeMapTo(nextMap)
end

function GM:ChangeMapTo(map)
	if map == game.GetMap() then
		self.Rounds = 0
		self.SetupCount = 0
		self:SetGameState(ROUND_WAIT)
		return
	end

	-- Persiste la map courante dans l'historique récent
	self:PushRecentMap(game.GetMap())

	print("[ph_altered] Rotate changing map to " .. map)
	GlobalChatMsg("Changing map to ", map)
	hook.Call("OnChangeMap", GAMEMODE)
	timer.Simple(5, function()
		RunConsoleCommand("changelevel", map)
	end)
end

function GM:PushRecentMap(map)
	if not map or map == "" then return end
	local size = GetConVar("ph_mapvote_recent_size"):GetInt()
	if size <= 0 then return end
	local tbl = {}
	local raw = file.Read("ph_altered/recentmaps.txt", "DATA") or ""
	for line in raw:gmatch("[^\r\n]+") do tbl[#tbl + 1] = line end
	-- Retire les doublons
	for i = #tbl, 1, -1 do
		if tbl[i] == map then table.remove(tbl, i) end
	end
	table.insert(tbl, 1, map)
	-- Tronque
	while #tbl > size do table.remove(tbl) end
	if not file.Exists("ph_altered", "DATA") then file.CreateDir("ph_altered") end
	file.Write("ph_altered/recentmaps.txt", table.concat(tbl, "\r\n"))
	self.RecentMaps = tbl
end

function GM:LoadRecentMaps()
	local tbl = {}
	local raw = file.Read("ph_altered/recentmaps.txt", "DATA") or ""
	for line in raw:gmatch("[^\r\n]+") do tbl[#tbl + 1] = line end
	self.RecentMaps = tbl
end

GM.MapList = {}

local defaultMapList = {
	"cs_italy",
	"cs_office",
	"cs_compound",
	"cs_assault"
}

function GM:SaveMapList()
	-- ensure the folders are there
	if !file.Exists("ph_altered/", "DATA") then
		file.CreateDir("ph_altered")
	end

	local txt = ""
	for k, map in pairs(self.MapList) do
		txt = txt .. map .. "\r\n"
	end

	file.Write("ph_altered/maplist.txt", txt)
end

function GM:LoadMapList()
	local jason = file.ReadDataAndContent("ph_altered/maplist.txt")
	if jason then
		local tbl = {}
		for map in jason:gmatch("[^\r\n]+") do
			table.insert(tbl, map)
		end

		self.MapList = tbl
	else
		local tbl = {}

		for k, map in pairs(defaultMapList) do
			if file.Exists("maps/" .. map .. ".bsp", "GAME") then
				table.insert(tbl, map)
			end
		end

		local files = file.Find("maps/*", "GAME")
		for k, v in pairs(files) do
			local name = v:match("([^%.]+)%.bsp$")
			if name then
				if name:sub(1, 3) == "ph_" then
					table.insert(tbl, name)
				end
			end
		end

		self.MapList = tbl
		self:SaveMapList()
	end

	-- Copie "canon" pour le mapvote (self.MapList est réduit pendant le vote)
	self._FullMapList = table.Copy(self.MapList)
	self:LoadRecentMaps()

	for k, map in pairs(self.MapList) do
		local path = "maps/" .. map .. ".png"
		if file.Exists(path, "GAME") then
			resource.AddSingleFile(path)
		else
			local path = "maps/thumb/" .. map .. ".png"
			if file.Exists(path, "GAME") then
				resource.AddSingleFile(path)
			end
		end
	end
end

function GM:StartMapVote()
	-- Check if we're using the MapVote addon. If so, ignore the builtin mapvote logic.
	-- MapVote Workshop Link: https://steamcommunity.com/sharedfiles/filedetails/?id=151583504
	local initHookTbl = hook.GetTable().Initialize
	if initHookTbl && initHookTbl.MapVoteConfigSetup then
		self:SetGameState(ROUND_MAPVOTE)
		MapVote.Start()
		return
	end

	-- allow developers to override builtin mapvote (upstream)
	if hook.GetTable().PHStartMapVote then
		self:SetGameState(ROUND_MAPVOTE)
		hook.Run("PHStartMapVote")
		return
	end

	self.MapVoteStart = CurTime()
	self.MapVoteTime = GetConVar("ph_mapvote_time"):GetInt()
	self.MapVoting = true
	self.MapVotes = {}

	-- Sélection des maps candidates : exclure la map courante + maps récentes
	local currentMap = game.GetMap()
	local excludeCurrent = GetConVar("ph_mapvote_exclude_current"):GetBool()
	local recent = self.RecentMaps or {}
	local recentSet = {}
	for _, m in ipairs(recent) do recentSet[m] = true end

	local pool = {}
	for _, m in ipairs(self:GetFullMapList()) do
		if excludeCurrent and m == currentMap then continue end
		if recentSet[m] then continue end
		pool[#pool + 1] = m
	end

	-- Si le filtre vide le pool (petit serveur), fallback sur la liste complète sans map courante
	if #pool == 0 then
		for _, m in ipairs(self:GetFullMapList()) do
			if not excludeCurrent or m ~= currentMap then
				pool[#pool + 1] = m
			end
		end
	end
	if #pool == 0 then pool = table.Copy(self:GetFullMapList()) end

	-- Mélange
	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end

	-- Cap au nombre de choix voulu
	local cap = GetConVar("ph_mapvote_choices"):GetInt()
	if cap > 0 and #pool > cap then
		local reduced = {}
		for i = 1, cap do reduced[i] = pool[i] end
		pool = reduced
	end

	self.MapList = pool
	self:SetGameState(ROUND_MAPVOTE)
	self:NetworkMapVoteStart()
end

function GM:GetFullMapList()
	return self._FullMapList or self.MapList
end

function GM:MapVoteThink()
	if self.MapVoting then
		if self:GetMapVoteRunningTime() >= self.MapVoteTime then
			self.MapVoting = false
			local votes = {}
			for ply, map in pairs(self.MapVotes) do
				if IsValid(ply) && ply:IsPlayer() then
					votes[map] = (votes[map] || 0) + 1
				end
			end

			local maxvotes = 0
			for k, v in pairs(votes) do
				if v > maxvotes then
					maxvotes = v
				end
			end

			local maps = {}
			for k, v in pairs(votes) do
				if v == maxvotes then
					table.insert(maps, k)
				end
			end

			if #maps > 0 then
				self:ChangeMapTo(table.Random(maps))
			else
				-- Aucun vote : on prend un choix aléatoire parmi les maps proposées
				-- pour éviter une boucle infinie mapvote → WAIT → mapvote.
				if #self.MapList > 0 then
					local fallback = table.Random(self.MapList)
					GlobalChatMsg("Aucun vote : map suivante tirée au hasard — ", fallback)
					self:ChangeMapTo(fallback)
				else
					GlobalChatMsg("Map change failed, no maps available")
					self.Rounds = 0
					self.SetupCount = 0
					self:SetGameState(ROUND_WAIT)
				end
			end
		end
	end
end

function GM:NetworkMapVoteStart(ply)
	net.Start("ph_mapvote")
	net.WriteFloat(self.MapVoteStart)
	net.WriteFloat(self.MapVoteTime)

	for k, map in pairs(self.MapList) do
		net.WriteUInt(k, 16)
		net.WriteString(map)
	end
	net.WriteUInt(0, 16)

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end

	self:NetworkMapVotes()
end

function GM:NetworkMapVotes(ply)
	net.Start("ph_mapvotevotes")

	for k, map in pairs(self.MapVotes) do
		net.WriteUInt(1, 8)
		net.WriteEntity(k)
		net.WriteString(map)
	end
	net.WriteUInt(0, 8)

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

concommand.Add("ph_votemap", function(ply, com, args)
	if GAMEMODE.MapVoting then
		if #args < 1 then
			return
		end

		local found
		for k, v in pairs(GAMEMODE.MapList) do
			if v:lower() == args[1]:lower() then
				found = v
				break
			end
		end

		if !found then
			ply:ChatPrint("Invalid map " .. args[1])
			return
		end

		GAMEMODE.MapVotes[ply] = found
		GAMEMODE:NetworkMapVotes()
	end
end)
