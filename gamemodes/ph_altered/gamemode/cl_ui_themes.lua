-- Système de thèmes pour l'interface moderne Prop Hunt
-- Permet de personnaliser l'apparence de l'interface

local UIThemes = {}

-- Thèmes disponibles
UIThemes.Themes = {
    {
        name = "Dark Modern",
        id = "dark_modern",
        colors = {
            primary = Color(52, 152, 219),
            secondary = Color(46, 204, 113),
            accent = Color(231, 76, 60),
            background = Color(30, 30, 35),
            surface = Color(40, 40, 45),
            text = Color(255, 255, 255),
            textSecondary = Color(200, 200, 200),
            border = Color(60, 60, 65)
        }
    },
    {
        name = "Light Modern",
        id = "light_modern",
        colors = {
            primary = Color(52, 152, 219),
            secondary = Color(46, 204, 113),
            accent = Color(231, 76, 60),
            background = Color(245, 245, 250),
            surface = Color(255, 255, 255),
            text = Color(30, 30, 35),
            textSecondary = Color(100, 100, 100),
            border = Color(220, 220, 225)
        }
    },
    {
        name = "Gaming",
        id = "gaming",
        colors = {
            primary = Color(155, 89, 182),
            secondary = Color(241, 196, 15),
            accent = Color(231, 76, 60),
            background = Color(20, 20, 25),
            surface = Color(35, 35, 40),
            text = Color(255, 255, 255),
            textSecondary = Color(180, 180, 180),
            border = Color(80, 80, 85)
        }
    },
    {
        name = "Minimal",
        id = "minimal",
        colors = {
            primary = Color(52, 73, 94),
            secondary = Color(46, 204, 113),
            accent = Color(231, 76, 60),
            background = Color(250, 250, 250),
            surface = Color(255, 255, 255),
            text = Color(50, 50, 50),
            textSecondary = Color(120, 120, 120),
            border = Color(200, 200, 200)
        }
    }
}

-- Thème actuel
UIThemes.CurrentTheme = "dark_modern"

-- Fonction pour obtenir le thème actuel
function UIThemes:GetCurrentTheme()
    for _, theme in ipairs(self.Themes) do
        if theme.id == self.CurrentTheme then
            return theme
        end
    end
    return self.Themes[1] -- Fallback vers le premier thème
end

-- Fonction pour changer de thème
function UIThemes:SetTheme(themeId)
    for _, theme in ipairs(self.Themes) do
        if theme.id == themeId then
            self.CurrentTheme = themeId
            return true
        end
    end
    return false
end

-- Fonction pour obtenir une couleur du thème actuel
function UIThemes:GetColor(colorName)
    local theme = self:GetCurrentTheme()
    return theme.colors[colorName] or Color(255, 255, 255)
end

