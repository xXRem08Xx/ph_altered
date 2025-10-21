-- Système de correction des problèmes de taunts
-- Résout les problèmes de sons qui ne se jouent pas mais bloquent le timer

local TauntFix = {}

-- Configuration du système de correction
TauntFix.Config = {
    -- Délai maximum pour considérer un taunt comme échoué
    MaxTauntDuration = 10,
    -- Délai de vérification des taunts bloqués
    CheckInterval = 1,
    -- Nombre maximum de tentatives de retry
    MaxRetries = 3,
    -- Délai entre les tentatives
    RetryDelay = 0.5
}

-- Fonction pour vérifier si un son existe et est valide
function TauntFix:IsSoundValid(filename)
    if not filename or filename == "" then return false end
    
    -- Vérifier si le fichier son existe
    local soundName = FilenameToSoundname(filename)
    local duration = SoundDuration(filename)
    
    -- Si la durée est 0 ou très courte, le son n'existe probablement pas
    if duration <= 0 then return false end
    
    -- Vérifier si le son est dans la liste des sons autorisés
    if not AllowedTauntSounds[filename] then return false end
    
    return true
end

-- Fonction pour émettre un taunt avec validation et fallback
function TauntFix:EmitTauntSafe(ply, filename, durationOverride)
    if not IsValid(ply) or not ply:Alive() then return false end
    
    -- Vérifier si le son est valide
    if not self:IsSoundValid(filename) then
        print("[TauntFix] Son invalide: " .. tostring(filename))
        return false
    end
    
    local duration = SoundDuration(filename)
    if filename:match("%.mp3$") then
        duration = durationOverride or 1
    end
    
    local sndName = FilenameToSoundname(filename)
    local success = false
    
    -- Essayer d'émettre le son avec le système de spatialisation
    if AudioSpatialization then
        local success, err = pcall(function()
            AudioSpatialization:EmitTaunt3D(ply, sndName, 1.0, 100)
        end)
        
        if success then
            success = true
        else
            print("[TauntFix] Erreur spatialisation: " .. tostring(err))
        end
    end
    
    -- Fallback vers l'ancien système si la spatialisation échoue
    if not success then
        local success, err = pcall(function()
            ply:EmitSound(sndName)
        end)
        
        if success then
            success = true
        else
            print("[TauntFix] Erreur son basique: " .. tostring(err))
        end
    end
    
    -- Si le son a réussi, définir le timer
    if success then
        ply.TauntEnd = CurTime() + duration + 0.1
        ply.TauntAmount = (ply.TauntAmount or 0) + 1
        ply.AutoTauntDeadline = nil
        
        if not ply.TauntsUsed then ply.TauntsUsed = {} end
        ply.TauntsUsed[sndName] = true
        
        -- Ajouter un timer de sécurité pour débloquer le taunt
        timer.Create("taunt_safety_" .. ply:SteamID(), duration + 1, 1, function()
            if IsValid(ply) and ply.TauntEnd and CurTime() > ply.TauntEnd then
                ply.TauntEnd = nil
                print("[TauntFix] Timer de sécurité activé pour " .. ply:Nick())
            end
        end)
        
        return true
    else
        -- Si le son a échoué, ne pas bloquer le timer
        print("[TauntFix] Échec du taunt pour " .. ply:Nick() .. " - son: " .. filename)
        return false
    end
end

-- Fonction pour débloquer un joueur bloqué
function TauntFix:UnblockPlayer(ply)
    if not IsValid(ply) then return end
    
    -- Réinitialiser le timer de taunt
    ply.TauntEnd = nil
    ply.AutoTauntDeadline = nil
    
    -- Nettoyer les timers de sécurité
    timer.Remove("taunt_safety_" .. ply:SteamID())
    
    print("[TauntFix] Joueur débloqué: " .. ply:Nick())
end

-- Fonction pour vérifier et corriger les taunts bloqués
function TauntFix:CheckBlockedTaunts()
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply.TauntEnd then
            local timeLeft = ply.TauntEnd - CurTime()
            
            -- Si le timer est bloqué depuis trop longtemps
            if timeLeft > self.Config.MaxTauntDuration then
                print("[TauntFix] Taunt bloqué détecté pour " .. ply:Nick() .. " - déblocage automatique")
                self:UnblockPlayer(ply)
            end
        end
    end
end

