-- Système de spatialisation audio 3D amélioré pour Prop Hunt
-- Corrige le problème de perception de la hauteur des sons

local AudioSpatialization = {}

-- Configuration de la spatialisation audio
AudioSpatialization.Config = {
    -- Distance maximale pour entendre les sons
    MaxDistance = 2000,
    -- Facteur de réduction du volume selon la distance
    DistanceFalloff = 0.8,
    -- Facteur de réduction du volume selon la hauteur
    HeightFalloff = 0.3,
    -- Seuil minimum de volume
    MinVolume = 0.1,
    -- Seuil maximum de volume
    MaxVolume = 1.0,
    -- Facteur de pitch selon la hauteur (plus aigu en haut, plus grave en bas)
    HeightPitchFactor = 0.1
}

-- Fonction pour calculer la distance 3D entre deux positions
function AudioSpatialization:CalculateDistance3D(pos1, pos2)
    return pos1:Distance(pos2)
end

-- Fonction pour calculer la différence de hauteur
function AudioSpatialization:CalculateHeightDifference(pos1, pos2)
    return math.abs(pos1.z - pos2.z)
end

-- Fonction pour calculer le volume basé sur la distance et la hauteur
function AudioSpatialization:CalculateVolume3D(soundPos, listenerPos, baseVolume)
    local distance = self:CalculateDistance3D(soundPos, listenerPos)
    local heightDiff = self:CalculateHeightDifference(soundPos, listenerPos)
    
    -- Calcul du volume basé sur la distance
    local distanceVolume = math.max(0, 1 - (distance / self.Config.MaxDistance) * self.Config.DistanceFalloff)
    
    -- Calcul du volume basé sur la hauteur
    local heightVolume = math.max(0, 1 - (heightDiff / 500) * self.Config.HeightFalloff)
    
    -- Volume final combiné
    local finalVolume = baseVolume * distanceVolume * heightVolume
    
    return math.Clamp(finalVolume, self.Config.MinVolume, self.Config.MaxVolume)
end

-- Fonction pour calculer le pitch basé sur la hauteur
function AudioSpatialization:CalculatePitch3D(soundPos, listenerPos, basePitch)
    local heightDiff = self:CalculateHeightDifference(soundPos, listenerPos)
    local heightDirection = soundPos.z - listenerPos.z
    
    -- Plus aigu si le son vient d'en haut, plus grave s'il vient d'en bas
    local pitchModifier = (heightDirection / 1000) * self.Config.HeightPitchFactor
    
    return math.Clamp(basePitch + pitchModifier, 0.5, 2.0)
end

-- Fonction pour émettre un son avec spatialisation 3D
function AudioSpatialization:EmitSound3D(ent, soundName, volume, pitch, channel, flags)
    if not IsValid(ent) then return end
    
    local soundPos = ent:GetPos()
    local listeners = {}
    
    -- Récupérer tous les joueurs qui peuvent entendre le son
    if ent:IsPlayer() then
        -- Pour les sons de joueurs, utiliser le système de chat/voice existant
        for _, ply in pairs(player.GetAll()) do
            if GAMEMODE:PlayerCanHearChatVoice(ply, ent, "voice") then
                table.insert(listeners, ply)
            end
        end
    else
        -- Pour les sons d'entités, tous les joueurs vivants peuvent entendre
        for _, ply in pairs(player.GetAll()) do
            if ply:Alive() and not ply:IsSpectator() then
                table.insert(listeners, ply)
            end
        end
    end
    
    -- Émettre le son pour chaque auditeur avec spatialisation
    for _, listener in pairs(listeners) do
        if IsValid(listener) then
            local listenerPos = listener:GetPos()
            local calculatedVolume = self:CalculateVolume3D(soundPos, listenerPos, volume or 1)
            local calculatedPitch = self:CalculatePitch3D(soundPos, listenerPos, pitch or 100)
            
            -- Émettre le son avec les paramètres calculés
            ent:EmitSound(soundName, calculatedVolume * 100, calculatedPitch, channel or CHAN_AUTO, flags or 0)
        end
    end
