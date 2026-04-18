-- Menu Paramètres Prop Hunt — refonte sidebar + content.
-- Live-apply : chaque contrôle met à jour sa ConVar directement, pas de bouton
-- Apply. Reset d'onglet uniquement (pas de reset global destructif).

local ModernSettings = {}
local settingsMenu

-- ============================================================================
-- Couleurs / polices
-- ============================================================================

local COL_BG        = Color(22, 22, 27, 250)
local COL_SIDEBAR   = Color(16, 16, 20, 255)
local COL_CARD      = Color(34, 34, 40, 255)
local COL_CARD_HOV  = Color(42, 42, 50, 255)
local COL_TEXT      = Color(235, 235, 240)
local COL_SUB       = Color(160, 160, 170)
local COL_DIM       = Color(100, 100, 110)
local COL_MODIFIED  = Color(240, 170, 60)

surface.CreateFont("PHSettingsTitle",   {font = "Roboto", size = 24, weight = 700, antialias = true})
surface.CreateFont("PHSettingsTab",     {font = "Roboto", size = 15, weight = 600, antialias = true})
surface.CreateFont("PHSettingsLabel",   {font = "Roboto", size = 15, weight = 600, antialias = true})
surface.CreateFont("PHSettingsDesc",    {font = "Roboto", size = 12, weight = 400, antialias = true})
surface.CreateFont("PHSettingsValue",   {font = "Roboto", size = 14, weight = 600, antialias = true})
surface.CreateFont("PHSettingsSmall",   {font = "Roboto", size = 11, weight = 400, antialias = true})

-- ============================================================================
-- Catégories & paramètres
-- ============================================================================

