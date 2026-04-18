-- Panel de sélection de classe — affiché en début de ROUND_HIDE.

PH = PH or {}
local menu

local COL_BG        = Color(18, 18, 22, 240)
local COL_CARD      = Color(34, 34, 40, 255)
local COL_CARD_HOV  = Color(48, 48, 58, 255)
local COL_TAKEN     = Color(28, 28, 32, 200)
local COL_TEXT      = Color(235, 235, 240)
local COL_SUB       = Color(170, 170, 180)
local COL_DIM       = Color(110, 110, 120)

surface.CreateFont("PHSelectTitle",  {font = "Roboto", size = 28, weight = 700, antialias = true})
surface.CreateFont("PHSelectCard",   {font = "Roboto", size = 20, weight = 700, antialias = true})
surface.CreateFont("PHSelectDesc",   {font = "Roboto", size = 13, weight = 400, antialias = true})
surface.CreateFont("PHSelectSmall",  {font = "Roboto", size = 12, weight = 400, antialias = true})

local function sendPick(id)
    net.Start("ph_class_pick")
    net.WriteString(id or "")
    net.SendToServer()
end

local function buildCard(parent, def, accent)
    local card = vgui.Create("DButton", parent)
    card:SetText("")
    card:SetTall(140)
    card:Dock(TOP)
    card:DockMargin(0, 0, 0, 10)

    card.Paint = function(self, w, h)
        local taken = def._taken
        local bg = taken and COL_TAKEN or (self:IsHovered() and COL_CARD_HOV or COL_CARD)
        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, w, h)
        -- Accent
        surface.SetDrawColor(accent.r, accent.g, accent.b, taken and 100 or 255)
        surface.DrawRect(0, 0, 4, h)

        local textCol = taken and COL_DIM or COL_TEXT
        draw.SimpleText(def.name, "PHSelectCard", 18, 12, textCol)

        -- Wrap description (simple, sur 2 lignes)
        draw.DrawText(def.desc, "PHSelectDesc", 18, 46, taken and COL_DIM or COL_SUB, TEXT_ALIGN_LEFT)

        if taken then
            draw.SimpleText("Pris par " .. (def._takenBy or "?"), "PHSelectSmall", 18, h - 22, Color(220, 80, 80))
        elseif self:IsHovered() then
            draw.SimpleText("Cliquer pour choisir", "PHSelectSmall", w - 18, h - 22, accent, TEXT_ALIGN_RIGHT)
        end
    end

    card.DoClick = function()
        if def._taken then return end
        sendPick(def.id)
        if IsValid(menu) then
            menu._picked = true
            menu:Close()
        end
        surface.PlaySound("ui/buttonclickrelease.wav")
    end
end

function PH.OpenClassSelect()
    if IsValid(menu) then menu:Remove() end

    local ply = LocalPlayer()
    if not IsValid(ply) or ply:IsSpectator() then return end

    local team = ply:Team()
    local accent = PH.TeamAccent[team] or Color(255, 255, 255)
    local classes = PH.GetAvailableClasses(team)

    -- Repère les classes prises
    for _, def in ipairs(classes) do
        def._taken = false
        def._takenBy = nil
        for _, p in ipairs(player.GetHumans()) do
            if IsValid(p) and p ~= ply and p:GetNWString("ph_class", "") == def.id then
                def._taken = true
                def._takenBy = p:Nick()
            end
        end
    end

    menu = vgui.Create("DFrame")
    menu:SetSize(520, math.min(ScrH() - 80, 100 + #classes * 150))
    menu:Center()
    menu:SetTitle("")
    menu:ShowCloseButton(false)
    menu:SetDraggable(false)
    menu:MakePopup()

    -- Si le joueur ferme sans choisir, on envoie vanilla pour débloquer le lock serveur
    menu._picked = false
    menu.OnRemove = function()
        if not menu._picked and LocalPlayer():GetNWBool("ph_class_picked", false) == false then
            sendPick("")
        end
    end

    menu.Paint = function(self, w, h)
        surface.SetDrawColor(COL_BG)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(accent)
        surface.DrawRect(0, 0, w, 3)
        draw.SimpleText("Choisis ta classe", "PHSelectTitle", 24, 22, COL_TEXT)
        draw.SimpleText(team == TEAM_PROP and "Camouflage & survie" or "Traque & révélation",
            "PHSelectDesc", 24, 56, COL_SUB)
    end

    local content = vgui.Create("DScrollPanel", menu)
    content:Dock(FILL)
    content:DockMargin(16, 80, 16, 60)

    for _, def in ipairs(classes) do
        buildCard(content, def, accent)
    end

    -- Skip button
    local skip = vgui.Create("DButton", menu)
    skip:SetText("Jouer sans classe")
    skip:SetTall(36)
    skip:Dock(BOTTOM)
    skip:DockMargin(16, 8, 16, 16)
    skip:SetFont("PHSelectSmall")
    skip:SetTextColor(COL_SUB)
    skip.Paint = function(self, w, h)
        local c = self:IsHovered() and Color(60, 60, 70) or Color(40, 40, 48)
        surface.SetDrawColor(c)
        surface.DrawRect(0, 0, w, h)
    end
    skip.DoClick = function()
        sendPick("")
        menu._picked = true
        menu:Close()
    end
end
