-- Système de validation des taunts côté client
-- Vérifie et corrige les problèmes de sons côté client

local TauntValidation = {}

-- Configuration de la validation
TauntValidation.Config = {
    -- Délai maximum pour considérer un son comme échoué
    MaxSoundWait = 2,
    -- Délai de vérification des sons bloqués
    CheckInterval = 0.5,
    -- Nombre maximum de tentatives de retry
    MaxRetries = 2,
    -- Délai entre les tentatives
    RetryDelay = 0.3
}

-- Table pour suivre les sons en cours
local activeSounds = {}
local soundId = 0

-- Fonction pour générer un ID unique pour un son
local function generateSoundId()
    soundId = soundId + 1
    return soundId
end

-- Fonction pour vérifier si un son est en cours de lecture
function TauntValidation:IsSoundPlaying(soundName)
    -- Vérifier si le son est dans la liste des sons actifs
    for id, data in pairs(activeSounds) do
        if data.soundName == soundName and data.endTime > CurTime() then
            return true
        end
    end
    return false
end

-- Fonction pour enregistrer un son en cours
function TauntValidation:RegisterSound(soundName, duration)
    local id = generateSoundId()
    activeSounds[id] = {
        soundName = soundName,
        startTime = CurTime(),
        endTime = CurTime() + duration,
        retries = 0
    }
    
    -- Nettoyer automatiquement après la durée
    timer.Simple(duration + 1, function()
        activeSounds[id] = nil
    end)
    
    return id
end

-- Fonction pour valider qu'un son se joue correctement
function TauntValidation:ValidateSound(soundName, expectedDuration)
    if not soundName or soundName == "" then return false end
    
    -- Vérifier si le son existe
    local duration = SoundDuration(soundName)
    if duration <= 0 then return false end
    
    -- Vérifier si le son est dans la liste des sons autorisés
    if not AllowedTauntSounds or not AllowedTauntSounds[soundName] then return false end
    
    return true
end

-- Fonction pour émettre un son avec validation
function TauntValidation:EmitSoundSafe(soundName, volume, pitch)
    if not self:ValidateSound(soundName) then
        print("[TauntValidation] Son invalide: " .. tostring(soundName))
        return false
    end
    
    local duration = SoundDuration(soundName)
    local id = self:RegisterSound(soundName, duration)
    
    -- Émettre le son
    LocalPlayer():EmitSound(soundName, volume or 100, pitch or 100)
    
    -- Vérifier après un court délai si le son se joue
    timer.Simple(0.1, function()
        if activeSounds[id] then
            -- Le son est toujours en cours, c'est bon
            print("[TauntValidation] Son validé: " .. soundName)
        else
            -- Le son a échoué, essayer de le relancer
            print("[TauntValidation] Son échoué, tentative de relance: " .. soundName)
            self:RetrySound(soundName, volume, pitch, 1)
        end
    end)
    
    return true
end

-- Fonction pour retry un son échoué
function TauntValidation:RetrySound(soundName, volume, pitch, attempts)
    attempts = attempts or 0
    
    if attempts >= self.Config.MaxRetries then
        print("[TauntValidation] Nombre maximum de tentatives atteint pour: " .. soundName)
        return false
    end
    
    -- Attendre un peu avant de réessayer
    timer.Simple(self.Config.RetryDelay, function()
        if self:ValidateSound(soundName) then
            LocalPlayer():EmitSound(soundName, volume or 100, pitch or 100)
            print("[TauntValidation] Retry " .. (attempts + 1) .. " pour: " .. soundName)
        end
    end)
    
    return true
end

-- Fonction pour nettoyer les sons bloqués
function TauntValidation:CleanupBlockedSounds()
    local currentTime = CurTime()
    local cleaned = 0
    
    for id, data in pairs(activeSounds) do
        if currentTime > data.endTime + self.Config.MaxSoundWait then
            activeSounds[id] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        print("[TauntValidation] " .. cleaned .. " sons bloqués nettoyés")
    end
end

-- Fonction pour obtenir des statistiques des sons
function TauntValidation:GetSoundStats()
    local stats = {
        activeSounds = table.Count(activeSounds),
        totalSounds = soundId,
        blockedSounds = 0
    }
    
    local currentTime = CurTime()
    for id, data in pairs(activeSounds) do
        if currentTime > data.endTime + self.Config.MaxSoundWait then
            stats.blockedSounds = stats.blockedSounds + 1
        end
    end
    
    return stats
end

-- Hook pour nettoyer les sons bloqués
timer.Create("TauntValidation_Cleanup", TauntValidation.Config.CheckInterval, 0, function()
    TauntValidation:CleanupBlockedSounds()
end)

-- Hook pour gérer les sons de taunts
hook.Add("EntityEmitSound", "TauntValidation_HandleTaunt", function(t)
    if not IsValid(t.entity) or not t.entity:IsPlayer() then return end
    
    -- Vérifier si c'est un son de taunt
    if t.sound and AllowedTauntSounds and AllowedTauntSounds[t.sound] then
        -- Enregistrer le son
        local duration = SoundDuration(t.sound)
        TauntValidation:RegisterSound(t.sound, duration)
        
        print("[TauntValidation] Son de taunt détecté: " .. t.sound)
    end
end)

-- Commande pour diagnostiquer les problèmes de sons
concommand.Add("ph_taunt_validate", function()
    local stats = TauntValidation:GetSoundStats()
    print("=== Statistiques des sons de taunts ===")
    print("Sons actifs: " .. stats.activeSounds)
    print("Total sons: " .. stats.totalSounds)
    print("Sons bloqués: " .. stats.blockedSounds)
    
    if stats.blockedSounds > 0 then
        print("ATTENTION: " .. stats.blockedSounds .. " sons bloqués détectés !")
        TauntValidation:CleanupBlockedSounds()
    end
end)

-- Commande pour nettoyer les sons bloqués
concommand.Add("ph_taunt_cleanup", function()
    TauntValidation:CleanupBlockedSounds()
    print("Nettoyage des sons bloqués effectué")
end)

-- Commande pour tester un son
concommand.Add("ph_taunt_test", function(ply, cmd, args)
    if not args[1] then
        print("Usage: ph_taunt_test <nom_du_son>")
        return
    end
    
    local soundName = args[1]
    local success = TauntValidation:EmitSoundSafe(soundName, 100, 100)
    
    if success then
        print("Test du son réussi: " .. soundName)
    else
        print("Test du son échoué: " .. soundName)
    end
end)

-- Exporter le module
_G.TauntValidation = TauntValidation
