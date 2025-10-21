-- Client-side audio spatialization system
-- Gère la réception et la lecture des sons spatialisés

-- Réception des taunts spatialisés
net.Receive("ph_taunt_3d", function()
    local ply = net.ReadEntity()
    local soundName = net.ReadString()
    local volume = net.ReadFloat()
    local pitch = net.ReadFloat()
    
    if IsValid(ply) and soundName and soundName != "" then
        -- Émettre le son avec les paramètres spatialisés
        ply:EmitSound(soundName, volume * 100, pitch, CHAN_AUTO, 0)
    end
end)

-- Réception des sons de mort spatialisés
net.Receive("ph_death_sound_3d", function()
    local ply = net.ReadEntity()
    local soundName = net.ReadString()
    local volume = net.ReadFloat()
    local pitch = net.ReadFloat()
    
    if IsValid(ply) and soundName and soundName != "" then
        -- Émettre le son avec les paramètres spatialisés
        ply:EmitSound(soundName, volume * 100, pitch, CHAN_AUTO, 0)
    end
end)

-- Réception des sons de déguisement spatialisés
net.Receive("ph_disguise_sound_3d", function()
    local ply = net.ReadEntity()
    local soundName = net.ReadString()
    local volume = net.ReadFloat()
    local pitch = net.ReadFloat()
    
    if IsValid(ply) and soundName and soundName != "" then
        -- Émettre le son avec les paramètres spatialisés
        ply:EmitSound(soundName, volume * 100, pitch, CHAN_AUTO, 0)
    end
end)

-- Hook pour améliorer la spatialisation des sons de pas
hook.Add("PlayerFootstep", "PH_EnhancedFootstepSpatialization", function(ply, pos, foot, sound, volume, filter)
    if not IsValid(ply) then return end
    
    -- Calculer la distance et la hauteur par rapport au joueur local
    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) then return end
    
    local distance = pos:Distance(localPlayer:GetPos())
    local heightDiff = math.abs(pos.z - localPlayer:GetPos().z)
    
    -- Ajuster le volume selon la distance et la hauteur
    local distanceVolume = math.max(0, 1 - (distance / 1000))
    local heightVolume = math.max(0, 1 - (heightDiff / 500) * 0.3)
    local finalVolume = volume * distanceVolume * heightVolume
    
    -- Ajuster le pitch selon la hauteur
    local heightDirection = pos.z - localPlayer:GetPos().z
    local pitchModifier = (heightDirection / 1000) * 0.1
    local finalPitch = math.Clamp(100 + pitchModifier, 50, 200)
    
    -- Émettre le son avec les paramètres calculés
    ply:EmitSound(sound, finalVolume * 100, finalPitch, CHAN_AUTO, 0)
    
    return true -- Empêcher l'émission du son original
end)

-- Hook pour améliorer la spatialisation des sons d'armes
hook.Add("EntityEmitSound", "PH_EnhancedWeaponSpatialization", function(t)
    if not IsValid(t.entity) then return end
    
    -- Vérifier si c'est un joueur qui tire
    if t.entity:IsPlayer() and t.entity:Alive() then
        local localPlayer = LocalPlayer()
        if not IsValid(localPlayer) then return end
        
        local soundPos = t.entity:GetPos()
        local listenerPos = localPlayer:GetPos()
        
        -- Calculer la distance et la hauteur
        local distance = soundPos:Distance(listenerPos)
        local heightDiff = math.abs(soundPos.z - listenerPos.z)
        
        -- Ajuster le volume selon la distance et la hauteur
        local distanceVolume = math.max(0, 1 - (distance / 2000) * 0.8)
        local heightVolume = math.max(0, 1 - (heightDiff / 500) * 0.3)
        local finalVolume = t.volume * distanceVolume * heightVolume
        
        -- Ajuster le pitch selon la hauteur
        local heightDirection = soundPos.z - listenerPos.z
        local pitchModifier = (heightDirection / 1000) * 0.1
        local finalPitch = math.Clamp(t.pitch + pitchModifier, 0.5, 2.0)
        
        -- Modifier les paramètres du son
        t.volume = math.Clamp(finalVolume, 0.1, 1.0)
        t.pitch = finalPitch
        
        return true
    end
end)

-- Hook pour améliorer la spatialisation des sons d'explosion
hook.Add("EntityEmitSound", "PH_EnhancedExplosionSpatialization", function(t)
    if not IsValid(t.entity) then return end
    
    -- Vérifier si c'est une explosion
    if t.sound and (t.sound:find("explosion") or t.sound:find("grenade") or t.sound:find("bomb")) then
        local localPlayer = LocalPlayer()
        if not IsValid(localPlayer) then return end
        
        local soundPos = t.entity:GetPos()
        local listenerPos = localPlayer:GetPos()
        
        -- Calculer la distance et la hauteur
        local distance = soundPos:Distance(listenerPos)
        local heightDiff = math.abs(soundPos.z - listenerPos.z)
        
        -- Ajuster le volume selon la distance et la hauteur
        local distanceVolume = math.max(0, 1 - (distance / 3000) * 0.9)
        local heightVolume = math.max(0, 1 - (heightDiff / 1000) * 0.2)
        local finalVolume = t.volume * distanceVolume * heightVolume
        
        -- Ajuster le pitch selon la hauteur
        local heightDirection = soundPos.z - listenerPos.z
        local pitchModifier = (heightDirection / 2000) * 0.05
        local finalPitch = math.Clamp(t.pitch + pitchModifier, 0.3, 1.5)
        
        -- Modifier les paramètres du son
        t.volume = math.Clamp(finalVolume, 0.1, 1.0)
        t.pitch = finalPitch
        
        return true
    end
end)

-- Fonction utilitaire pour afficher des informations de debug audio
local function ShowAudioDebug()
    if not GetConVar("ph_audio_debug"):GetBool() then return end
    
    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) then return end
    
    local pos = localPlayer:GetPos()
    local eyePos = localPlayer:EyePos()
    
    -- Afficher les informations de position
    draw.SimpleText("Position: " .. tostring(pos), "DermaDefault", 10, 10, Color(255, 255, 255), TEXT_ALIGN_LEFT)
    draw.SimpleText("Eye Position: " .. tostring(eyePos), "DermaDefault", 10, 30, Color(255, 255, 255), TEXT_ALIGN_LEFT)
    
    -- Afficher les informations des sons proches
    local nearbySounds = 0
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply != localPlayer then
            local distance = pos:Distance(ply:GetPos())
            if distance <= 1000 then
                nearbySounds = nearbySounds + 1
            end
        end
    end
    
    draw.SimpleText("Sons proches: " .. nearbySounds, "DermaDefault", 10, 50, Color(255, 255, 255), TEXT_ALIGN_LEFT)
end

-- Hook pour afficher le debug audio
hook.Add("HUDPaint", "PH_AudioDebug", ShowAudioDebug)

-- Commande pour activer/désactiver le debug audio
concommand.Add("ph_audio_debug", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local enabled = args[1] == "1" or args[1] == "true"
    ply:SetNWBool("ph_audio_debug", enabled)
    
    if enabled then
        ply:ChatPrint("Debug audio activé")
    else
        ply:ChatPrint("Debug audio désactivé")
    end
end)
