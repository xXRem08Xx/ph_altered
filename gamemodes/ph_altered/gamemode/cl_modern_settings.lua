-- Interface moderne des paramètres Prop Hunt avec onglets par catégorie
-- Remplace l'ancien système d'options basique

local ModernSettings = {}
local settingsMenu = nil

-- Configuration des catégories et paramètres
ModernSettings.Categories = {
    {
        name = "Général",
        icon = "🎮",
        color = Color(52, 152, 219),
        settings = {
            {name = "ph_roundlimit", type = "int", label = "Nombre de rounds", min = 1, max = 50, decimals = 0, help = "Nombre de rounds avant le vote de carte"},
            {name = "ph_roundtime", type = "int", label = "Durée des rounds (sec)", min = 0, max = 300, decimals = 0, help = "Durée limite des rounds (0 = automatique)"},
            {name = "ph_mapstartwait", type = "int", label = "Attente avant début (sec)", min = 0, max = 120, decimals = 0, help = "Temps d'attente avant le début de la carte"},
            {name = "ph_hidingtime", type = "int", label = "Temps de cachette (sec)", min = 0, max = 120, decimals = 0, help = "Temps avant que les chasseurs soient libérés"},
            {name = "ph_postroundtime", type = "int", label = "Temps post-round (sec)", min = 2, max = 60, decimals = 0, help = "Temps avant le round suivant"},
            {name = "ph_map_time_limit", type = "int", label = "Limite de temps de carte (min)", min = -1, max = 120, decimals = 0, help = "Minutes avant le dernier round (-1 = désactivé)"}
        }
    },
    {
        name = "Équipes",
        icon = "👥",
        color = Color(46, 204, 113),
        settings = {
            {name = "ph_auto_team_balance", type = "bool", label = "Équilibrage automatique des équipes", help = "Équilibre automatiquement les équipes"},
            {name = "ph_nb_hunter", type = "int", label = "Nombre de chasseurs", min = 1, max = 10, decimals = 0, help = "Nombre de chasseurs (si équilibrage désactivé)"},
            {name = "ph_props_onwinstayprops", type = "bool", label = "Props restent props en cas de victoire", help = "Les props restent dans leur équipe après une victoire"},
            {name = "ph_dead_canroam", type = "bool", label = "Spectateurs libres", help = "Les joueurs morts peuvent utiliser le mode spectateur libre"}
        }
    },
    {
        name = "Chasseurs",
        icon = "🎯",
        color = Color(231, 76, 60),
        settings = {
            {name = "ph_hunter_dmgpenalty", type = "int", label = "Dégâts pour mauvais tir", min = 0, max = 100, decimals = 0, help = "Dégâts subis pour tirer sur un mauvais prop"},
            {name = "ph_hunter_smggrenades", type = "int", label = "Grenades SMG", min = 0, max = 5, decimals = 0, help = "Nombre de grenades SMG pour les chasseurs"},
            {name = "ph_hunter_deaf_onhiding", type = "bool", label = "Sourds pendant la cachette", help = "Les chasseurs sont sourds pendant la phase de cachette"},
            {name = "ph_hunter_aim_laser", type = "int", label = "Laser de visée", min = 0, max = 2, decimals = 0, help = "Qui peut voir le laser de visée (0=nul, 1=spectateurs, 2=props+spectateurs)"}
        }
    },
    {
        name = "Props",
        icon = "📦",
        color = Color(155, 89, 182),
        settings = {
            {name = "ph_props_small_size", type = "int", label = "Pénalité petite taille", min = 0, max = 1000, decimals = 0, help = "Pénalité de vitesse pour les petits props"},
            {name = "ph_props_jumppower", type = "float", label = "Puissance de saut", min = 0, max = 5, decimals = 2, help = "Bonus de puissance de saut pour les props"},
            {name = "ph_props_camdistance", type = "float", label = "Distance caméra", min = 0, max = 5, decimals = 2, help = "Multiplicateur de distance de caméra pour les props déguisés"},
            {name = "ph_props_silent_footsteps", type = "bool", label = "Pas silencieux", help = "Les props n'émettent pas de sons de pas"},
            {name = "ph_props_tpose", type = "bool", label = "T-pose", help = "Les props sont en T-pose"},
            {name = "ph_props_undisguised_thirdperson", type = "bool", label = "Vue 3ème personne non déguisé", help = "Les props non déguisés sont en vue 3ème personne"},
            {name = "ph_props_random_change", type = "bool", label = "Props aléatoires", help = "Les props changent aléatoirement"},
            {name = "ph_random_prop_limit", type = "int", label = "Limite props aléatoires", min = 0, max = 10, decimals = 0, help = "Nombre de changements de props aléatoires par round"}
        }
    },
    {
        name = "Audio & Voix",
        icon = "🔊",
        color = Color(241, 196, 15),
        settings = {
            {name = "ph_voice_hearotherteam", type = "bool", label = "Entendre l'autre équipe", help = "Permet d'entendre le chat vocal de l'autre équipe"},
            {name = "ph_voice_heardead", type = "bool", label = "Entendre les morts", help = "Permet d'entendre le chat vocal des joueurs morts"},
            {name = "ph_audio_spatialization", type = "bool", label = "Spatialisation audio 3D", help = "Améliore la perception de la hauteur des sons"},
            {name = "ph_audio_debug", type = "bool", label = "Debug audio", help = "Affiche les informations de debug audio"}
        }
    },
    {
        name = "Taunts",
        icon = "🎵",
        color = Color(230, 126, 34),
        settings = {
            {name = "ph_taunt_menu_phrase", type = "string", label = "Phrase du menu taunt", help = "Phrase affichée en haut du menu de taunts"},
            {name = "ph_auto_taunt", type = "bool", label = "Taunts automatiques", help = "Active les taunts automatiques"},
            {name = "ph_auto_taunt_delay_min", type = "int", label = "Délai min taunts auto (sec)", min = 0, max = 300, decimals = 0, help = "Délai minimum entre les taunts automatiques"},
            {name = "ph_auto_taunt_delay_max", type = "int", label = "Délai max taunts auto (sec)", min = 0, max = 300, decimals = 0, help = "Délai maximum entre les taunts automatiques"},
            {name = "ph_auto_taunt_props_only", type = "bool", label = "Taunts auto props seulement", help = "Les taunts automatiques ne s'appliquent qu'aux props"}
        }
    },
    {
        name = "Avancé",
        icon = "⚙️",
        color = Color(149, 165, 166),
        settings = {
            {name = "ph_secrets", type = "bool", label = "Secrets activés", help = "Active les fonctionnalités secrètes"},
            {name = "ph_auto_taunt_delay_min", type = "int", label = "Délai min taunts auto (sec)", min = 0, max = 300, decimals = 0, help = "Délai minimum entre les taunts automatiques"},
            {name = "ph_auto_taunt_delay_max", type = "int", label = "Délai max taunts auto (sec)", min = 0, max = 300, decimals = 0, help = "Délai maximum entre les taunts automatiques"}
        }
    }
}

