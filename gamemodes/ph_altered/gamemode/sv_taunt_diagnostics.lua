-- Système de diagnostic avancé pour les problèmes de taunts
-- Identifie et corrige automatiquement les problèmes de sons

local TauntDiagnostics = {}

-- Configuration du diagnostic
TauntDiagnostics.Config = {
    -- Délai entre les diagnostics
    DiagnosticInterval = 30,
    -- Seuil de ping pour considérer un joueur comme problématique
    PingThreshold = 150,
    -- Seuil de perte de paquets
    PacketLossThreshold = 5,
    -- Nombre maximum de taunts par minute
    MaxTauntsPerMinute = 20,
    -- Délai de cooldown après un diagnostic
    CooldownTime = 60
}

-- Table pour suivre les diagnostics
local diagnosticHistory = {}
local playerStats = {}

-- Fonction pour analyser les problèmes d'un joueur
function TauntDiagnostics:AnalyzePlayer(ply)
    if not IsValid(ply) then return {} end
    
    local issues = {}
    local currentTime = CurTime()
    
    -- Vérifier le ping
    if ply:Ping() > self.Config.PingThreshold then
        table.insert(issues, {
            type = "ping",
            severity = "warning",
            message = "Ping élevé: " .. ply:Ping() .. "ms",
            solution = "Vérifier la connexion réseau"
        })
    end
    
    -- Vérifier si le joueur est bloqué
    if ply.TauntEnd and ply.TauntEnd > currentTime then
        local timeLeft = ply.TauntEnd - currentTime
        if timeLeft > 10 then
            table.insert(issues, {
                type = "blocked",
                severity = "error",
                message = "Taunt bloqué depuis " .. math.Round(timeLeft) .. " secondes",
                solution = "Débloquer le joueur"
            })
        end
    end
    
    -- Vérifier le nombre de taunts récents
    if ply.TauntAmount then
        local recentTaunts = 0
        if ply.TauntsUsed then
            recentTaunts = table.Count(ply.TauntsUsed)
        end
        
        if recentTaunts > self.Config.MaxTauntsPerMinute then
            table.insert(issues, {
                type = "spam",
                severity = "warning",
                message = "Trop de taunts récents: " .. recentTaunts,
                solution = "Réduire la fréquence des taunts"
            })
        end
    end
    
    -- Vérifier la connectivité réseau
    if ply:Ping() > 300 then
        table.insert(issues, {
            type = "network",
            severity = "error",
            message = "Connexion réseau instable",
            solution = "Vérifier la connexion internet"
        })
    end
    
    return issues
end

-- Fonction pour diagnostiquer tous les joueurs
function TauntDiagnostics:DiagnoseAllPlayers()
    local allIssues = {}
    local playersWithIssues = 0
    
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) then
            local issues = self:AnalyzePlayer(ply)
            if #issues > 0 then
                allIssues[ply:SteamID()] = {
                    player = ply,
                    issues = issues,
                    timestamp = CurTime()
                }
                playersWithIssues = playersWithIssues + 1
            end
        end
    end
    
    -- Enregistrer dans l'historique
    diagnosticHistory[CurTime()] = {
        totalPlayers = #player.GetAll(),
        playersWithIssues = playersWithIssues,
        issues = allIssues
    }
    
    return allIssues
end

-- Fonction pour corriger automatiquement les problèmes
function TauntDiagnostics:AutoFixIssues(issues)
    local fixesApplied = 0
    
    for steamId, data in pairs(issues) do
        local ply = data.player
        if IsValid(ply) then
            for _, issue in ipairs(data.issues) do
                if issue.type == "blocked" then
                    -- Débloquer le joueur
                    if TauntFix then
                        TauntFix:UnblockPlayer(ply)
                        fixesApplied = fixesApplied + 1
                        print("[TauntDiagnostics] Joueur débloqué automatiquement: " .. ply:Nick())
                    end
                elseif issue.type == "spam" then
                    -- Nettoyer les taunts du joueur
                    if TauntFix then
                        TauntFix:CleanupPlayerTaunts(ply)
                        fixesApplied = fixesApplied + 1
                        print("[TauntDiagnostics] Taunts nettoyés automatiquement: " .. ply:Nick())
                    end
                end
            end
        end
    end
    
    return fixesApplied
end