-- Fonction pour dessiner un bouton moderne
function UIThemes:DrawModernButton(panel, w, h, text, isHovered, isPressed)
    local theme = self:GetCurrentTheme()
    local col = theme.colors.primary
    
    if isPressed then
        col = theme.colors.accent
    elseif isHovered then
        col = theme.colors.secondary
    end
    
    -- Fond avec dégradé
    surface.SetDrawColor(col.r, col.g, col.b, 200)
    surface.DrawRect(0, 0, w, h)
    
    -- Bordure
    surface.SetDrawColor(theme.colors.border.r, theme.colors.border.g, theme.colors.border.b, 150)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    
    -- Texte
    surface.SetFont("DermaDefault")
    local textW, textH = surface.GetTextSize(text)
    draw.SimpleText(text, "DermaDefault", w/2, h/2, theme.colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Fonction pour dessiner un panneau moderne
function UIThemes:DrawModernPanel(panel, w, h, hasBorder)
    local theme = self:GetCurrentTheme()
    
    -- Fond
    surface.SetDrawColor(theme.colors.surface.r, theme.colors.surface.g, theme.colors.surface.b, 200)
    surface.DrawRect(0, 0, w, h)
    
    -- Bordure optionnelle
    if hasBorder then
        surface.SetDrawColor(theme.colors.border.r, theme.colors.border.g, theme.colors.border.b, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
end

-- Fonction pour dessiner un slider moderne
function UIThemes:DrawModernSlider(panel, w, h, value, min, max)
    local theme = self:GetCurrentTheme()
    
    -- Fond du slider
    surface.SetDrawColor(theme.colors.surface.r, theme.colors.surface.g, theme.colors.surface.b, 150)
    surface.DrawRect(0, 0, w, h)
    
    -- Barre de progression
    local progress = (value - min) / (max - min)
    local barW = w * progress
    
    surface.SetDrawColor(theme.colors.primary.r, theme.colors.primary.g, theme.colors.primary.b, 200)
    surface.DrawRect(0, 0, barW, h)
    
    -- Bordure
    surface.SetDrawColor(theme.colors.border.r, theme.colors.border.g, theme.colors.border.b, 100)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end

-- Fonction pour dessiner une checkbox moderne
function UIThemes:DrawModernCheckbox(panel, w, h, checked, isHovered)
    local theme = self:GetCurrentTheme()
    
    -- Fond
    local bgColor = checked and theme.colors.primary or theme.colors.surface
    surface.SetDrawColor(bgColor.r, bgColor.g, bgColor.b, 200)
    surface.DrawRect(0, 0, w, h)
    
    -- Bordure
    local borderColor = isHovered and theme.colors.secondary or theme.colors.border
    surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 150)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    -- Checkmark si coché
    if checked then
        surface.SetDrawColor(theme.colors.text.r, theme.colors.text.g, theme.colors.text.b, 255)
        surface.DrawRect(2, 2, w-4, h-4)
    end
end

-- Fonction pour dessiner un text entry moderne
function UIThemes:DrawModernTextEntry(panel, w, h, text, isFocused)
    local theme = self:GetCurrentTheme()
    
    -- Fond
    surface.SetDrawColor(theme.colors.surface.r, theme.colors.surface.g, theme.colors.surface.b, 200)
    surface.DrawRect(0, 0, w, h)
    
    -- Bordure
    local borderColor = isFocused and theme.colors.primary or theme.colors.border
    surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 150)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    -- Texte
    if text and text != "" then
        surface.SetFont("DermaDefault")
        draw.SimpleText(text, "DermaDefault", 5, h/2, theme.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

-- Fonction pour dessiner un onglet moderne
function UIThemes:DrawModernTab(panel, w, h, text, isActive, isHovered)
    local theme = self:GetCurrentTheme()
    
    -- Fond
    local bgColor = isActive and theme.colors.primary or theme.colors.surface
    if isHovered and not isActive then
        bgColor = theme.colors.secondary
    end
    
    surface.SetDrawColor(bgColor.r, bgColor.g, bgColor.b, 200)
    surface.DrawRect(0, 0, w, h)
    
    -- Bordure
    surface.SetDrawColor(theme.colors.border.r, theme.colors.border.g, theme.colors.border.b, 100)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    
    -- Texte
    surface.SetFont("DermaDefault")
    draw.SimpleText(text, "DermaDefault", w/2, h/2, theme.colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Fonction pour dessiner un titre moderne
function UIThemes:DrawModernTitle(panel, w, h, text, subtitle)
    local theme = self:GetCurrentTheme()
    
    -- Fond avec dégradé
    local gradient = {}
    for i = 0, h do
        local alpha = 240 - (i / h) * 40
        table.insert(gradient, {x = 0, y = i, w = w, h = 1, color = Color(theme.colors.background.r, theme.colors.background.g, theme.colors.background.b, alpha)})
    end
    
    for _, rect in ipairs(gradient) do
        surface.SetDrawColor(rect.color)
        surface.DrawRect(rect.x, rect.y, rect.w, rect.h)
    end
    
    -- Bordure
    surface.SetDrawColor(theme.colors.primary.r, theme.colors.primary.g, theme.colors.primary.b, 200)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    -- Titre principal
    surface.SetFont("DermaLarge")
    draw.SimpleText(text, "DermaLarge", 20, 15, theme.colors.text, TEXT_ALIGN_LEFT)
    
    -- Sous-titre
    if subtitle then
        surface.SetFont("DermaDefault")
        draw.SimpleText(subtitle, "DermaDefault", 20, 45, theme.colors.textSecondary, TEXT_ALIGN_LEFT)
    end
end

-- Fonction pour dessiner un tooltip moderne
function UIThemes:DrawModernTooltip(panel, w, h, text)
    local theme = self:GetCurrentTheme()
    
    -- Fond
    surface.SetDrawColor(theme.colors.surface.r, theme.colors.surface.g, theme.colors.surface.b, 240)
    surface.DrawRect(0, 0, w, h)
    
    -- Bordure
    surface.SetDrawColor(theme.colors.border.r, theme.colors.border.g, theme.colors.border.b, 200)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    
    -- Texte
    surface.SetFont("DermaDefault")
    draw.SimpleText(text, "DermaDefault", 10, h/2, theme.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

-- Exporter le module
_G.UIThemes = UIThemes