-- Fonction pour créer le menu moderne
function ModernSettings:CreateMenu()
    if IsValid(settingsMenu) then
        settingsMenu:Remove()
    end

    settingsMenu = vgui.Create("DFrame")
    settingsMenu:SetSize(ScrW() * 0.7, ScrH() * 0.8)
    settingsMenu:Center()
    settingsMenu:MakePopup()
    settingsMenu:SetKeyboardInputEnabled(false)
    settingsMenu:SetDeleteOnClose(false)
    settingsMenu:ShowCloseButton(true)
    settingsMenu:SetTitle("")
    settingsMenu:SetDraggable(true)

    -- Style moderne du menu
    function settingsMenu:Paint(w, h)
        -- Fond avec dégradé
        local gradient = {}
        for i = 0, h do
            local alpha = 240 - (i / h) * 40
            table.insert(gradient, {x = 0, y = i, w = w, h = 1, color = Color(30, 30, 35, alpha)})
        end
        
        for _, rect in ipairs(gradient) do
            surface.SetDrawColor(rect.color)
            surface.DrawRect(rect.x, rect.y, rect.w, rect.h)
        end

        -- Bordure moderne
        surface.SetDrawColor(52, 152, 219, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        -- Titre avec icône
        surface.SetFont("DermaLarge")
        local titleW, titleH = surface.GetTextSize("⚙️ Paramètres Prop Hunt")
        draw.SimpleText("⚙️ Paramètres Prop Hunt", "DermaLarge", 20, 15, Color(255, 255, 255), TEXT_ALIGN_LEFT)
        
        -- Sous-titre
        surface.SetFont("DermaDefault")
        draw.SimpleText("Configuration avancée du serveur", "DermaDefault", 20, 45, Color(200, 200, 200), TEXT_ALIGN_LEFT)
    end

    -- Créer le système d'onglets
    local tabPanel = vgui.Create("DPropertySheet", settingsMenu)
    tabPanel:Dock(FILL)
    tabPanel:DockMargin(10, 60, 10, 10)
    tabPanel:SetPadding(5)

    -- Style des onglets
    function tabPanel:Paint(w, h)
        surface.SetDrawColor(40, 40, 45, 200)
        surface.DrawRect(0, 0, w, h)
    end

    -- Créer les onglets pour chaque catégorie
    for _, category in ipairs(self.Categories) do
        local categoryPanel = vgui.Create("DPanel")
        categoryPanel:DockPadding(15, 15, 15, 15)

        -- Style du panneau de catégorie
        function categoryPanel:Paint(w, h)
            surface.SetDrawColor(50, 50, 55, 150)
            surface.DrawRect(0, 0, w, h)
        end

        -- Scroll panel pour les paramètres
        local scrollPanel = vgui.Create("DScrollPanel", categoryPanel)
        scrollPanel:Dock(FILL)

        -- Style du scroll panel
        function scrollPanel:Paint(w, h)
            surface.SetDrawColor(60, 60, 65, 100)
            surface.DrawRect(0, 0, w, h)
        end

        -- Créer les contrôles pour chaque paramètre
        local y = 10
        for _, setting in ipairs(category.settings) do
            local controlPanel = vgui.Create("DPanel", scrollPanel)
            controlPanel:SetPos(10, y)
            controlPanel:SetSize(scrollPanel:GetWide() - 20, 60)
            controlPanel:DockMargin(0, 0, 0, 10)

            -- Style du panneau de contrôle
            function controlPanel:Paint(w, h)
                surface.SetDrawColor(70, 70, 75, 120)
                surface.DrawRect(0, 0, w, h)
                
                -- Bordure subtile
                surface.SetDrawColor(category.color.r, category.color.g, category.color.b, 100)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            -- Label du paramètre
            local label = vgui.Create("DLabel", controlPanel)
            label:SetPos(15, 8)
            label:SetSize(controlPanel:GetWide() - 30, 20)
            label:SetText(setting.label)
            label:SetFont("DermaDefault")
            label:SetTextColor(Color(255, 255, 255))

            -- Aide contextuelle
            if setting.help then
                local helpLabel = vgui.Create("DLabel", controlPanel)
                helpLabel:SetPos(15, 25)
                helpLabel:SetSize(controlPanel:GetWide() - 30, 15)
                helpLabel:SetText(setting.help)
                helpLabel:SetFont("DermaDefault")
                helpLabel:SetTextColor(Color(180, 180, 180))
            end

            -- Contrôle selon le type
            if setting.type == "bool" then
                local checkbox = vgui.Create("DCheckBox", controlPanel)
                checkbox:SetPos(controlPanel:GetWide() - 40, 15)
                checkbox:SetConVar(setting.name)
                checkbox:SetSize(20, 20)

                -- Style personnalisé pour la checkbox
                function checkbox:Paint(w, h)
                    local checked = self:GetChecked()
                    surface.SetDrawColor(checked and category.color or Color(100, 100, 100))
                    surface.DrawRect(0, 0, w, h)
                    
                    if checked then
                        surface.SetDrawColor(255, 255, 255)
                        surface.DrawRect(2, 2, w-4, h-4)
                    end
                end

            elseif setting.type == "int" or setting.type == "float" then
                local slider = vgui.Create("DNumSlider", controlPanel)
                slider:SetPos(controlPanel:GetWide() - 200, 10)
                slider:SetSize(180, 40)
                slider:SetMin(setting.min or 0)
                slider:SetMax(setting.max or 100)
                slider:SetDecimals(setting.decimals or 0)
                slider:SetConVar(setting.name)
                slider:SetText("")

                -- Style personnalisé pour le slider
                function slider:Paint(w, h)
                    surface.SetDrawColor(80, 80, 85, 150)
                    surface.DrawRect(0, 0, w, h)
                end

            elseif setting.type == "string" then
                local textEntry = vgui.Create("DTextEntry", controlPanel)
                textEntry:SetPos(controlPanel:GetWide() - 200, 15)
                textEntry:SetSize(180, 25)
                textEntry:SetText(GetConVar(setting.name):GetString())
                textEntry:SetFont("DermaDefault")

                textEntry.OnEnter = function(self)
                    RunConsoleCommand(setting.name, self:GetValue())
                end

                -- Style personnalisé pour le text entry
                function textEntry:Paint(w, h)
                    surface.SetDrawColor(40, 40, 45, 200)
                    surface.DrawRect(0, 0, w, h)
                    
                    surface.SetDrawColor(category.color.r, category.color.g, category.color.b, 150)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
            end

            y = y + 70
        end

        -- Ajouter l'onglet
        tabPanel:AddSheet(category.name, categoryPanel, category.icon, false, false, category.help)
    end

    -- Boutons d'action en bas
    local buttonPanel = vgui.Create("DPanel", settingsMenu)
    buttonPanel:Dock(BOTTOM)
    buttonPanel:SetTall(50)
    buttonPanel:DockMargin(10, 0, 10, 10)

    function buttonPanel:Paint(w, h)
        surface.SetDrawColor(40, 40, 45, 200)
        surface.DrawRect(0, 0, w, h)
    end

    -- Bouton Reset
    local resetButton = vgui.Create("DButton", buttonPanel)
    resetButton:SetPos(10, 10)
    resetButton:SetSize(120, 30)
    resetButton:SetText("🔄 Réinitialiser")
    resetButton:SetFont("DermaDefault")

    function resetButton:Paint(w, h)
        local col = self:IsHovered() and Color(231, 76, 60) or Color(52, 152, 219)
        surface.SetDrawColor(col.r, col.g, col.b, 200)
        surface.DrawRect(0, 0, w, h)
        
        surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    function resetButton:DoClick()
        Derma_Query("Êtes-vous sûr de vouloir réinitialiser tous les paramètres ?", "Confirmation", "Oui", function()
            -- Réinitialiser tous les paramètres
            for _, category in ipairs(ModernSettings.Categories) do
                for _, setting in ipairs(category.settings) do
                    local convar = GetConVar(setting.name)
                    if convar then
                        RunConsoleCommand(setting.name, convar:GetDefault())
                    end
                end
            end
            settingsMenu:Close()
        end, "Non")
    end

    -- Bouton Appliquer
    local applyButton = vgui.Create("DButton", buttonPanel)
    applyButton:SetPos(buttonPanel:GetWide() - 130, 10)
    applyButton:SetSize(120, 30)
    applyButton:SetText("✅ Appliquer")
    applyButton:SetFont("DermaDefault")

    function applyButton:Paint(w, h)
        local col = self:IsHovered() and Color(46, 204, 113) or Color(52, 152, 219)
        surface.SetDrawColor(col.r, col.g, col.b, 200)
        surface.DrawRect(0, 0, w, h)
        
        surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    function applyButton:DoClick()
        -- Les changements sont appliqués automatiquement via les ConVars
        settingsMenu:Close()
    end

    return settingsMenu
end

-- Fonction pour ouvrir/fermer le menu
function ModernSettings:ToggleMenu()
    if not IsValid(settingsMenu) then
        self:CreateMenu()
    end
    settingsMenu:SetVisible(not settingsMenu:IsVisible())
end

-- Exporter le module
_G.ModernSettings = ModernSettings

-- Remplacer l'ancien système
local function toggleHelpMenu()
    ModernSettings:ToggleMenu()
end

-- Remplacer la réception du réseau
net.Receive("ph_openhelpmenu", toggleHelpMenu)
