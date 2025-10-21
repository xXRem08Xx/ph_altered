-- Modern Prop Hunt Settings (safe & portable)
-- Client-side file: lua/autorun/client/cl_ph_modern_settings.lua

if not CLIENT then return end

local ModernSettings = {}
local settingsMenu

-- ===== Fonts (polices sûres Derma) =====
-- Utilise les polices déjà présentes dans GMod (fiables multi-OS)
surface.CreateFont("PH_Title", { font = "Trebuchet24", size = 24, weight = 800, antialias = true })
surface.CreateFont("PH_Label", { font = "Trebuchet18", size = 18, weight = 600, antialias = true })
surface.CreateFont("PH_Help",  { font = "Trebuchet18", size = 14, weight = 0,   antialias = true })

-- ===== Icônes natives (évite les emojis) =====
local ICONS = {
  ["Général"]      = "icon16/controller.png",
  ["Équipes"]      = "icon16/group.png",
  ["Chasseurs"]    = "icon16/crosshair.png",
  ["Props"]        = "icon16/box.png",
  ["Audio & Voix"] = "icon16/sound.png",
  ["Taunts"]       = "icon16/music.png",
  ["Avancé"]       = "icon16/wrench.png",
}

-- ===== Définition des catégories et paramètres =====
ModernSettings.Categories = {
  {
    name = "Général",
    settings = {
      {name="ph_roundlimit",       type="int",   label="Nombre de rounds",            min=1,  max=50,  decimals=0, help="Nombre de rounds avant le vote de carte"},
      {name="ph_roundtime",        type="int",   label="Durée des rounds (sec)",      min=0,  max=300, decimals=0, help="Durée limite des rounds (0 = automatique)"},
      {name="ph_mapstartwait",     type="int",   label="Attente avant début (sec)",   min=0,  max=120, decimals=0, help="Temps d'attente avant le début de la carte"},
      {name="ph_hidingtime",       type="int",   label="Temps de cachette (sec)",     min=0,  max=120, decimals=0, help="Temps avant que les chasseurs soient libérés"},
      {name="ph_postroundtime",    type="int",   label="Temps post-round (sec)",      min=2,  max=60,  decimals=0, help="Temps avant le round suivant"},
      {name="ph_map_time_limit",   type="int",   label="Limite de temps carte (min)", min=-1, max=120, decimals=0, help="Minutes avant le dernier round (-1 = désactivé)"},
    }
  },
  {
    name = "Équipes",
    settings = {
      {name="ph_auto_team_balance",      type="bool",  label="Équilibrage auto des équipes", help="Équilibre automatiquement les équipes"},
      {name="ph_nb_hunter",              type="int",   label="Nombre de chasseurs",          min=1, max=10, decimals=0, help="Si équilibrage désactivé"},
      {name="ph_props_onwinstayprops",   type="bool",  label="Props restent props en victoire", help="Les props restent dans leur équipe après victoire"},
      {name="ph_dead_canroam",           type="bool",  label="Spectateurs libres",           help="Les morts peuvent utiliser le mode spectateur libre"},
    }
  },
  {
    name = "Chasseurs",
    settings = {
      {name="ph_hunter_dmgpenalty", type="int",   label="Dégâts mauvais tir", min=0, max=100, decimals=0, help="Dégâts subis sur mauvais prop"},
      {name="ph_hunter_smggrenades",type="int",   label="Grenades SMG",       min=0, max=5,   decimals=0, help="Grenades pour chasseurs"},
      {name="ph_hunter_deaf_onhiding", type="bool", label="Sourds pendant cachette", help="Chasseurs sourds pendant la cachette"},
      {name="ph_hunter_aim_laser",   type="int",   label="Laser de visée (0/1/2)", min=0, max=2, decimals=0, help="0: personne, 1: spectateurs, 2: props+spectateurs"},
    }
  },
  {
    name = "Props",
    settings = {
      {name="ph_props_small_size",         type="int",   label="Pénalité petite taille", min=0, max=1000, decimals=0, help="Pénalité de vitesse"},
      {name="ph_props_jumppower",          type="float", label="Puissance de saut",      min=0, max=5,    decimals=2, help="Bonus de jump"},
      {name="ph_props_camdistance",        type="float", label="Distance caméra",        min=0, max=5,    decimals=2, help="Multiplicateur de distance"},
      {name="ph_props_silent_footsteps",   type="bool",  label="Pas silencieux"},
      {name="ph_props_tpose",              type="bool",  label="T-pose"},
      {name="ph_props_undisguised_thirdperson", type="bool", label="3e personne non déguisé"},
      {name="ph_props_random_change",      type="bool",  label="Props aléatoires"},
      {name="ph_random_prop_limit",        type="int",   label="Limite props aléatoires", min=0, max=10, decimals=0},
    }
  },
  {
    name = "Audio & Voix",
    settings = {
      {name="ph_voice_hearotherteam", type="bool", label="Entendre l'autre équipe"},
      {name="ph_voice_heardead",      type="bool", label="Entendre les morts"},
      {name="ph_audio_spatialization",type="bool", label="Spatialisation audio 3D"},
      {name="ph_audio_debug",         type="bool", label="Debug audio"},
    }
  },
  {
    name = "Taunts",
    settings = {
      {name="ph_taunt_menu_phrase",       type="string", label="Phrase menu taunt"},
      {name="ph_auto_taunt",              type="bool",   label="Taunts auto"},
      {name="ph_auto_taunt_delay_min",    type="int",    label="Délai min taunt (sec)", min=0, max=300, decimals=0},
      {name="ph_auto_taunt_delay_max",    type="int",    label="Délai max taunt (sec)", min=0, max=300, decimals=0},
      {name="ph_auto_taunt_props_only",   type="bool",   label="Taunts auto props seulement"},
    }
  },
  {
    name = "Avancé",
    settings = {
      {name="ph_secrets",                type="bool", label="Secrets activés"},
      {name="ph_auto_taunt_delay_min",   type="int",  label="Délai min taunt (sec)", min=0, max=300, decimals=0},
      {name="ph_auto_taunt_delay_max",   type="int",  label="Délai max taunt (sec)", min=0, max=300, decimals=0},
    }
  }
}

