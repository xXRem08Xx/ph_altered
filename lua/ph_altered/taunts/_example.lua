-- EXEMPLE : ajouter des taunts custom SANS toucher au gamemode.
--
-- Emplacement chargé automatiquement : garrysmod/lua/ph_altered/taunts/*.lua
-- (le chemin est relatif à `lua/`, donc ce fichier EST bien au bon endroit).
--
-- Renomme ce fichier en retirant le `_` devant (ex: "mes_taunts.lua") pour
-- l'activer, ou supprime-le si tu n'en veux pas.
--
-- Signature :
--   addTaunt(displayName, soundFiles, team, sex, categories, duration, allowedModels)
--
-- Paramètres :
--   displayName   : nom affiché dans le menu (string)
--   soundFiles    : table de chemins relatifs à garrysmod/sound/
--   team          : "props" | "hunters" | TEAM_PROP | TEAM_HUNTER | table
--   sex           : "male" | "female" | nil  (nil = les deux)
--   categories    : table de strings (ex: {"talk", "funny"})
--   duration      : IMPORTANT pour les MP3 ! durée en secondes.
--                   Pour les WAV, laisse nil : le moteur calcule tout seul.
--   allowedModels : (optionnel) table de noms de playermodels autorisés
--
-- RÈGLES IMPORTANTES :
--   - Le fichier son DOIT exister dans garrysmod/sound/<path>.
--     Si le serveur ne le trouve pas, le taunt est ignoré (cf. logs console).
--   - Pour les MP3, TOUJOURS passer la durée (SoundDuration est buggé pour MP3).
--   - Pour que les autres joueurs entendent ton taunt, le fichier doit être
--     distribué (FastDL, addon Workshop, ou présent dans leur gmod).

--[[
-- Exemples : décommente et adapte.

addTaunt("Mon taunt WAV", {
    "mon_dossier/mon_son.wav"
}, "props", nil, {"custom"})

addTaunt("Mon taunt MP3", {
    "mon_dossier/mon_long_son.mp3"
}, "props", nil, {"custom"}, 5)  -- 5s de durée (le MP3 fait ~5s)

addTaunt("Taunt multi-sons", {
    "mon_dossier/a.wav",
    "mon_dossier/b.wav",
    "mon_dossier/c.mp3"
}, "hunters", nil, {"custom"}, 3)  -- durée appliquée aux mp3
--]]