-- Fonction pour retry un taunt échoué
function TauntFix:RetryTaunt(ply, filename, durationOverride, attempts)
    attempts = attempts or 0
    
    if attempts >= self.Config.MaxRetries then
        print("[TauntFix] Nombre maximum de tentatives atteint pour " .. ply:Nick())
        return false
    end
    
    -- Attendre un peu avant de réessayer
    timer.Simple(self.Config.RetryDelay, function()
        if IsValid(ply) then
            local success = self:EmitTauntSafe(ply, filename, durationOverride)
            if not success then
                self:RetryTaunt(ply, filename, durationOverride, attempts + 1)
            end
        end
    end)
    
    return true
end

-- Fonction pour diagnostiquer les problèmes de taunts
function TauntFix:DiagnoseTauntIssues(ply)
    if not IsValid(ply) then return end
    
    local issues = {}
    
    -- Vérifier si le joueur est bloqué
    if ply.TauntEnd and ply.TauntEnd > CurTime() then
        local timeLeft = ply.TauntEnd - CurTime()
        if timeLeft > self.Config.MaxTauntDuration then
            table.insert(issues, "Timer bloqué depuis " .. math.Round(timeLeft) .. " secondes")
        end
    end
    
    -- Vérifier les sons utilisés récemment
    if ply.TauntsUsed then
        local recentTaunts = 0
        for _, _ in pairs(ply.TauntsUsed) do
            recentTaunts = recentTaunts + 1
        end
        if recentTaunts > 10 then
            table.insert(issues, "Trop de taunts récents (" .. recentTaunts .. ")")
        end
    end
    
    -- Vérifier la connectivité réseau
    if ply:Ping() > 200 then
        table.insert(issues, "Ping élevé: " .. ply:Ping() .. "ms")
    end
    
    return issues
end

-- Fonction pour nettoyer les taunts d'un joueur
function TauntFix:CleanupPlayerTaunts(ply)
    if not IsValid(ply) then return end
    
    -- Arrêter tous les sons en cours
    if ply.TauntsUsed then
        for soundName, _ in pairs(ply.TauntsUsed) do
            ply:StopSound(soundName)
        end
    end
    
    -- Réinitialiser tous les timers
    ply.TauntEnd = nil
    ply.AutoTauntDeadline = nil
    ply.TauntsUsed = {}
    
    -- Nettoyer les timers de sécurité
    timer.Remove("taunt_safety_" .. ply:SteamID())
    
    print("[TauntFix] Nettoyage complet des taunts pour " .. ply:Nick())
end

-- Fonction pour obtenir des statistiques de taunts
function TauntFix:GetTauntStats(ply)
    if not IsValid(ply) then return {} end
    
    local stats = {
        totalTaunts = ply.TauntAmount or 0,
        isBlocked = ply.TauntEnd and ply.TauntEnd > CurTime(),
        timeLeft = ply.TauntEnd and math.max(0, ply.TauntEnd - CurTime()) or 0,
        recentTaunts = ply.TauntsUsed and table.Count(ply.TauntsUsed) or 0,
        ping = ply:Ping()
    }
    
    return stats
end

-- Timer pour vérifier les taunts bloqués
timer.Create("TauntFix_CheckBlocked", TauntFix.Config.CheckInterval, 0, function()
    TauntFix:CheckBlockedTaunts()
end)

-- Commande pour débloquer un joueur
concommand.Add("ph_taunt_unblock", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    TauntFix:UnblockPlayer(ply)
    ply:ChatPrint("Taunt débloqué !")
end)

-- Commande pour diagnostiquer les problèmes
concommand.Add("ph_taunt_diagnose", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local issues = TauntFix:DiagnoseTauntIssues(ply)
    if #issues == 0 then
        ply:ChatPrint("Aucun problème détecté avec vos taunts.")
    else
        ply:ChatPrint("Problèmes détectés:")
        for _, issue in ipairs(issues) do
            ply:ChatPrint("- " .. issue)
        end
    end
end)

-- Commande pour nettoyer les taunts
concommand.Add("ph_taunt_cleanup", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    TauntFix:CleanupPlayerTaunts(ply)
    ply:ChatPrint("Taunts nettoyés !")
end)

-- Commande pour obtenir les statistiques
concommand.Add("ph_taunt_stats", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local stats = TauntFix:GetTauntStats(ply)
    ply:ChatPrint("Statistiques de taunts:")
    ply:ChatPrint("- Total: " .. stats.totalTaunts)
    ply:ChatPrint("- Bloqué: " .. (stats.isBlocked and "Oui" or "Non"))
    ply:ChatPrint("- Temps restant: " .. math.Round(stats.timeLeft) .. "s")
    ply:ChatPrint("- Récents: " .. stats.recentTaunts)
    ply:ChatPrint("- Ping: " .. stats.ping .. "ms")
end)

-- Exporter le module
_G.TauntFix = TauntFix
