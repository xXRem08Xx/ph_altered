-- Système de classes ph_altered
--
-- Registry partagé des classes. Une classe = une équipe (TEAM_PROP / TEAM_HUNTER),
-- une capacité à usage unique par round, pas de doublon par équipe.

PH = PH or {}
PH.Classes = PH.Classes or {}

-- TEAM_PROP / TEAM_HUNTER sont déjà définis dans shared.lua

PH.CLASS_PHASE_ANY   = 0  -- utilisable en HIDE et SEEK
PH.CLASS_PHASE_SEEK  = 1  -- utilisable uniquement en SEEK
PH.CLASS_PHASE_HIDE  = 2  -- utilisable uniquement en HIDE

-- ConVars partagées (réplication client)
local F = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)

CreateConVar("ph_classes_enabled",       "1", F, "Active le système de classes")
CreateConVar("ph_classes_auto_assign",   "0", F, "Assigne aléatoirement une classe si aucun pick")

-- Toggles par classe
CreateConVar("ph_class_medic",       "1", F, "Active la classe Medic")
CreateConVar("ph_class_ghost",       "1", F, "Active la classe Ghost")
CreateConVar("ph_class_decoy",       "1", F, "Active la classe Decoy")
CreateConVar("ph_class_jumper",      "1", F, "Active la classe Jumper")
CreateConVar("ph_class_scout",       "1", F, "Active la classe Scout")
CreateConVar("ph_class_tracker",     "1", F, "Active la classe Tracker")
CreateConVar("ph_class_demolition",  "1", F, "Active la classe Demolition")
CreateConVar("ph_class_sweeper",     "1", F, "Active la classe Sweeper")

-- Balance
CreateConVar("ph_class_medic_heal",           "50",  F, "Medic : HP restaurés par heal")
CreateConVar("ph_class_ghost_duration",       "3",   F, "Ghost : durée d'invisibilité (s)")
CreateConVar("ph_class_decoy_duration",       "15",  F, "Decoy : durée du clone (s)")
CreateConVar("ph_class_jumper_min_range",     "500", F, "Jumper : portée TP min")
CreateConVar("ph_class_jumper_max_range",     "1000",F, "Jumper : portée TP max")
CreateConVar("ph_class_scout_cone_deg",       "60",  F, "Scout : angle du cône (deg)")
CreateConVar("ph_class_scout_range",          "1500",F, "Scout : portée du cône")
CreateConVar("ph_class_tracker_warn_delay",   "1",   F, "Tracker : délai avant warning props (s)")
CreateConVar("ph_class_demolition_radius",    "400", F, "Demolition : rayon de pulse")
CreateConVar("ph_class_sweeper_radius",       "700", F, "Sweeper : rayon d'effet")
CreateConVar("ph_class_sweeper_percent",      "40",  F, "Sweeper : % de props supprimés (0-100)")
CreateConVar("ph_class_sweeper_cap",          "30",  F, "Sweeper : cap max de props supprimés")

-- Couleurs par équipe (accent HUD / panel)
PH.TeamAccent = {
    [TEAM_PROP]  = Color(230, 126, 34),
    [TEAM_HUNTER] = Color(52, 152, 219),
}

-- Helper : une classe est-elle activée par l'admin ?
function PH.IsClassEnabled(id)
    local cv = GetConVar("ph_class_" .. id)
    return cv and cv:GetBool()
end

-- Helper : enregistrer une classe (appelé côté serveur dans sv_classes.lua)
function PH.RegisterClass(id, def)
    def.id = id
    PH.Classes[id] = def
end

-- Helper : liste des classes d'une team, filtrées par toggle
function PH.GetAvailableClasses(team)
    local list = {}
    for id, def in pairs(PH.Classes) do
        if def.team == team and PH.IsClassEnabled(id) then
            list[#list + 1] = def
        end
    end
    table.sort(list, function(a, b) return a.order < b.order end)
    return list
end

-- Helper client/serveur : la classe d'un joueur (ou nil)
function PH.GetClass(ply)
    if not IsValid(ply) then return nil end
    local id = ply:GetNWString("ph_class", "")
    if id == "" then return nil end
    return PH.Classes[id]
end

function PH.AbilityUsed(ply)
    return ply:GetNWBool("ph_ability_used", false)
end