-- Fonction pour générer un rapport de diagnostic
function TauntDiagnostics:GenerateReport()
    local report = {
        timestamp = CurTime(),
        totalPlayers = #player.GetAll(),
        issues = {},
        recommendations = {}
    }
    
    -- Analyser tous les joueurs
    local allIssues = self:DiagnoseAllPlayers()
    
    -- Compter les types de problèmes
    local issueTypes = {}
    for steamId, data in pairs(allIssues) do
        for _, issue in ipairs(data.issues) do
            if not issueTypes[issue.type] then
                issueTypes[issue.type] = 0
            end
            issueTypes[issue.type] = issueTypes[issue.type] + 1
        end
    end
    
    report.issues = issueTypes
    
    -- Générer des recommandations
    if issueTypes.blocked and issueTypes.blocked > 0 then
        table.insert(report.recommendations, "Débloquer " .. issueTypes.blocked .. " joueur(s) bloqué(s)")
    end
    
    if issueTypes.ping and issueTypes.ping > 0 then
        table.insert(report.recommendations, "Vérifier la connectivité réseau de " .. issueTypes.ping .. " joueur(s)")
    end
    
    if issueTypes.spam and issueTypes.spam > 0 then
        table.insert(report.recommendations, "Limiter la fréquence des taunts pour " .. issueTypes.spam .. " joueur(s)")
    end
    
    return report
end

-- Fonction pour afficher un rapport de diagnostic
function TauntDiagnostics:DisplayReport(ply)
    if not IsValid(ply) then return end
    
    local report = self:GenerateReport()
    
    ply:ChatPrint("=== RAPPORT DE DIAGNOSTIC DES TAUNTS ===")
    ply:ChatPrint("Joueurs total: " .. report.totalPlayers)
    
    if table.Count(report.issues) > 0 then
        ply:ChatPrint("Problèmes détectés:")
        for issueType, count in pairs(report.issues) do
            ply:ChatPrint("- " .. issueType .. ": " .. count .. " joueur(s)")
        end
        
        if #report.recommendations > 0 then
            ply:ChatPrint("Recommandations:")
            for _, rec in ipairs(report.recommendations) do
                ply:ChatPrint("- " .. rec)
            end
        end
    else
        ply:ChatPrint("Aucun problème détecté !")
    end
end

-- Fonction pour corriger automatiquement tous les problèmes
function TauntDiagnostics:AutoFixAll()
    local issues = self:DiagnoseAllPlayers()
    local fixesApplied = self:AutoFixIssues(issues)
    
    print("[TauntDiagnostics] " .. fixesApplied .. " corrections automatiques appliquées")
    return fixesApplied
end

-- Timer pour le diagnostic automatique
timer.Create("TauntDiagnostics_AutoCheck", TauntDiagnostics.Config.DiagnosticInterval, 0, function()
    local issues = TauntDiagnostics:DiagnoseAllPlayers()
    if table.Count(issues) > 0 then
        print("[TauntDiagnostics] " .. table.Count(issues) .. " joueur(s) avec des problèmes détectés")
        
        -- Corriger automatiquement les problèmes simples
        TauntDiagnostics:AutoFixAll()
    end
end)

-- Commandes de diagnostic
concommand.Add("ph_taunt_diagnose_all", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    TauntDiagnostics:DisplayReport(ply)
end)

concommand.Add("ph_taunt_auto_fix", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local fixesApplied = TauntDiagnostics:AutoFixAll()
    ply:ChatPrint("Corrections automatiques appliquées: " .. fixesApplied)
end)

concommand.Add("ph_taunt_stats", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local stats = {
        totalPlayers = #player.GetAll(),
        playersWithIssues = 0,
        blockedPlayers = 0,
        highPingPlayers = 0
    }
    
    for _, player in pairs(player.GetAll()) do
        if IsValid(player) then
            local issues = TauntDiagnostics:AnalyzePlayer(player)
            if #issues > 0 then
                stats.playersWithIssues = stats.playersWithIssues + 1
                
                for _, issue in ipairs(issues) do
                    if issue.type == "blocked" then
                        stats.blockedPlayers = stats.blockedPlayers + 1
                    elseif issue.type == "ping" then
                        stats.highPingPlayers = stats.highPingPlayers + 1
                    end
                end
            end
        end
    end
    
    ply:ChatPrint("=== STATISTIQUES DES TAUNTS ===")
    ply:ChatPrint("Joueurs total: " .. stats.totalPlayers)
    ply:ChatPrint("Joueurs avec problèmes: " .. stats.playersWithIssues)
    ply:ChatPrint("Joueurs bloqués: " .. stats.blockedPlayers)
    ply:ChatPrint("Joueurs ping élevé: " .. stats.highPingPlayers)
end)

-- Exporter le module
_G.TauntDiagnostics = TauntDiagnostics