end

-- Fonction pour émettre un son de taunt avec spatialisation
function AudioSpatialization:EmitTaunt3D(ply, soundName, volume, pitch)
    if not IsValid(ply) or not ply:Alive() then return end
    
    local soundPos = ply:GetPos()
    local listeners = {}
    
    -- Récupérer les auditeurs selon les règles du gamemode
    for _, listener in pairs(player.GetAll()) do
        if GAMEMODE:PlayerCanHearChatVoice(listener, ply, "voice") then
            table.insert(listeners, listener)
        end
    end
    
    -- Émettre le son pour chaque auditeur
    for _, listener in pairs(listeners) do
        if IsValid(listener) then
            local listenerPos = listener:GetPos()
            local calculatedVolume = self:CalculateVolume3D(soundPos, listenerPos, volume or 1)
            local calculatedPitch = self:CalculatePitch3D(soundPos, listenerPos, pitch or 100)
            
            -- Utiliser une approche différente pour les taunts (sons de joueurs)
            -- Envoyer le son via le réseau pour un meilleur contrôle
            net.Start("ph_taunt_3d")
            net.WriteEntity(ply)
            net.WriteString(soundName)
            net.WriteFloat(calculatedVolume)
            net.WriteFloat(calculatedPitch)
            net.Send(listener)
        end
    end
end

-- Fonction pour émettre un son de mort avec spatialisation
function AudioSpatialization:EmitDeathSound3D(ply, soundName, volume, pitch)
    if not IsValid(ply) then return end
    
    local soundPos = ply:GetPos()
    local listeners = {}
    
    -- Tous les joueurs vivants peuvent entendre les sons de mort
    for _, listener in pairs(player.GetAll()) do
        if listener:Alive() and not listener:IsSpectator() then
            table.insert(listeners, listener)
        end
    end
    
    -- Émettre le son pour chaque auditeur
    for _, listener in pairs(listeners) do
        if IsValid(listener) then
            local listenerPos = listener:GetPos()
            local calculatedVolume = self:CalculateVolume3D(soundPos, listenerPos, volume or 1)
            local calculatedPitch = self:CalculatePitch3D(soundPos, listenerPos, pitch or 100)
            
            -- Envoyer le son via le réseau
            net.Start("ph_death_sound_3d")
            net.WriteEntity(ply)
            net.WriteString(soundName)
            net.WriteFloat(calculatedVolume)
            net.WriteFloat(calculatedPitch)
            net.Send(listener)
        end
    end
end

-- Fonction pour émettre un son de déguisement avec spatialisation
function AudioSpatialization:EmitDisguiseSound3D(ply, soundName, volume, pitch)
    if not IsValid(ply) then return end
    
    local soundPos = ply:GetPos()
    local listeners = {}
    
    -- Tous les joueurs proches peuvent entendre le son de déguisement
    for _, listener in pairs(player.GetAll()) do
        if IsValid(listener) and listener:Alive() then
            local distance = self:CalculateDistance3D(soundPos, listener:GetPos())
            if distance <= 500 then -- Portée limitée pour les sons de déguisement
                table.insert(listeners, listener)
            end
        end
    end
    
    -- Émettre le son pour chaque auditeur
    for _, listener in pairs(listeners) do
        if IsValid(listener) then
            local listenerPos = listener:GetPos()
            local calculatedVolume = self:CalculateVolume3D(soundPos, listenerPos, volume or 1)
            local calculatedPitch = self:CalculatePitch3D(soundPos, listenerPos, pitch or 100)
            
            -- Envoyer le son via le réseau
            net.Start("ph_disguise_sound_3d")
            net.WriteEntity(ply)
            net.WriteString(soundName)
            net.WriteFloat(calculatedVolume)
            net.WriteFloat(calculatedPitch)
            net.Send(listener)
        end
    end
end

-- Exporter le module
_G.AudioSpatialization = AudioSpatialization
