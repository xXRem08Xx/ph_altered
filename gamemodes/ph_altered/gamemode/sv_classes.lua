-- Logique serveur du système de classes.

AddCSLuaFile("sh_classes.lua")
AddCSLuaFile("cl_classes.lua")
AddCSLuaFile("cl_class_select.lua")
include("sh_classes.lua")

util.AddNetworkString("ph_class_pick")        -- cl -> sv : pick d'une classe
util.AddNetworkString("ph_class_use")         -- cl -> sv : activation ability
util.AddNetworkString("ph_class_open_menu")   -- sv -> cl : ouvre le panel de sélection
util.AddNetworkString("ph_class_effect")      -- sv -> cl : effet visuel (scout silhouette, demolition/sweeper dôme, ghost flash...)
util.AddNetworkString("ph_class_warning")     -- sv -> cl : warning prop (tracker)

GAMEMODE = GAMEMODE or GM
GAMEMODE.ClassesTaken = GAMEMODE.ClassesTaken or { [TEAM_PROP] = {}, [TEAM_HUNTER] = {} }

-- Délai de sécurité max pour le verrouillage HIDE : si personne ne valide, on débloque automatiquement.
CreateConVar("ph_classes_pick_max_wait", "60", bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY),
    "Durée max (secondes) d'attente des picks de classe avant déverrouillage auto")

local function livingPickers()
    local list = {}
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) and not ply:IsSpectator() and ply:GetNWBool("RoundInGame", false) and ply:Alive() then
            list[#list + 1] = ply
        end
    end
    return list
end

local function countPending()
    local pending = 0
    for _, ply in ipairs(livingPickers()) do
        if not ply:GetNWBool("ph_class_picked", false) then
            pending = pending + 1
        end
    end
    return pending
end

local function broadcastPending()
    SetGlobalInt("ph_hide_picks_pending", countPending())
end

function GAMEMODE:LockHidePhase()
    SetGlobalBool("ph_hide_locked", true)
    broadcastPending()
    timer.Create("ph_hide_lock_safety", GetConVar("ph_classes_pick_max_wait"):GetInt(), 1, function()
        if GetGlobalBool("ph_hide_locked", false) then
            GAMEMODE:UnlockHidePhase()
        end
    end)
end

function GAMEMODE:UnlockHidePhase()
    if not GetGlobalBool("ph_hide_locked", false) then return end
    SetGlobalBool("ph_hide_locked", false)
    SetGlobalInt("ph_hide_picks_pending", 0)
    timer.Remove("ph_hide_lock_safety")
    -- Redémarre le compte à rebours HIDE au moment exact du déverrouillage.
    if self:GetGameState() == ROUND_HIDE then
        self.StateStart = CurTime()
        self:NetworkGameState()
    end
end

function GAMEMODE:CheckHidePicks()
    if not GetGlobalBool("ph_hide_locked", false) then return end
    broadcastPending()
    if countPending() == 0 then
        self:UnlockHidePhase()
    end
end

-- Helpers internes

local function clearPick(ply)
    if not IsValid(ply) then return end
    local id = ply:GetNWString("ph_class", "")
    if id ~= "" then
        for _, team in ipairs({TEAM_PROP, TEAM_HUNTER}) do
            if GAMEMODE.ClassesTaken[team] and GAMEMODE.ClassesTaken[team][id] == ply:SteamID() then
                GAMEMODE.ClassesTaken[team][id] = nil
            end
        end
    end
    ply:SetNWString("ph_class", "")
    ply:SetNWBool("ph_ability_used", false)
    -- Note : ph_class_picked n'est PAS reset ici (géré au niveau de ResetClassPicks / pick handler).
end

local function isTaken(team, id)
    return GAMEMODE.ClassesTaken[team] and GAMEMODE.ClassesTaken[team][id] ~= nil
end

local function sendEffect(scope, payload)
    -- scope: table of players or nil (broadcast)
    net.Start("ph_class_effect")
    net.WriteString(payload.kind or "")
    net.WriteEntity(payload.source or NULL)
    net.WriteVector(payload.pos or vector_origin)
    net.WriteFloat(payload.radius or 0)
    net.WriteFloat(payload.duration or 0)
    if scope then
        net.Send(scope)
    else
        net.Broadcast()
    end
end

function GAMEMODE:ResetClassPicks()
    self.ClassesTaken = { [TEAM_PROP] = {}, [TEAM_HUNTER] = {} }
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) then
            ply:SetNWString("ph_class", "")
            ply:SetNWBool("ph_ability_used", false)
            ply:SetNWBool("ph_class_picked", false)
        end
    end
