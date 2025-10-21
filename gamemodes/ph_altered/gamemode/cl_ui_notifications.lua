-- Système de notifications modernes pour l'interface Prop Hunt
-- Affiche des notifications élégantes pour les changements de paramètres

local UINotifications = {}
local notifications = {}
local notificationId = 0

-- Types de notifications
UINotifications.Types = {
    SUCCESS = "success",
    WARNING = "warning",
    ERROR = "error",
    INFO = "info"
}

-- Configuration des notifications
UINotifications.Config = {
    Duration = 3, -- Durée d'affichage en secondes
    MaxNotifications = 5, -- Nombre maximum de notifications simultanées
    AnimationSpeed = 0.3, -- Vitesse d'animation
    Spacing = 10 -- Espacement entre les notifications
}

-- Icônes pour chaque type
UINotifications.Icons = {
    success = "✅",
    warning = "⚠️",
    error = "❌",
    info = "ℹ️"
}

-- Couleurs pour chaque type
UINotifications.Colors = {
    success = Color(46, 204, 113),
    warning = Color(241, 196, 15),
    error = Color(231, 76, 60),
    info = Color(52, 152, 219)
}

-- Structure d'une notification
local Notification = {}
Notification.__index = Notification

function Notification:New(type, title, message, duration)
    local self = setmetatable({}, Notification)
    
    self.id = notificationId
    notificationId = notificationId + 1
    
    self.type = type or UINotifications.Types.INFO
    self.title = title or "Notification"
    self.message = message or ""
    self.duration = duration or UINotifications.Config.Duration
    self.startTime = CurTime()
    self.endTime = self.startTime + self.duration
    
    self.alpha = 0
    self.x = ScrW()
    self.y = 50 + (#notifications * (100 + UINotifications.Config.Spacing))
    self.width = 350
    self.height = 80
    
    self.animating = true
    self.visible = true
    
    return self
end

function Notification:Update()
    if not self.visible then return end
    
    local currentTime = CurTime()
    local timeLeft = self.endTime - currentTime
    
    -- Animation d'entrée
    if self.animating and self.alpha < 1 then
        self.alpha = math.min(1, (currentTime - self.startTime) / UINotifications.Config.AnimationSpeed)
        self.x = ScrW() - (self.width * self.alpha)
    end
    
    -- Animation de sortie
    if timeLeft <= UINotifications.Config.AnimationSpeed then
        self.alpha = math.max(0, timeLeft / UINotifications.Config.AnimationSpeed)
        self.x = ScrW() - (self.width * self.alpha)
    end
    
    -- Supprimer si invisible
    if self.alpha <= 0 then
        self.visible = false
        return false
    end
    
    return true
end

function Notification:Paint()
    if not self.visible or self.alpha <= 0 then return end
    
    local theme = UIThemes and UIThemes:GetCurrentTheme() or {colors = {surface = Color(40, 40, 45), text = Color(255, 255, 255), border = Color(60, 60, 65)}}
    local color = UINotifications.Colors[self.type] or UINotifications.Colors.info
    
    -- Fond avec transparence
    surface.SetDrawColor(color.r, color.g, color.b, 200 * self.alpha)
    surface.DrawRect(self.x, self.y, self.width, self.height)
    
    -- Bordure
    surface.SetDrawColor(theme.colors.border.r, theme.colors.border.g, theme.colors.border.b, 150 * self.alpha)
    surface.DrawOutlinedRect(self.x, self.y, self.width, self.height, 2)
    
    -- Icône
    local icon = UINotifications.Icons[self.type] or UINotifications.Icons.info
    surface.SetFont("ModernSettings_Title")
    draw.SimpleText(icon, "ModernSettings_Title", self.x + 15, self.y + 15, Color(255, 255, 255, 255 * self.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Titre
    surface.SetFont("ModernSettings_Label")
    draw.SimpleText(self.title, "ModernSettings_Label", self.x + 50, self.y + 15, Color(255, 255, 255, 255 * self.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Message
    surface.SetFont("ModernSettings_Help")
    draw.SimpleText(self.message, "ModernSettings_Help", self.x + 15, self.y + 40, Color(200, 200, 200, 200 * self.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Barre de progression
    local progress = math.max(0, (self.endTime - CurTime()) / self.duration)
    surface.SetDrawColor(255, 255, 255, 100 * self.alpha)
    surface.DrawRect(self.x, self.y + self.height - 3, self.width * progress, 3)
end

-- Fonction pour ajouter une notification
function UINotifications:Add(type, title, message, duration)
    -- Limiter le nombre de notifications
    if #notifications >= self.Config.MaxNotifications then
        table.remove(notifications, 1)
    end
    
    local notification = Notification:New(type, title, message, duration)
    table.insert(notifications, notification)
    
    return notification
end

-- Fonction pour supprimer une notification
function UINotifications:Remove(id)
    for i, notification in ipairs(notifications) do
        if notification.id == id then
            table.remove(notifications, i)
            break
        end
    end
end

-- Fonction pour supprimer toutes les notifications
function UINotifications:Clear()
    notifications = {}
end

-- Fonction pour mettre à jour toutes les notifications
function UINotifications:Update()
    for i = #notifications, 1, -1 do
        local notification = notifications[i]
        if not notification:Update() then
            table.remove(notifications, i)
        end
    end
end

-- Fonction pour dessiner toutes les notifications
function UINotifications:Paint()
    for _, notification in ipairs(notifications) do
        notification:Paint()
    end
end

-- Fonctions de commodité
function UINotifications:Success(title, message, duration)
    return self:Add(self.Types.SUCCESS, title, message, duration)
end

function UINotifications:Warning(title, message, duration)
    return self:Add(self.Types.WARNING, title, message, duration)
end

function UINotifications:Error(title, message, duration)
    return self:Add(self.Types.ERROR, title, message, duration)
end

function UINotifications:Info(title, message, duration)
    return self:Add(self.Types.INFO, title, message, duration)
end

-- Hook pour mettre à jour et dessiner les notifications
hook.Add("Think", "UINotifications_Update", function()
    UINotifications:Update()
end)

hook.Add("HUDPaint", "UINotifications_Paint", function()
    if UINotifications and UINotifications.Paint then
        UINotifications:Paint()
    end
end)

-- Fonction pour notifier les changements de paramètres
function UINotifications:NotifySettingChange(settingName, oldValue, newValue)
    local title = "Paramètre modifié"
    local message = string.format("%s: %s → %s", settingName, tostring(oldValue), tostring(newValue))
    
    self:Success(title, message, 2)
end

-- Fonction pour notifier les erreurs de paramètres
function UINotifications:NotifySettingError(settingName, error)
    local title = "Erreur de paramètre"
    local message = string.format("%s: %s", settingName, error)
    
    self:Error(title, message, 4)
end

-- Fonction pour notifier les avertissements
function UINotifications:NotifySettingWarning(settingName, warning)
    local title = "Avertissement"
    local message = string.format("%s: %s", settingName, warning)
    
    self:Warning(title, message, 3)
end

-- Exporter le module
_G.UINotifications = UINotifications
