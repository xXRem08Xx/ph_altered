-- Système de raccourcis clavier pour l'interface Prop Hunt
-- Permet d'utiliser des raccourcis clavier pour naviguer dans l'interface

local UIShortcuts = {}

-- ConVar d'affichage des raccourcis (évite les nil sur GetConVar)
local cvarShowShortcuts = CreateClientConVar("ph_show_shortcuts", "0", true, false, "Afficher les raccourcis clavier dans le HUD")

-- Configuration des raccourcis
UIShortcuts.Shortcuts = {
    {
        key = KEY_F1,
        name = "Aide",
        description = "Ouvrir l'aide du jeu",
        action = function()
            if ModernSettings then
                ModernSettings:ToggleMenu()
            end
        end
    },
    {
        key = KEY_F2,
        name = "Paramètres",
        description = "Ouvrir les paramètres du serveur",
        action = function()
            if ModernSettings then
                ModernSettings:ToggleMenu()
            end
        end
    },
    {
        key = KEY_F3,
        name = "Taunts",
        description = "Ouvrir le menu des taunts",
        action = function()
            RunConsoleCommand("ph_menu_taunt")
        end
    },
    {
        key = KEY_F4,
        name = "Équipes",
        description = "Changer d'équipe",
        action = function()
            RunConsoleCommand("ph_jointeam")
        end
    },
    {
        key = KEY_F5,
        name = "Debug Audio",
        description = "Basculer le debug audio",
        action = function()
            local current = GetConVar("ph_audio_debug"):GetBool()
            RunConsoleCommand("ph_audio_debug", current and "0" or "1")
            
            if UINotifications then
                UINotifications:Info("Debug Audio", current and "Désactivé" or "Activé", 2)
            end
        end
    },
    {
        key = KEY_F6,
        name = "Thème",
        description = "Changer de thème d'interface",
        action = function()
            if UIThemes then
                local themes = UIThemes.Themes
                local currentIndex = 1
                
                for i, theme in ipairs(themes) do
                    if theme.id == UIThemes.CurrentTheme then
                        currentIndex = i
                        break
                    end
                end
                
                local nextIndex = (currentIndex % #themes) + 1
                local nextTheme = themes[nextIndex]
                
                UIThemes:SetTheme(nextTheme.id)
                
                if UINotifications then
                    UINotifications:Info("Thème", "Changement vers " .. nextTheme.name, 2)
                end
            end
        end
    }
}

-- Fonction pour enregistrer un raccourci
function UIShortcuts:Register(key, name, description, action)
    table.insert(self.Shortcuts, {
        key = key,
        name = name,
        description = description,
        action = action
    })
end

-- Fonction pour supprimer un raccourci
function UIShortcuts:Unregister(key)
    for i, shortcut in ipairs(self.Shortcuts) do
        if shortcut.key == key then
            table.remove(self.Shortcuts, i)
            break
        end
    end
end

-- Fonction pour obtenir un raccourci par touche
function UIShortcuts:GetByKey(key)
    for _, shortcut in ipairs(self.Shortcuts) do
        if shortcut.key == key then
            return shortcut
        end
    end
    return nil
end

-- Fonction pour exécuter un raccourci
function UIShortcuts:Execute(key)
    local shortcut = self:GetByKey(key)
    if shortcut and shortcut.action then
        shortcut.action()
        return true
    end
    return false
end

-- Fonction pour afficher l'aide des raccourcis
function UIShortcuts:ShowHelp()
    if UINotifications then
        for _, shortcut in ipairs(self.Shortcuts) do
            UINotifications:Info("Raccourci", string.format("%s: %s", shortcut.name, shortcut.description), 3)
        end
    end
end

-- Hook pour gérer les touches
hook.Add("PlayerButtonDown", "UIShortcuts_HandleKey", function(ply, button)
    if not IsValid(ply) or ply != LocalPlayer() then return end

    -- Empêche les interférences entre interfaces tout en autorisant la touche liée pour fermer la fenêtre ouverte.
    local shouldBlock = false
    local matchingOpen = false

    if ModernSettings and IsValid(ModernSettings.settingsMenu) and ModernSettings.settingsMenu:IsVisible() then
        if button == KEY_F1 or button == KEY_F2 then
            matchingOpen = true
        else
            shouldBlock = true
        end
    end

    if _G.menu and IsValid(_G.menu) and _G.menu:IsVisible() then
        if button == KEY_F3 then
            matchingOpen = true
        else
            shouldBlock = true
        end
    end

    if matchingOpen or not shouldBlock then
        UIShortcuts:Execute(button)
    end
end)

-- Fonction pour afficher les raccourcis dans le HUD
local function DrawShortcutsHelp()
    if not cvarShowShortcuts:GetBool() then return end
    
    local x = 10
    local y = ScrH() - 200
    
    surface.SetFont("DermaDefault")
    local lineHeight = 20
    
    -- Titre
    draw.SimpleText("Raccourcis clavier:", "DermaDefault", x, y, Color(255, 255, 255), TEXT_ALIGN_LEFT)
    y = y + lineHeight
    
    -- Liste des raccourcis
    for _, shortcut in ipairs(UIShortcuts.Shortcuts) do
        local keyName = input.GetKeyName(shortcut.key)
        local text = string.format("F%d: %s", shortcut.key - KEY_F1 + 1, shortcut.name)
        
        draw.SimpleText(text, "DermaDefault", x, y, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        y = y + lineHeight
    end
end

-- Hook pour dessiner l'aide des raccourcis
hook.Add("HUDPaint", "UIShortcuts_DrawHelp", function()
    if cvarShowShortcuts and cvarShowShortcuts:GetBool() then
        DrawShortcutsHelp()
    end
end)

-- Commande pour afficher l'aide des raccourcis
concommand.Add("ph_shortcuts_help", function()
    UIShortcuts:ShowHelp()
end)

-- Commande pour basculer l'affichage des raccourcis
concommand.Add("ph_toggle_shortcuts", function()
    local current = cvarShowShortcuts:GetBool()
    RunConsoleCommand("ph_show_shortcuts", current and "0" or "1")
    
    if UINotifications then
        UINotifications:Info("Raccourcis", current and "Masqués" or "Affichés", 2)
    end
end)

-- Exporter le module
_G.UIShortcuts = UIShortcuts
