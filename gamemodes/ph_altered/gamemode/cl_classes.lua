-- Classes ph_altered — côté client
-- HUD card, bind d'activation, réception des effets.

include("sh_classes.lua")

CreateClientConVar("ph_classes_hud",          "1", true, false, "Affiche la card de classe dans le HUD")
CreateClientConVar("ph_classes_bind_hinted",  "0", true, false, "Interne : true si le bind F a été proposé")

-- Concommand d'activation
concommand.Add("ph_class_ability", function()
    net.Start("ph_class_use")
    net.SendToServer()
end)

-- Bind F par défaut (une seule fois)
hook.Add("InitPostEntity", "PH_Classes_DefaultBind", function()
    if GetConVar("ph_classes_bind_hinted"):GetBool() then return end
    if not input.LookupBinding("ph_class_ability") then
        RunConsoleCommand("bind", "f", "ph_class_ability")
    end
    RunConsoleCommand("ph_classes_bind_hinted", "1")
end)

-- ============================================================================
-- État local des effets visuels
-- ============================================================================

local Effects = {
    -- kind -> { source, pos, radius, duration, start }
}

local function addEffect(kind, data)
    data.kind = kind
    data.start = CurTime()
    Effects[kind .. "_" .. (IsValid(data.source) and data.source:EntIndex() or 0)] = data
end

local function pruneEffects()
    local t = CurTime()
    for k, e in pairs(Effects) do
        if e.duration and t > e.start + e.duration then
            Effects[k] = nil
        end
    end
end

-- ============================================================================
-- Réception net
-- ============================================================================

net.Receive("ph_class_effect", function()
    local kind = net.ReadString()
    local source = net.ReadEntity()
    local pos = net.ReadVector()
    local radius = net.ReadFloat()
    local duration = net.ReadFloat()
    addEffect(kind, {source = source, pos = pos, radius = radius, duration = duration > 0 and duration or 2})
end)

net.Receive("ph_class_warning", function()
    local kind = net.ReadString()
    if kind == "tracker" then
        chat.AddText(Color(255, 60, 60), "⚠  Tu as été repéré par un chasseur !")
        surface.PlaySound("buttons/button10.wav")
        -- Flash rouge via overlay
        addEffect("warning_flash", {pos = vector_origin, duration = 0.5})
    end
end)

-- Menu d'ouverture (relayé vers cl_class_select)
net.Receive("ph_class_open_menu", function()
    if PH.OpenClassSelect then PH.OpenClassSelect() end
end)

-- ============================================================================
-- HUD card de classe
-- ============================================================================

surface.CreateFont("PHClassTitle", {font = "Roboto", size = 18, weight = 700, antialias = true})
surface.CreateFont("PHClassDesc",  {font = "Roboto", size = 13, weight = 400, antialias = true})
surface.CreateFont("PHClassHint",  {font = "Roboto", size = 12, weight = 600, antialias = true})

local function drawClassCard()
    if not GetConVar("ph_classes_hud"):GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local def = PH.GetClass(ply)
    if not def then return end

    local w, h = 260, 72
    local x, y = 16, ScrH() - 180
    local accent = PH.TeamAccent[ply:Team()] or color_white
    local used = PH.AbilityUsed(ply)

    -- Fond
    surface.SetDrawColor(18, 18, 22, 220)
    surface.DrawRect(x, y, w, h)
    -- Bordure gauche couleur d'équipe
    surface.SetDrawColor(accent)
    surface.DrawRect(x, y, 4, h)
    -- Bordure fine
    surface.SetDrawColor(255, 255, 255, 20)
    surface.DrawOutlinedRect(x, y, w, h, 1)

    -- Titre
    draw.SimpleText(def.name, "PHClassTitle", x + 14, y + 8, color_white)

    -- Description courte
    draw.SimpleText(def.desc, "PHClassDesc", x + 14, y + 30, Color(180, 180, 190))

    -- État
    local statusColor = used and Color(120, 120, 120) or Color(90, 220, 120)
    local statusText = used and "● UTILISÉ" or "● PRÊT"
    draw.SimpleText(statusText, "PHClassHint", x + 14, y + 52, statusColor)

    -- Hint bind
    local bind = input.LookupBinding("ph_class_ability") or "F"
    draw.SimpleText(string.format("[%s] activer", string.upper(bind)), "PHClassHint",
        x + w - 14, y + 52, Color(200, 200, 210, 200), TEXT_ALIGN_RIGHT)
end

hook.Add("HUDPaint", "PH_ClassHUD", function()
    pruneEffects()
    drawClassCard()
end)

-- ============================================================================
-- Effets visuels : halo scout, dôme demolition/sweeper, flash ghost, warning
-- ============================================================================

-- Halo des props "scoutés" (scout, demolition, tracker)
hook.Add("PreDrawHalos", "PH_Classes_Halos", function()
    local t = CurTime()
    local scoutedProps = {}
    local trackedProps = {}
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) and ply:IsProp() and ply:Alive() then
            if ply:GetNWFloat("ph_scouted_until", 0) > t then
                scoutedProps[#scoutedProps + 1] = ply
                local dent = ply:GetNWEntity("disguiseEntity")
                if IsValid(dent) then scoutedProps[#scoutedProps + 1] = dent end
            end
            if ply:GetNWFloat("ph_tracked_until", 0) > t then
                trackedProps[#trackedProps + 1] = ply
                local dent = ply:GetNWEntity("disguiseEntity")
                if IsValid(dent) then trackedProps[#trackedProps + 1] = dent end
            end
        end
    end
    if #scoutedProps > 0 then
        halo.Add(scoutedProps, Color(255, 220, 60), 3, 3, 2, true, true)
    end
    if #trackedProps > 0 then
        halo.Add(trackedProps, Color(60, 200, 255), 3, 3, 2, true, true)
    end
end)

-- Dôme Demolition / Sweeper (uniquement pour le hunter qui a activé)
hook.Add("PostDrawTranslucentRenderables", "PH_Classes_Domes", function()
    local t = CurTime()
    for _, e in pairs(Effects) do
        if (e.kind == "demolition_pulse" or e.kind == "sweeper_pulse") and IsValid(e.source) and e.source == LocalPlayer() then
            local progress = (t - e.start) / e.duration
            local alpha = 255 * (1 - progress)
            local col = e.kind == "demolition_pulse" and Color(80, 200, 255, alpha) or Color(200, 80, 255, alpha)
            render.SetColorMaterial()
            render.DrawWireframeSphere(e.pos, e.radius, 24, 16, col, true)
        end
    end
end)

-- Flash d'écran (warning tracker)
hook.Add("HUDPaint", "PH_Classes_Flash", function()
    local f = Effects["warning_flash_0"]
    if f then
        local a = 120 * (1 - (CurTime() - f.start) / f.duration)
        if a > 0 then
            surface.SetDrawColor(255, 40, 40, a)
            surface.DrawRect(0, 0, ScrW(), ScrH())
        end
    end
end)