-- ===== Helpers =====

local function hasConVar(cvar)
  local ok = GetConVar(cvar)
  return ok ~= nil, ok
end

local function pushConVar(name, value)
  if value == nil then return end
  RunConsoleCommand(name, tostring(value))
end

local function createSettingControl(parent, def)
  local exists, cv = hasConVar(def.name)
  local helpText = def.help or ""

  if def.type == "bool" then
    local pnl = vgui.Create("DPanel", parent)
    pnl:Dock(TOP)
    pnl:DockMargin(0, 0, 0, 6)
    pnl:SetTall(24)

    local cb = vgui.Create("DCheckBoxLabel", pnl)
    cb:Dock(FILL)
    cb:SetText(def.label or def.name)
    cb:SetFont("PH_Label")
    cb:SetTextColor(color_white)
    cb:SetDark(false)
    cb:SetEnabled(exists)

    if exists then cb:SetChecked(cv:GetBool()) else cb:SetChecked(false) end

    function cb:OnChange(b)
      if exists then pushConVar(def.name, b and "1" or "0") end
    end

    if helpText ~= "" then
      local hlp = vgui.Create("DLabel", parent)
      hlp:SetFont("PH_Help")
      hlp:SetText(helpText .. (exists and "" or "  (ConVar introuvable)"))
      hlp:SetTextColor(exists and Color(200,200,200) or Color(255,120,120))
      hlp:Dock(TOP)
      hlp:DockMargin(4, 0, 0, 8)
    end

    return pnl
  end

  if def.type == "int" or def.type == "float" then
    local slider = vgui.Create("DNumSlider", parent)
    slider:Dock(TOP)
    slider:DockMargin(0, 0, 0, 4)
    slider:SetText(def.label or def.name)
    slider:SetMinMax(def.min or 0, def.max or 100)
    slider:SetDecimals(def.decimals or (def.type == "float" and 2 or 0))
    slider:SetEnabled(exists)

    local cur = exists and tonumber(cv:GetString()) or 0
    if cur == nil then cur = 0 end
    slider:SetValue(cur)

    function slider:OnValueChanged(val)
      if exists then pushConVar(def.name, val) end
    end

    if helpText ~= "" then
      local hlp = vgui.Create("DLabel", parent)
      hlp:SetFont("PH_Help")
      hlp:SetText(helpText .. (exists and "" or "  (ConVar introuvable)"))
      hlp:SetTextColor(exists and Color(200,200,200) or Color(255,120,120))
      hlp:Dock(TOP)
      hlp:DockMargin(4, 0, 0, 8)
    end

    return slider
  end

  if def.type == "string" then
    local lbl = vgui.Create("DLabel", parent)
    lbl:SetFont("PH_Label")
    lbl:SetText(def.label or def.name)
    lbl:SetTextColor(color_white)
    lbl:Dock(TOP)
    lbl:DockMargin(0, 0, 0, 2)

    local txt = vgui.Create("DTextEntry", parent)
    txt:Dock(TOP)
    txt:DockMargin(0, 0, 0, 6)
    txt:SetEnabled(exists)
    txt:SetUpdateOnType(true)
    if exists then txt:SetText(cv:GetString() or "") else txt:SetText("") end

    function txt:OnEnter()
      if exists then pushConVar(def.name, self:GetText()) end
    end

    if helpText ~= "" then
      local hlp = vgui.Create("DLabel", parent)
      hlp:SetFont("PH_Help")
      hlp:SetText(helpText .. (exists and "" or "  (ConVar introuvable)"))
      hlp:SetTextColor(exists and Color(200,200,200) or Color(255,120,120))
      hlp:Dock(TOP)
      hlp:DockMargin(4, 0, 0, 8)
    end

    return txt
  end

  -- Type inconnu : message
  local warn = vgui.Create("DLabel", parent)
  warn:SetFont("PH_Help")
  warn:SetText("[Type non géré] " .. (def.label or def.name))
  warn:SetTextColor(Color(255,150,150))
  warn:Dock(TOP)
  warn:DockMargin(0, 0, 0, 6)
  return warn
