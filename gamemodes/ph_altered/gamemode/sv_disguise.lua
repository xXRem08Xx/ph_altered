include("sh_disguise.lua")

local PlayerMeta = FindMetaTable("Player")

function GM:PlayerDisguise(ply)
	print("[DirectModification] PlayerDisguise called for " .. ply:Nick())
	if ply:IsHunter() then
		print("[DirectModification] Player is hunter; skipping disguise.")
		return
	end
	if GetConVar("ph_props_random_change"):GetBool() then
		local limit = GetConVar("ph_random_prop_limit"):GetInt() or 3
		local used = ply:GetNWInt("randomPropUses", 0)
		if not ply.RandomPropList then
			ply.RandomPropList = {}
			ply.RandomPropIndex = 0
		end
		local currentModel = ply:GetNWString("disguiseModel", "")
		local newProp = nil
		local range = 20000
		local pos = ply:GetPos()
		local props = {}
		local allowClasses = {"prop_physics", "prop_physics_multiplayer"}
		for _, ent in ipairs(ents.FindInSphere(pos, range)) do
			if table.HasValue(allowClasses, ent:GetClass()) then
				table.insert(props, ent)
			end
		end
		print("[DirectModification] Found " .. #props .. " allowed props for " .. ply:Nick())
		if #props == 0 then
			ply:ChatPrint("Aucun prop trouvé à proximité!")
			print("[DirectModification] No allowed prop found for " .. ply:Nick())
			return
		end
		if used < limit then
			newProp = table.Random(props)
			if newProp:GetModel() == currentModel and currentModel ~= "" then
				ply:ChatPrint("Déjà déguisé sur ce modèle, changement non compté.")
				print("[DirectModification] Same model as current, aborting change for " .. ply:Nick())
				return
			end
			ply:DisguiseAsProp(newProp)
			if ply:IsDisguised() then
				if not table.HasValue(ply.RandomPropList, newProp) then
					table.insert(ply.RandomPropList, newProp)
				end
				ply:SetNWInt("randomPropUses", used + 1)
				ply.LastDisguise = CurTime()
				ply:ChatPrint("Changement réussi! (" .. (limit - ply:GetNWInt("randomPropUses", 0)) .. " changements restants)")
				print("[DirectModification] Disguise succeeded for " .. ply:Nick())
			else
				ply:ChatPrint("Transformation échouée, changement non compté.")
				print("[DirectModification] Disguise failed for " .. ply:Nick())
			end
		else
			if #ply.RandomPropList == 0 then
				newProp = table.Random(props)
				table.insert(ply.RandomPropList, newProp)
			else
				ply.RandomPropIndex = (ply.RandomPropIndex or 0) + 1
				if ply.RandomPropIndex > #ply.RandomPropList then
					ply.RandomPropIndex = 1
				end
				newProp = ply.RandomPropList[ply.RandomPropIndex]
			end
			ply:DisguiseAsProp(newProp)
			if ply:IsDisguised() then
				ply.LastDisguise = CurTime()
				ply:ChatPrint("Changement réussi en mode cyclique!")
				print("[DirectModification] Cyclic disguise succeeded for " .. ply:Nick())
			else
				ply:ChatPrint("Transformation échouée en mode cyclique!")
				print("[DirectModification] Cyclic disguise failed for " .. ply:Nick())
			end
		end
	else
		local canDisguise, target = self:PlayerCanDisguiseCurrentTarget(ply)
		if not canDisguise then
			print("[DirectModification] Cannot disguise: condition not met for " .. ply:Nick())
			return
		end
		if ply.LastDisguise and ply.LastDisguise + 1 > CurTime() then
			print("[DirectModification] Cooldown active for disguise for " .. ply:Nick())
			return
		end
		ply:DisguiseAsProp(target)
		ply.LastDisguise = CurTime()
		print("[DirectModification] Disguise completed for " .. ply:Nick())
	end
end

function PlayerMeta:DisguiseAsProp(ent)
	local hullxy, hullz = ent:GetPropSize()
	if !self:CanFitHull(hullxy, hullxy, hullz) then
		self:PlayerChatMsg(Color(255, 50, 50), "Not enough room to change")
		return
	end

	if !self:IsDisguised() then
		self.OldPlayerModel = self:GetModel()
	end

	self:Flashlight(false)

	-- create an entity for the disguise
	-- we can't use a clientside entity as it needs a shadow
	local dent = self:GetNWEntity("disguiseEntity")
	if !IsValid(dent) then
		dent = ents.Create("ph_disguise")
		self:SetNWEntity("disguiseEntity", dent)
		dent.PropOwner = self
		dent:SetPos(self:GetPos())
		dent:Spawn()
	end
	dent:SetModel(ent:GetModel())

	self:SetNWBool("disguised", true)
	self:SetNWString("disguiseModel", ent:GetModel())
	self:SetNWVector("disguiseMins", ent:OBBMins())
	self:SetNWVector("disguiseMaxs", ent:OBBMaxs())
	self:SetNWInt("disguiseSkin", ent:GetSkin())
	self:SetNWBool("disguiseRotationLock", false)
	self:SetColor(Color(255, 0, 0, 0))
	self:SetRenderMode(RENDERMODE_NONE)
	self:SetModel(ent:GetModel())
	self:SetNoDraw(false)
	self:DrawShadow(false)
	GAMEMODE:PlayerSetNewHull(self, hullxy, hullz, hullz)

	local maxHealth = 1
	local volume = 1
	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		maxHealth = math.Clamp(math.Round(phys:GetVolume() / 230), 1, 200)
		volume = phys:GetVolume()
	end

	self.PercentageHealth = math.min(self:Health() / self:GetHMaxHealth(), self.PercentageHealth || 1)
	local per = math.Clamp(self.PercentageHealth * maxHealth, 1, 200)
	self:SetHealth(per)
	self:SetHMaxHealth(maxHealth)
	self:SetNWFloat("disguiseVolume", volume)

	self:CalculateSpeed()

	local offset = Vector(0, 0, ent:OBBMaxs().z - self:OBBMins().z + 10)
	self:SetViewOffset(offset)
	self:SetViewOffsetDucked(offset)

	self:EmitSound("weapons/bugbait/bugbait_squeeze" .. math.random(1, 3) .. ".wav")
	self.LastDisguise = CurTime()

	local eff = EffectData()
	eff:SetOrigin(self:GetPos() + Vector(0, 0, 1))
	eff:SetScale(hullxy)
	eff:SetMagnitude(hullz)
	util.Effect("ph_disguise", eff, true, true)
end

function PlayerMeta:IsDisguised()
	return self:GetNWBool("disguised", false)
end

function PlayerMeta:UnDisguise()
	local dent = self:GetNWEntity("disguiseEntity")
	if IsValid(dent) then
		dent:Remove()
	end

	self.PercentageHealth = nil
	self:SetNWBool("disguised", false)
	self:SetColor(Color(255, 255, 255, 255))
	self:SetNoDraw(false)
	self:DrawShadow(true)
	self:SetRenderMode(RENDERMODE_NORMAL)
	GAMEMODE:PlayerSetNewHull(self)
	if self.OldPlayerModel then
		self:SetModel(self.OldPlayerModel)
		self.OldPlayerModel = nil
	end

	self:SetViewOffset(Vector(0, 0, 64))
	self:SetViewOffsetDucked(Vector(0, 0, 28))

	self:CalculateSpeed()
end

function PlayerMeta:DisguiseLockRotation()
	if !self:IsDisguised() then return end

	local mins, maxs = self:CalculateRotatedDisguiseMinsMaxs()
	local hullx = math.Round((maxs.x - mins.x) / 2)
	local hully = math.Round((maxs.y - mins.y) / 2)
	local hullz = math.Round(maxs.z - mins.z)
	if !self:CanFitHull(hullx, hully, hullz) then
		self:PlayerChatMsg(Color(255, 50, 50), "Not enough room to lock rotation, move into a more open area")
		return
	end

	local ang = self:EyeAngles()
	self:SetNWBool("disguiseRotationLock", true)
	self:SetNWFloat("disguiseRotationLockYaw", ang.y)
	GAMEMODE:PlayerSetHull(self, hullx, hully, hullz, hullz)
end

function PlayerMeta:DisguiseUnlockRotation()
	local maxs = self:GetNWVector("disguiseMaxs")
	local mins = self:GetNWVector("disguiseMins")
	local hullxy = math.Round(math.Max(maxs.x - mins.x, maxs.y - mins.y) / 2)
	local hullz = math.Round(maxs.z - mins.z)
	if !self:CanFitHull(hullxy, hullxy, hullz) then
		self:PlayerChatMsg(Color(255, 50, 50), "Not enough room to unlock rotation, move into a more open area")
		return
	end

	self:SetNWBool("disguiseRotationLock", false)
	GAMEMODE:PlayerSetHull(self, hullxy, hullxy, hullz, hullz)
end

concommand.Add("ph_lockrotation", function(ply, com, args)
	if !IsValid(ply) then return end
	if !ply:IsDisguised() then return end

	if ply:DisguiseRotationLocked() then
		ply:DisguiseUnlockRotation()
	else
		ply:DisguiseLockRotation()
	end
end)