end

function GAMEMODE:OpenClassMenu(targets)
    targets = targets or player.GetHumans()
    net.Start("ph_class_open_menu")
    net.Send(targets)
end

function GAMEMODE:AutoAssignClasses()
    if not GetConVar("ph_classes_auto_assign"):GetBool() then return end
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) and not ply:IsSpectator() and ply:GetNWString("ph_class", "") == "" then
            local pool = PH.GetAvailableClasses(ply:Team())
            local candidates = {}
            for _, def in ipairs(pool) do
                if not isTaken(ply:Team(), def.id) then
                    candidates[#candidates + 1] = def
                end
            end
            if #candidates > 0 then
                local pick = candidates[math.random(#candidates)]
                GAMEMODE.ClassesTaken[ply:Team()][pick.id] = ply:SteamID()
                ply:SetNWString("ph_class", pick.id)
                ply:SetNWBool("ph_ability_used", false)
            end
        end
    end
end

-- ===========================================================================
-- Définitions des classes
-- ===========================================================================

-- Helper trace pour Medic / Scout / etc.
local function traceFromEye(ply, dist)
    return util.TraceLine({
        start  = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * dist,
        filter = ply,
    })
end

-- --- Medic (prop) ---
PH.RegisterClass("medic", {
    team = TEAM_PROP,
    name = "Medic",
    desc = "Soigne 50 HP : toi-même ou un allié visé (portée 400u).",
    order = 1,
    phase = PH.CLASS_PHASE_ANY,
    onUse = function(ply)
        local heal = GetConVar("ph_class_medic_heal"):GetInt()
        local tr = traceFromEye(ply, 400)
        local target = ply
        if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:IsProp() and tr.Entity:Alive() then
            target = tr.Entity
        end
        local maxHP = target.GetHMaxHealth and target:GetHMaxHealth() or target:GetMaxHealth()
        local newHP = math.min(target:Health() + heal, maxHP)
        if newHP <= target:Health() then return false end
        target:SetHealth(newHP)
        sendEffect({target}, {kind = "medic_heal", source = target, pos = target:GetPos(), duration = 1})
        return true
    end,
})

-- --- Ghost (prop) ---
PH.RegisterClass("ghost", {
    team = TEAM_PROP,
    name = "Ghost",
    desc = "Invisibilité totale 3s. Annulée si tu prends des dégâts.",
    order = 2,
    phase = PH.CLASS_PHASE_ANY,
    onUse = function(ply)
        local dur = GetConVar("ph_class_ghost_duration"):GetFloat()
        ply.ph_ghost_until = CurTime() + dur
        ply:SetNoDraw(true)
        ply:DrawShadow(false)
        -- Cache aussi l'entité disguise
        local dent = ply:GetNWEntity("disguiseEntity")
        if IsValid(dent) then dent:SetNoDraw(true) end
        sendEffect(nil, {kind = "ghost_start", source = ply, pos = ply:GetPos(), duration = dur})
        timer.Create("ph_ghost_" .. ply:SteamID(), dur, 1, function()
            if IsValid(ply) then
                ply.ph_ghost_until = nil
                ply:SetNoDraw(false)
                ply:DrawShadow(true)
                local d = ply:GetNWEntity("disguiseEntity")
                if IsValid(d) then d:SetNoDraw(false) end
                sendEffect(nil, {kind = "ghost_end", source = ply, pos = ply:GetPos()})
            end
        end)
        return true
    end,
})

-- Hook qui coupe Ghost si dégâts
hook.Add("EntityTakeDamage", "PH_Ghost_CancelOnDamage", function(ent, dmg)
    if ent:IsPlayer() and ent.ph_ghost_until and ent.ph_ghost_until > CurTime() then
        ent.ph_ghost_until = nil
        ent:SetNoDraw(false)
        ent:DrawShadow(true)
        local d = ent:GetNWEntity("disguiseEntity")
        if IsValid(d) then d:SetNoDraw(false) end
        timer.Remove("ph_ghost_" .. ent:SteamID())
        sendEffect(nil, {kind = "ghost_end", source = ent, pos = ent:GetPos()})
    end
end)

-- --- Decoy (prop) ---
PH.RegisterClass("decoy", {
    team = TEAM_PROP,
    name = "Decoy",
    desc = "Crée un clone statique de ton déguisement pendant 15s.",
    order = 3,
    phase = PH.CLASS_PHASE_SEEK,
    onUse = function(ply)
        local model = ply:GetNWString("disguiseModel", ply:GetModel())
        if not model or model == "" then return false end
        local clone = ents.Create("prop_physics")
        if not IsValid(clone) then return false end
        clone:SetModel(model)
        clone:SetPos(ply:GetPos())
        clone:SetAngles(ply:GetAngles())
        clone.IsDecoy = true
        clone:Spawn()
        local phys = clone:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        local dur = GetConVar("ph_class_decoy_duration"):GetInt()
        sendEffect(nil, {kind = "decoy_spawn", source = clone, pos = clone:GetPos(), duration = dur})
        timer.Simple(dur, function()
            if IsValid(clone) then SafeRemoveEntity(clone) end
        end)
        return true
    end,
})

-- Exclure les decoys du pool de déguisement random
hook.Add("PH_CanDisguiseAs", "PH_ExcludeDecoys", function(ply, ent)
    if IsValid(ent) and ent.IsDecoy then return false end
end)

-- --- Jumper (prop) ---
PH.RegisterClass("jumper", {
    team = TEAM_PROP,
    name = "Jumper",
    desc = "Téléportation aléatoire dans un rayon accessible aux chasseurs.",
    order = 4,
    phase = PH.CLASS_PHASE_SEEK,
    onUse = function(ply)
        local minR = GetConVar("ph_class_jumper_min_range"):GetInt()
        local maxR = GetConVar("ph_class_jumper_max_range"):GetInt()
        local origin = ply:GetPos()

        for attempt = 1, 10 do
            local ang = math.rad(math.random(0, 359))
            local dist = math.random(minR, maxR)
            local candidate = origin + Vector(math.cos(ang) * dist, math.sin(ang) * dist, 0)
            -- Trace sol vers le bas pour s'ancrer
            local tr = util.TraceLine({
                start = candidate + Vector(0, 0, 200),
                endpos = candidate + Vector(0, 0, -2000),
                filter = ply,
                mask = MASK_SOLID_BRUSHONLY,
            })
            if tr.Hit and not tr.StartSolid then
                -- Vérifier que le hull du joueur tient
                local destPos = tr.HitPos + Vector(0, 0, 2)
                local hullCheck = util.TraceHull({
                    start = destPos,
                    endpos = destPos,
                    mins = ply:OBBMins(),
                    maxs = ply:OBBMaxs(),
                    filter = ply,
                    mask = MASK_PLAYERSOLID,
                })
                if not hullCheck.Hit and not hullCheck.StartSolid then
                    local fx = EffectData()
                    fx:SetOrigin(origin); fx:SetScale(20); fx:SetMagnitude(64)
                    util.Effect("ph_disguise", fx, true, true)
                    ply:SetPos(destPos)
                    fx:SetOrigin(destPos)
                    util.Effect("ph_disguise", fx, true, true)
                    sendEffect(nil, {kind = "jumper_tp", source = ply, pos = destPos})
                    return true
                end
            end
        end

        ply:ChatPrint("[Jumper] Aucune destination valide trouvée, réessaye ailleurs.")
        return false -- ne consomme pas la charge
    end,
})

-- --- Scout (hunter) ---
PH.RegisterClass("scout", {
    team = TEAM_HUNTER,
    name = "Scout",
    desc = "Silhouette les props dans un cône devant toi pendant 2s.",
    order = 1,
    phase = PH.CLASS_PHASE_SEEK,
    onUse = function(ply)
        local coneDeg = GetConVar("ph_class_scout_cone_deg"):GetInt()
        local range = GetConVar("ph_class_scout_range"):GetInt()
        local cosT = math.cos(math.rad(coneDeg / 2))
        local aim = ply:GetAimVector()
        local origin = ply:EyePos()
        local revealed = {}
        for _, p in ipairs(player.GetHumans()) do
            if IsValid(p) and p:IsProp() and p:Alive() and not (p.ph_ghost_until and p.ph_ghost_until > CurTime()) then
                local delta = p:GetPos() - origin
                local dist = delta:Length()
                if dist <= range then
                    local dir = delta:GetNormalized()
                    if aim:Dot(dir) >= cosT then
                        revealed[#revealed + 1] = p
                        p:SetNWFloat("ph_scouted_until", CurTime() + 2)
                    end
                end
            end
        end
        sendEffect({ply}, {kind = "scout_flash", source = ply, pos = origin, duration = 2})
        return #revealed > 0 or true
    end,
})

-- --- Tracker (hunter) ---
PH.RegisterClass("tracker", {
    team = TEAM_HUNTER,
    name = "Tracker",
    desc = "Révèle la position des props 3s. Ils reçoivent un warning après 1s.",
    order = 2,
    phase = PH.CLASS_PHASE_SEEK,
    onUse = function(ply)
        local delay = GetConVar("ph_class_tracker_warn_delay"):GetFloat()
        local targets = {}
        for _, p in ipairs(player.GetHumans()) do
            if IsValid(p) and p:IsProp() and p:Alive() and not (p.ph_ghost_until and p.ph_ghost_until > CurTime()) then
                targets[#targets + 1] = p
                p:SetNWFloat("ph_tracked_until", CurTime() + 3)
            end
        end
        sendEffect({ply}, {kind = "tracker_reveal", source = ply, pos = ply:GetPos(), duration = 3})
        timer.Simple(delay, function()
            for _, p in ipairs(targets) do
                if IsValid(p) and p:Alive() then
                    net.Start("ph_class_warning")
                    net.WriteString("tracker")
                    net.Send(p)
                end
            end
        end)
        return true
    end,
})

-- --- Demolition (hunter) ---
PH.RegisterClass("demolition", {
    team = TEAM_HUNTER,
    name = "Demolition",
    desc = "Pulse autour de toi qui révèle les props dans 400u pendant 3s.",
    order = 3,
    phase = PH.CLASS_PHASE_SEEK,
    onUse = function(ply)
        local radius = GetConVar("ph_class_demolition_radius"):GetInt()
        local origin = ply:GetPos()
        for _, p in ipairs(player.GetHumans()) do
            if IsValid(p) and p:IsProp() and p:Alive() and not (p.ph_ghost_until and p.ph_ghost_until > CurTime()) then
                local d = origin:Distance(p:GetPos())
                if d <= radius then
                    -- Trace d'occlusion
                    local tr = util.TraceLine({start = origin, endpos = p:GetPos(), filter = {ply, p}, mask = MASK_SOLID_BRUSHONLY})
                    if not tr.Hit then
                        p:SetNWFloat("ph_scouted_until", CurTime() + 3)
                    end
                end
            end
        end
        sendEffect({ply}, {kind = "demolition_pulse", source = ply, pos = origin, radius = radius, duration = 3})
        return true
    end,
})

-- --- Sweeper (hunter) ---
PH.RegisterClass("sweeper", {
    team = TEAM_HUNTER,
    name = "Sweeper",
    desc = "Supprime aléatoirement 40% des props dans 700u (ne touche pas aux props joueurs).",
    order = 4,
    phase = PH.CLASS_PHASE_SEEK,
    onUse = function(ply)
        local radius = GetConVar("ph_class_sweeper_radius"):GetInt()
        local pct = GetConVar("ph_class_sweeper_percent"):GetInt() / 100
        local cap = GetConVar("ph_class_sweeper_cap"):GetInt()
        local origin = ply:GetPos()

        -- Set des props actuellement utilisés par des joueurs
        local playerDisguises = {}
        for _, p in ipairs(player.GetHumans()) do
            if IsValid(p) and p:IsProp() and p:Alive() then
                local dent = p:GetNWEntity("disguiseEntity")
                if IsValid(dent) then playerDisguises[dent] = true end
            end
        end

        -- Collecte candidats
        local candidates = {}
        for _, ent in ipairs(ents.FindInSphere(origin, radius)) do
            if IsValid(ent) and ent.IsDisguisableAs and ent:IsDisguisableAs()
                and not playerDisguises[ent] and not ent.IsDecoy then
                candidates[#candidates + 1] = ent
            end
        end

        -- Sélection aléatoire
        table.Shuffle(candidates)
        local target = math.min(math.floor(#candidates * pct + 0.5), cap)
        for i = 1, target do
            local ent = candidates[i]
            if IsValid(ent) then
                local fx = EffectData()
                fx:SetOrigin(ent:GetPos()); fx:SetScale(10); fx:SetMagnitude(20)
                util.Effect("ph_disguise", fx, true, true)
                SafeRemoveEntity(ent)
            end
        end

        sendEffect({ply}, {kind = "sweeper_pulse", source = ply, pos = origin, radius = radius, duration = 2})
        return true
    end,
})

-- ===========================================================================
-- Network handlers
-- ===========================================================================

net.Receive("ph_class_pick", function(_, ply)
    if not IsValid(ply) or ply:IsSpectator() then return end
    if not GetConVar("ph_classes_enabled"):GetBool() then return end
    if GAMEMODE:GetGameState() ~= ROUND_HIDE then return end

    local id = net.ReadString()
    if id == "" then
        -- Skip : vanilla (compte comme un choix validé)
        clearPick(ply)
        ply:SetNWBool("ph_class_picked", true)
        GAMEMODE:CheckHidePicks()
        return
    end

    local def = PH.Classes[id]
    if not def or def.team ~= ply:Team() or not PH.IsClassEnabled(id) then return end
    if isTaken(ply:Team(), id) then
        ply:ChatPrint("[Classes] Cette classe est déjà prise.")
        return
    end

    -- Libère l'ancienne pick
    clearPick(ply)
    GAMEMODE.ClassesTaken[ply:Team()][id] = ply:SteamID()
    ply:SetNWString("ph_class", id)
    ply:SetNWBool("ph_ability_used", false)
    ply:SetNWBool("ph_class_picked", true)
    GAMEMODE:CheckHidePicks()
end)

net.Receive("ph_class_use", function(_, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if not GetConVar("ph_classes_enabled"):GetBool() then return end
    if PH.AbilityUsed(ply) then return end

    local def = PH.GetClass(ply)
    if not def then return end

    local state = GAMEMODE:GetGameState()
    if def.phase == PH.CLASS_PHASE_SEEK and state ~= ROUND_SEEK then return end
    if def.phase == PH.CLASS_PHASE_HIDE and state ~= ROUND_HIDE then return end
    if def.phase == PH.CLASS_PHASE_ANY and state ~= ROUND_HIDE and state ~= ROUND_SEEK then return end

    local ok = def.onUse(ply)
    if ok then
        ply:SetNWBool("ph_ability_used", true)
    end
end)

-- Nettoyage sur disconnect
hook.Add("PlayerDisconnected", "PH_Classes_Cleanup", function(ply)
    clearPick(ply)
    timer.Remove("ph_ghost_" .. ply:SteamID())
    -- Le départ du joueur peut débloquer les picks restants
    timer.Simple(0, function() GAMEMODE:CheckHidePicks() end)
end)

-- Un joueur qui meurt pendant le lock (normalement impossible en HIDE) libère sa contribution
hook.Add("PostPlayerDeath", "PH_Classes_DeathPickRelease", function(ply)
    timer.Simple(0, function() GAMEMODE:CheckHidePicks() end)
end)

-- Reset des picks au setup de round (appelé depuis sv_rounds.lua)
hook.Add("OnSetupRound", "PH_Classes_ResetOnSetup", function()
    GAMEMODE:ResetClassPicks()
end)

-- Ouverture du menu à l'entrée en HIDE + verrouillage du timer
hook.Add("OnRoundHide", "PH_Classes_OpenMenu", function()
    if not GetConVar("ph_classes_enabled"):GetBool() then
        SetGlobalBool("ph_hide_locked", false)
        SetGlobalInt("ph_hide_picks_pending", 0)
        return
    end
    GAMEMODE:LockHidePhase()
    GAMEMODE:OpenClassMenu()
    -- Si aucun joueur éligible (edge case), on déverrouille tout de suite
    GAMEMODE:CheckHidePicks()
end)

-- Fallback auto-assign à la transition HIDE -> SEEK
hook.Add("OnRoundSeek", "PH_Classes_AutoAssign", function()
    if not GetConVar("ph_classes_enabled"):GetBool() then return end
    GAMEMODE:AutoAssignClasses()
end)