end

-- ===== Menu =====
function ModernSettings:CreateMenu()
  if IsValid(settingsMenu) then settingsMenu:Remove() end

  local W, H = math.floor(ScrW()*0.7), math.floor(ScrH()*0.8)
  settingsMenu = vgui.Create("DFrame")
  settingsMenu:SetSize(W, H)
  settingsMenu:Center()
  settingsMenu:MakePopup()
  settingsMenu:SetDeleteOnClose(false)
  settingsMenu:ShowCloseButton(true)
  settingsMenu:SetTitle("")
  settingsMenu:SetDraggable(true)

  -- Fond simple & performant
  function settingsMenu:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, Color(26, 28, 34, 245))
    surface.SetDrawColor(52, 152, 219, 200)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    draw.SimpleText("Paramètres Prop Hunt", "PH_Title", 16, 12, color_white, TEXT_ALIGN_LEFT)
  end

  -- Onglets (DPropertySheet)
  local sheet = vgui.Create("DPropertySheet", settingsMenu)
  sheet:Dock(FILL)
  sheet:DockMargin(8, 40, 8, 48)

  -- Construire les catégories
  for _, cat in ipairs(ModernSettings.Categories) do
    local panel = vgui.Create("DPanel", sheet)
    panel:Dock(FILL)
    function panel:Paint(w,h)
      draw.RoundedBox(6, 0, 0, w, h, Color(32, 34, 40, 240))
    end

    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 8, 8, 8)

    -- Ajoute chaque réglage
    for _, def in ipairs(cat.settings or {}) do
      createSettingControl(scroll, def)
    end

    local iconPath = ICONS[cat.name] or "icon16/cog.png"
    sheet:AddSheet(cat.name, panel, iconPath)
  end

  -- Barre de boutons bas
  local buttonPanel = vgui.Create("DPanel", settingsMenu)
  buttonPanel:Dock(BOTTOM)
  buttonPanel:SetTall(44)
  function buttonPanel:Paint(w,h)
    draw.RoundedBoxEx(8, 0, 0, w, h, Color(24, 26, 32, 245), false, false, true, true)
    surface.SetDrawColor(52, 152, 219, 180)
    surface.DrawLine(0, 0, w, 0)
  end

  -- Bouton Réinitialiser
  local resetButton = vgui.Create("DButton", buttonPanel)
  resetButton:Dock(LEFT)
  resetButton:DockMargin(8, 8, 4, 8)
  resetButton:SetWide(140)
  resetButton:SetText("Réinitialiser")
  resetButton:SetFont("PH_Label")

  function resetButton:Paint(w, h)
    local hover = self:IsHovered()
    draw.RoundedBox(6, 0, 0, w, h, hover and Color(231,76,60,220) or Color(192,57,43,220))
    surface.SetDrawColor(255, 255, 255, 40)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
  end

  function resetButton:DoClick()
    Derma_Query("Réinitialiser toutes les options aux valeurs par défaut ?", "Confirmation",
      "Oui", function()
        for _, category in ipairs(ModernSettings.Categories) do
          for _, setting in ipairs(category.settings) do
            local c = GetConVar(setting.name)
            if c then
              RunConsoleCommand(setting.name, c:GetDefault())
            end
          end
        end
        -- rafraîchir l’UI
        settingsMenu:Close()
        timer.Simple(0, function() ModernSettings:CreateMenu() end)
      end,
      "Non"
    )
  end

  -- Espace
  local spacer = vgui.Create("DPanel", buttonPanel)
  spacer:Dock(FILL)
  function spacer:Paint() end

  -- Bouton Appliquer (ferme juste le menu : les sliders/checkbox ont déjà poussé les cvars)
  local applyButton = vgui.Create("DButton", buttonPanel)
  applyButton:Dock(RIGHT)
  applyButton:DockMargin(4, 8, 8, 8)
  applyButton:SetWide(140)
  applyButton:SetText("Appliquer")
  applyButton:SetFont("PH_Label")

  function applyButton:Paint(w, h)
    local hover = self:IsHovered()
    draw.RoundedBox(6, 0, 0, w, h, hover and Color(46,204,113,220) or Color(39,174,96,220))
    surface.SetDrawColor(255, 255, 255, 40)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
  end

  function applyButton:DoClick()
    settingsMenu:Close()
  end

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

-- Réception réseau pour ouvrir le menu
net.Receive("ph_openhelpmenu", function()
  ModernSettings:ToggleMenu()
end)

-- Commande console locale pratique
concommand.Add("ph_settings", function()
  ModernSettings:ToggleMenu()
end)
