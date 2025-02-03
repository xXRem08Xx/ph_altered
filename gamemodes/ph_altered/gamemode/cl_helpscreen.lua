local optionsMenu
local convarDefinitions = {
    {name = "ph_voice_hearotherteam", type = "bool", label = "Voice Hear Other Team"},
    {name = "ph_voice_heardead", type = "bool", label = "Voice Hear Dead"},
    {name = "ph_dead_canroam", type = "bool", label = "Dead Spectate Roam"},
    {name = "ph_roundlimit", type = "int", label = "Round Limit", min = 1, max = 50, decimals = 0},
    {name = "ph_roundtime", type = "int", label = "Round Time (sec)", min = 0, max = 300, decimals = 0},
    {name = "ph_mapstartwait", type = "int", label = "Map Start Wait (sec)", min = 0, max = 120, decimals = 0},
    {name = "ph_hidingtime", type = "int", label = "Hiding Time (sec)", min = 0, max = 120, decimals = 0},
    {name = "ph_postroundtime", type = "int", label = "Post-Round Time (sec)", min = 0, max = 60, decimals = 0},
    {name = "ph_map_time_limit", type = "int", label = "Map Time Limit (min)", min = -1, max = 60, decimals = 0},
    {name = "ph_hunter_dmgpenalty", type = "int", label = "Hunter Damage Penalty", min = 0, max = 100, decimals = 0},
    {name = "ph_hunter_smggrenades", type = "int", label = "Hunter SMG Grenades", min = 0, max = 5, decimals = 0},
    {name = "ph_hunter_deaf_onhiding", type = "bool", label = "Hunter Deaf on Hiding"},
    {name = "ph_hunter_aim_laser", type = "int", label = "Hunter Aim Laser", min = 0, max = 2, decimals = 0},
    {name = "ph_props_onwinstayprops", type = "bool", label = "Props Win Stay Props"},
    {name = "ph_props_small_size", type = "int", label = "Props Small Size", min = 0, max = 1000, decimals = 0},
    {name = "ph_props_jumppower", type = "float", label = "Props Jump Power", min = 0, max = 5, decimals = 2},
    {name = "ph_props_camdistance", type = "float", label = "Props Cam Distance", min = 0, max = 5, decimals = 2},
    {name = "ph_props_silent_footsteps", type = "bool", label = "Props Silent Footsteps"},
    {name = "ph_props_tpose", type = "bool", label = "Props Tpose"},
    {name = "ph_props_undisguised_thirdperson", type = "bool", label = "Props Undisguised Thirdperson"},
    {name = "ph_auto_team_balance", type = "bool", label = "Auto Team Balance"},
    {name = "ph_nb_hunter", type = "int", label = "Number of Hunters", min = 1, max = 10, decimals = 0},
    {name = "ph_taunt_menu_phrase", type = "string", label = "Taunt Menu Phrase"},
    {name = "ph_auto_taunt", type = "bool", label = "Auto Taunt Enabled"},
    {name = "ph_auto_taunt_delay_min", type = "int", label = "Auto Taunt Delay Min (sec)", min = 0, max = 300, decimals = 0},
    {name = "ph_auto_taunt_delay_max", type = "int", label = "Auto Taunt Delay Max (sec)", min = 0, max = 300, decimals = 0},
    {name = "ph_auto_taunt_props_only", type = "bool", label = "Auto Taunt Props Only"},
    {name = "ph_secrets", type = "bool", label = "Secrets Enabled"},
    {name = "ph_props_random_change", type = "bool", label = "Random props"},
    {name = "ph_random_prop_limit", type = "int", label = "Random Prop Limit", min = 0, max = 10, decimals = 0}
}
local function createHelpMenu()
	optionsMenu = vgui.Create("DFrame")
	optionsMenu:SetSize(ScrW() * 0.4, ScrH() * 0.6)
	optionsMenu:Center()
	optionsMenu:MakePopup()
	optionsMenu:SetKeyboardInputEnabled(false)
	optionsMenu:SetDeleteOnClose(false)
	optionsMenu:ShowCloseButton(true)
	optionsMenu:SetTitle("")
	optionsMenu:SetVisible(false)
	function optionsMenu:Paint(w, h)
		surface.SetDrawColor(40, 40, 40, 230)
		surface.DrawRect(0, 0, w, h)
		surface.SetFont("RobotoHUD-25")
		draw.ShadowText("Options", "RobotoHUD-25", 8, 2, Color(132, 199, 29), 0)
	end
	local scroll = vgui.Create("DScrollPanel", optionsMenu)
	scroll:Dock(FILL)
	local y = 10
	for _, def in ipairs(convarDefinitions) do
		if def.type == "bool" then
			local chk = vgui.Create("DCheckBoxLabel", scroll)
			chk:SetPos(10, y)
			chk:SetText(def.label)
			chk:SetConVar(def.name)
			chk:SizeToContents()
			y = y + 30
		elseif def.type == "int" or def.type == "float" then
			local slider = vgui.Create("DNumSlider", scroll)
			slider:SetPos(10, y)
			slider:SetSize(300, 40)
			slider:SetText(def.label)
			slider:SetMin(def.min or 0)
			slider:SetMax(def.max or 100)
			slider:SetDecimals(def.decimals or 0)
			slider:SetConVar(def.name)
			y = y + 50
		elseif def.type == "string" then
			local lbl = vgui.Create("DLabel", scroll)
			lbl:SetPos(10, y)
			lbl:SetText(def.label)
			lbl:SizeToContents()
			y = y + 20
			local txtEntry = vgui.Create("DTextEntry", scroll)
			txtEntry:SetPos(10, y)
			txtEntry:SetSize(300, 30)
			txtEntry:SetText(GetConVar(def.name):GetString())
			txtEntry.OnEnter = function(self)
				RunConsoleCommand(def.name, self:GetValue())
			end
			y = y + 40
		end
	end
end
local function toggleHelpMenu()
	if not IsValid(optionsMenu) then
		createHelpMenu()
	end
	optionsMenu:SetVisible(not optionsMenu:IsVisible())
end
net.Receive("ph_openhelpmenu", toggleHelpMenu)
