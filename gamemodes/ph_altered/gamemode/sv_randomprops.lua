if SERVER then
  CreateConVar("ph_random_prop_mode", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Enable random prop mode (left click will randomly change prop)")
end

local originalPlayerDisguise = GM.PlayerDisguise

function GM:PlayerDisguise(ply, targetProp)
  if GetConVar("ph_random_prop_mode"):GetBool() then
      self:PlayerRandomProp(ply)
  else
      originalPlayerDisguise(self, ply, targetProp)
  end
end

function GM:PlayerRandomProp(ply)
  local range = 10000
  local pos = ply:GetPos()
  local props = {}
  local allowClasses = {"prop_physics", "prop_physics_multiplayer"}

  for _, ent in ipairs(ents.FindInSphere(pos, range)) do
      if table.HasValue(allowClasses, ent:GetClass()) then
          table.insert(props, ent)
      end
  end

  if #props == 0 then
      ply:ChatPrint("Aucun prop trouvé à proximité!")
      return
  end

  local randomProp = table.Random(props)
  ply:ChatPrint("Prop aléatoire sélectionné!")
  originalPlayerDisguise(self, ply, randomProp)
end