local function classSettings()
    local list = {
        {name = "ph_classes_enabled",    type = "bool", label = "Système de classes activé", help = "Active le système global de classes"},
        {name = "ph_classes_auto_assign",type = "bool", label = "Assignation auto si pas de pick", help = "Attribue une classe aléatoire aux joueurs qui n'ont pas choisi"},
        {name = "ph_classes_hud",        type = "bool", label = "Afficher la card HUD", help = "Affiche la card de classe en jeu"},
    }
    local classIds = {"medic", "ghost", "decoy", "jumper", "scout", "tracker", "demolition", "sweeper"}
    for _, id in ipairs(classIds) do
        list[#list + 1] = {name = "ph_class_" .. id, type = "bool",
            label = "Activer " .. id:sub(1,1):upper() .. id:sub(2),
            help = "Rend la classe disponible dans le menu de sélection"}
    end
    -- Balance
    local balance = {
        {name = "ph_class_medic_heal",         type = "int",   label = "Medic : heal (HP)",          min = 10, max = 100},
        {name = "ph_class_ghost_duration",     type = "float", label = "Ghost : durée (s)",           min = 1,  max = 6,    decimals = 1},
        {name = "ph_class_decoy_duration",     type = "int",   label = "Decoy : durée clone (s)",     min = 5,  max = 30},
        {name = "ph_class_jumper_min_range",   type = "int",   label = "Jumper : portée min",         min = 200,max = 800},
        {name = "ph_class_jumper_max_range",   type = "int",   label = "Jumper : portée max",         min = 500,max = 1500},
        {name = "ph_class_scout_cone_deg",     type = "int",   label = "Scout : angle cône (°)",      min = 30, max = 120},
        {name = "ph_class_scout_range",        type = "int",   label = "Scout : portée",              min = 500,max = 3000},
        {name = "ph_class_tracker_warn_delay", type = "float", label = "Tracker : délai warning (s)", min = 0.2,max = 3,    decimals = 1},
        {name = "ph_class_demolition_radius",  type = "int",   label = "Demolition : rayon",          min = 200,max = 800},
        {name = "ph_class_sweeper_radius",     type = "int",   label = "Sweeper : rayon",             min = 300,max = 1200},
        {name = "ph_class_sweeper_percent",    type = "int",   label = "Sweeper : % supprimés",       min = 10, max = 80},
        {name = "ph_class_sweeper_cap",        type = "int",   label = "Sweeper : cap max",           min = 5,  max = 60},
    }
    for _, s in ipairs(balance) do list[#list + 1] = s end
    return list
end

ModernSettings.Categories = {
    {
        name = "Général", color = Color(52, 152, 219),
        settings = {
            {name = "ph_roundlimit",     type = "int", label = "Nombre de rounds",         min = 1, max = 50, help = "Rounds avant vote de carte"},
            {name = "ph_roundtime",      type = "int", label = "Durée des rounds (s)",      min = 0, max = 300, help = "0 = automatique"},
            {name = "ph_mapstartwait",   type = "int", label = "Attente avant début (s)",   min = 0, max = 120},
            {name = "ph_hidingtime",     type = "int", label = "Temps de cachette (s)",     min = 0, max = 120},
            {name = "ph_postroundtime",  type = "int", label = "Temps post-round (s)",      min = 2, max = 60},
            {name = "ph_map_time_limit", type = "int", label = "Limite temps carte (min)",  min = -1, max = 120, help = "-1 = désactivé"},
        },
    },
    {
        name = "Équipes", color = Color(46, 204, 113),
        settings = {
            {name = "ph_auto_team_balance",     type = "bool", label = "Équilibrage automatique"},
            {name = "ph_nb_hunter",             type = "int",  label = "Nombre de chasseurs", min = 1, max = 10, help = "Utilisé si équilibrage désactivé"},
            {name = "ph_props_onwinstayprops",  type = "bool", label = "Props restent props en cas de victoire"},
            {name = "ph_dead_canroam",          type = "bool", label = "Spectateur libre pour les morts"},
        },
    },
    {
        name = "Chasseurs", color = Color(231, 76, 60),
        settings = {
            {name = "ph_hunter_dmgpenalty",    type = "int",  label = "Dégâts mauvais tir", min = 0, max = 100},
            {name = "ph_hunter_smggrenades",   type = "int",  label = "Grenades SMG",       min = 0, max = 5},
            {name = "ph_hunter_deaf_onhiding", type = "bool", label = "Sourds pendant la cachette"},
            {name = "ph_hunter_aim_laser",     type = "int",  label = "Laser visibilité",   min = 0, max = 2, help = "0=nul, 1=spec, 2=props+spec"},
        },
    },
    {
        name = "Props", color = Color(155, 89, 182),
        settings = {
            {name = "ph_props_small_size",               type = "int",   label = "Pénalité petite taille", min = 0, max = 1000},
            {name = "ph_props_jumppower",                type = "float", label = "Puissance de saut",      min = 0, max = 5, decimals = 2},
            {name = "ph_props_camdistance",              type = "float", label = "Distance caméra",         min = 0, max = 5, decimals = 2},
            {name = "ph_props_silent_footsteps",         type = "bool",  label = "Pas silencieux"},
            {name = "ph_props_tpose",                    type = "bool",  label = "T-pose"},
            {name = "ph_props_undisguised_thirdperson",  type = "bool",  label = "3ème personne non déguisé"},
            {name = "ph_random_prop_mode",               type = "bool",  label = "Mode random prop"},
            {name = "ph_random_prop_limit",              type = "int",   label = "Limite random props",    min = 0, max = 10},
        },
    },
    {
        name = "Audio & Voix", color = Color(241, 196, 15),
        settings = {
            {name = "ph_voice_hearotherteam",  type = "bool", label = "Entendre l'autre équipe"},
            {name = "ph_voice_heardead",       type = "bool", label = "Entendre les morts"},
            {name = "ph_audio_spatial_enabled",type = "bool", label = "Spatialisation audio 3D", help = "Applique occlusion et indices de verticalité"},
            {name = "ph_audio_debug",          type = "bool", label = "Debug audio"},
        },
    },
    {
        name = "Taunts", color = Color(230, 126, 34),
        settings = {
            {name = "ph_taunt_menu_phrase",    type = "string", label = "Phrase du menu taunt"},
            {name = "ph_auto_taunt",           type = "bool",   label = "Taunts automatiques"},
            {name = "ph_auto_taunt_delay_min", type = "int",    label = "Délai min auto (s)", min = 0, max = 300},
            {name = "ph_auto_taunt_delay_max", type = "int",    label = "Délai max auto (s)", min = 0, max = 300},
            {name = "ph_auto_taunt_props_only",type = "bool",   label = "Auto-taunt props seulement"},
        },
    },
    {
        name = "Classes", color = Color(200, 100, 255),
        settings = classSettings(),
    },
    {
        name = "Avancé", color = Color(149, 165, 166),
        settings = {
            {name = "ph_secrets", type = "bool", label = "Secrets activés"},
        },
    },
}

-- ============================================================================
-- Helpers de dessin
-- ============================================================================

local function drawRoundedRect(x, y, w, h, r, col)
    draw.RoundedBox(r, x, y, w, h, col)
end

local function isModified(setting)
    local cv = GetConVar(setting.name)
    if not cv then return false end
    return cv:GetString() ~= cv:GetDefault()
end

-- ============================================================================
-- Construction d'une card de paramètre
-- ============================================================================

local function buildCard(parent, setting, accent)
    local card = vgui.Create("DPanel", parent)
    card:Dock(TOP)
    card:DockMargin(0, 0, 0, 8)
    card:SetTall(62)

    card.Paint = function(self, w, h)
        surface.SetDrawColor(self:IsHovered() and COL_CARD_HOV or COL_CARD)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(accent)
        surface.DrawRect(0, 0, 3, h)

        -- Dot orange si modifié
        if isModified(setting) then
            surface.SetDrawColor(COL_MODIFIED)
            surface.DrawRect(14, h / 2 - 3, 6, 6)
        end

        local labelX = isModified(setting) and 28 or 18
        draw.SimpleText(setting.label, "PHSettingsLabel", labelX, 10, COL_TEXT)
        if setting.help then
            draw.SimpleText(setting.help, "PHSettingsDesc", labelX, 34, COL_SUB)
        end
    end

    local cv = GetConVar(setting.name)
    if not cv then
        local warn = vgui.Create("DLabel", card)
        warn:Dock(RIGHT)
        warn:SetWide(240)
        warn:SetText("(ConVar introuvable)")
        warn:SetFont("PHSettingsSmall")
        warn:SetTextColor(Color(220, 80, 80))
        return card
    end

    if setting.type == "bool" then
        local cb = vgui.Create("DCheckBox", card)
        cb:SetSize(44, 22)
        cb:SetPos(0, 0) -- repositionné dans PerformLayout
        cb:SetConVar(setting.name)
        cb.Paint = function(self, w, h)
            local on = self:GetChecked()
            surface.SetDrawColor(on and accent or Color(70, 70, 80))
            draw.RoundedBox(h / 2, 0, 0, w, h, on and accent or Color(60, 60, 70))
            local knobX = on and (w - h + 2) or 2
            draw.RoundedBox(h / 2 - 2, knobX, 2, h - 4, h - 4, Color(240, 240, 245))
        end
        card.PerformLayout = function(self, w, h)
            cb:SetPos(w - cb:GetWide() - 16, (h - cb:GetTall()) / 2)
        end

    elseif setting.type == "int" or setting.type == "float" then
        local slider = vgui.Create("DNumSlider", card)
        slider:SetSize(280, 40)
        slider:SetMin(setting.min or 0)
        slider:SetMax(setting.max or 100)
        slider:SetDecimals(setting.type == "float" and (setting.decimals or 2) or 0)
        slider:SetConVar(setting.name)
        slider:SetText("")
        -- Cacher le label built-in
        slider.Label:SetVisible(false)
        -- Slider custom paint
        if slider.Slider and slider.Slider.Paint then
            slider.Slider.Paint = function(self, w, h)
                surface.SetDrawColor(40, 40, 48)
                draw.RoundedBox(3, 0, h / 2 - 3, w, 6, Color(40, 40, 48))
                local frac = (slider:GetValue() - slider:GetMin()) / math.max(slider:GetMax() - slider:GetMin(), 0.0001)
                draw.RoundedBox(3, 0, h / 2 - 3, w * frac, 6, accent)
            end
            if slider.Slider.Knob then
                slider.Slider.Knob.Paint = function(self, w, h)
                    draw.RoundedBox(h / 2, 0, 0, w, h, Color(240, 240, 245))
                end
            end
        end
        if slider.TextArea then
            slider.TextArea:SetTextColor(COL_TEXT)
            slider.TextArea:SetFont("PHSettingsValue")
            slider.TextArea.Paint = function(self, w, h)
                surface.SetDrawColor(12, 12, 16)
                draw.RoundedBox(4, 0, 0, w, h, Color(12, 12, 16))
                self:DrawTextEntryText(COL_TEXT, Color(100, 100, 120), COL_TEXT)
            end
        end
        card.PerformLayout = function(self, w, h)
            slider:SetPos(w - slider:GetWide() - 16, (h - slider:GetTall()) / 2)
        end

    elseif setting.type == "string" then
        local entry = vgui.Create("DTextEntry", card)
        entry:SetSize(260, 28)
        entry:SetText(cv:GetString())
        entry:SetFont("PHSettingsValue")
        entry.OnEnter = function(self) RunConsoleCommand(setting.name, self:GetValue()) end
        entry.OnFocusChanged = function(self, lost) if lost then RunConsoleCommand(setting.name, self:GetValue()) end end
        entry.Paint = function(self, w, h)
            surface.SetDrawColor(12, 12, 16)
            draw.RoundedBox(4, 0, 0, w, h, Color(12, 12, 16))
            surface.SetDrawColor(accent.r, accent.g, accent.b, 120)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            self:DrawTextEntryText(COL_TEXT, Color(100, 100, 120), COL_TEXT)
        end
        card.PerformLayout = function(self, w, h)
            entry:SetPos(w - entry:GetWide() - 16, (h - entry:GetTall()) / 2)
        end
    end

    card._setting = setting
    return card
end

-- ============================================================================
-- Fenêtre principale
-- ============================================================================

function ModernSettings:CreateMenu()
    if IsValid(settingsMenu) then settingsMenu:Remove() end

    settingsMenu = vgui.Create("DFrame")
    settingsMenu:SetSize(math.min(ScrW() - 100, 980), math.min(ScrH() - 80, 720))
    settingsMenu:Center()
    settingsMenu:SetTitle("")
    settingsMenu:ShowCloseButton(false)
    settingsMenu:MakePopup()
    settingsMenu:SetDraggable(true)

    settingsMenu.Paint = function(self, w, h)
        surface.SetDrawColor(COL_BG)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(52, 152, 219, 180)
        surface.DrawRect(0, 0, w, 3)
        draw.SimpleText("Paramètres Prop Hunt", "PHSettingsTitle", 24, 18, COL_TEXT)
    end

    -- Bouton fermer
    local closeBtn = vgui.Create("DButton", settingsMenu)
    closeBtn:SetSize(32, 32)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        surface.SetDrawColor(self:IsHovered() and Color(220, 80, 80) or Color(60, 60, 70))
        draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(220, 80, 80) or Color(60, 60, 70))
        draw.SimpleText("×", "PHSettingsTitle", w / 2, h / 2 - 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() settingsMenu:Close() end

    settingsMenu.OnSizeChanged = function(self, w, h)
        closeBtn:SetPos(w - 40, 14)
    end
    closeBtn:SetPos(settingsMenu:GetWide() - 40, 14)

    -- Sidebar
    local sidebar = vgui.Create("DPanel", settingsMenu)
    sidebar:SetWide(210)
    sidebar:Dock(LEFT)
    sidebar:DockMargin(0, 56, 0, 0)
    sidebar.Paint = function(self, w, h)
        surface.SetDrawColor(COL_SIDEBAR)
        surface.DrawRect(0, 0, w, h)
    end

    -- Search
    local searchEntry = vgui.Create("DTextEntry", sidebar)
    searchEntry:Dock(TOP)
    searchEntry:DockMargin(12, 12, 12, 8)
    searchEntry:SetTall(30)
    searchEntry:SetFont("PHSettingsValue")
    searchEntry:SetPlaceholderText("Rechercher…")
    searchEntry.Paint = function(self, w, h)
        surface.SetDrawColor(12, 12, 16)
        draw.RoundedBox(4, 0, 0, w, h, Color(12, 12, 16))
        self:DrawTextEntryText(COL_TEXT, Color(100, 100, 120), COL_TEXT)
    end

    -- Content host
    local content = vgui.Create("DScrollPanel", settingsMenu)
    content:Dock(FILL)
    content:DockMargin(16, 56, 16, 56)
    local sbar = content:GetVBar()
    sbar:SetWide(6)
    sbar.Paint = function(s, w, h) surface.SetDrawColor(20, 20, 24) surface.DrawRect(0, 0, w, h) end
    sbar.btnGrip.Paint = function(s, w, h) draw.RoundedBox(3, 0, 0, w, h, Color(80, 80, 90)) end
    sbar.btnUp:SetSize(0, 0) sbar.btnDown:SetSize(0, 0)

    local currentCategory = self.Categories[1]
    local currentCards = {}

    local function renderCategory(cat, filter)
        currentCategory = cat
        content:Clear()
        currentCards = {}
        filter = (filter or ""):lower()

        local header = vgui.Create("DPanel", content)
        header:Dock(TOP)
        header:DockMargin(0, 0, 0, 14)
        header:SetTall(38)
        header.Paint = function(self, w, h)
            draw.SimpleText(cat.name, "PHSettingsTitle", 0, 4, COL_TEXT)
            surface.SetDrawColor(cat.color)
            surface.DrawRect(0, h - 2, 40, 2)
        end

        for _, s in ipairs(cat.settings) do
            local match = filter == "" or s.label:lower():find(filter, 1, true) or (s.help and s.help:lower():find(filter, 1, true))
            if match then
                local c = buildCard(content, s, cat.color)
                currentCards[#currentCards + 1] = c
            end
        end

        if #currentCards == 0 then
            local nope = vgui.Create("DLabel", content)
            nope:Dock(TOP)
            nope:DockMargin(0, 20, 0, 0)
            nope:SetFont("PHSettingsDesc")
            nope:SetText("Aucun paramètre ne correspond.")
            nope:SetTextColor(COL_DIM)
        end
    end

    searchEntry.OnChange = function(self)
        renderCategory(currentCategory, self:GetValue())
    end

    -- Liste des catégories
    local catList = vgui.Create("DPanel", sidebar)
    catList:Dock(FILL)
    catList.Paint = function() end

    local tabButtons = {}
    for _, cat in ipairs(self.Categories) do
        local btn = vgui.Create("DButton", catList)
        btn:Dock(TOP)
        btn:DockMargin(8, 0, 8, 2)
        btn:SetTall(34)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local active = (currentCategory == cat)
            if active then
                surface.SetDrawColor(cat.color.r, cat.color.g, cat.color.b, 40)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(cat.color)
                surface.DrawRect(0, 0, 3, h)
            elseif self:IsHovered() then
                surface.SetDrawColor(40, 40, 50)
                surface.DrawRect(0, 0, w, h)
            end
            draw.SimpleText(cat.name, "PHSettingsTab", 14, h / 2, active and COL_TEXT or COL_SUB, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            searchEntry:SetText("")
            renderCategory(cat, "")
        end
        tabButtons[#tabButtons + 1] = btn
    end

    -- Footer : Reset tab + Close
    local footer = vgui.Create("DPanel", settingsMenu)
    footer:Dock(BOTTOM)
    footer:DockMargin(16, 8, 16, 12)
    footer:SetTall(36)
    footer.Paint = function() end

    local reset = vgui.Create("DButton", footer)
    reset:Dock(LEFT)
    reset:SetWide(200)
    reset:SetText("")
    reset.Paint = function(self, w, h)
        local c = self:IsHovered() and Color(70, 70, 80) or Color(40, 40, 48)
        draw.RoundedBox(4, 0, 0, w, h, c)
        draw.SimpleText("Restaurer les défauts de cet onglet", "PHSettingsTab", w / 2, h / 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    reset.DoClick = function()
        Derma_Query(
            string.format("Restaurer les valeurs par défaut de l'onglet '%s' ?", currentCategory.name),
            "Confirmation",
            "Oui", function()
                for _, s in ipairs(currentCategory.settings) do
                    local cv = GetConVar(s.name)
                    if cv then RunConsoleCommand(s.name, cv:GetDefault()) end
                end
                renderCategory(currentCategory, searchEntry:GetValue())
            end,
            "Non"
        )
    end

    local close = vgui.Create("DButton", footer)
    close:Dock(RIGHT)
    close:SetWide(120)
    close:SetText("")
    close.Paint = function(self, w, h)
        local c = self:IsHovered() and Color(60, 130, 200) or Color(52, 152, 219)
        draw.RoundedBox(4, 0, 0, w, h, c)
        draw.SimpleText("Fermer", "PHSettingsTab", w / 2, h / 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close.DoClick = function() settingsMenu:Close() end

    -- Init
    renderCategory(self.Categories[1], "")
    return settingsMenu
end

function ModernSettings:ToggleMenu()
    if not IsValid(settingsMenu) then
        self:CreateMenu()
    else
        settingsMenu:SetVisible(not settingsMenu:IsVisible())
        if settingsMenu:IsVisible() then settingsMenu:MakePopup() end
    end
end

_G.ModernSettings = ModernSettings

net.Receive("ph_openhelpmenu", function() ModernSettings:ToggleMenu() end)
