-- Taunts custom du serveur.
-- Les fichiers sont dans gamemodes/ph_altered/content/sound/ph_altered/
-- (auto-mount GMod) et distribués aux clients via resource.AddFile (cf. sh_taunt.lua).
--
-- Disponibles pour Props ET Hunters (team = {"props", "hunters"}).
-- Catégorie unique "custom" pour les regrouper dans le menu.

local BOTH = {"props", "hunters"}
local CAT = {"custom"}

-- Format : addTaunt(name, {paths}, team, sex, categories)
-- Tous en WAV donc pas besoin de passer de durée (SoundDuration fonctionne).

addTaunt("003 - Je vais te faire courir", {"ph_altered/003_je_vais_te_faire_courir.wav"}, BOTH, nil, CAT)
addTaunt("Among Us - Role reveal",        {"ph_altered/among_us_role_reveal_sound.wav"},   BOTH, nil, CAT)
addTaunt("Call an ambulance !",           {"ph_altered/call_an_ambulance_not_for_me.wav"}, BOTH, nil, CAT)
addTaunt("Cat vibing",                    {"ph_altered/cat_vibing_to_ievan_polkka.wav"},   BOTH, nil, CAT)
addTaunt("Classic hurt",                  {"ph_altered/classic_hurt.wav"},                 BOTH, nil, CAT)
addTaunt("Dry fart",                      {"ph_altered/dry_fart.wav"},                     BOTH, nil, CAT)
addTaunt("Encore ça fait beaucoup",       {"ph_altered/ecore_ca_fait_beaucoup_la_non__mister_v.wav"}, BOTH, nil, CAT)
addTaunt("Fart with extra reverb",        {"ph_altered/fart_with_extra_reverb.wav"},       BOTH, nil, CAT)
addTaunt("Frappe moi je t'empoisonne",    {"ph_altered/frappe_moi_je_tempoisonne_5aksnqk.wav"}, BOTH, nil, CAT)
addTaunt("Gas gas gas",                   {"ph_altered/gas_gas_gaslqshort.wav"},           BOTH, nil, CAT)
addTaunt("Hello there",                   {"ph_altered/hello_there.wav"},                  BOTH, nil, CAT)
addTaunt("Honteux",                       {"ph_altered/honteux.wav"},                      BOTH, nil, CAT)
addTaunt("Je suis bien",                  {"ph_altered/je_suis_bien_t57xrtv.wav"},         BOTH, nil, CAT)
addTaunt("Jeanne",                        {"ph_altered/jeanne_final.wav"},                 BOTH, nil, CAT)
addTaunt("Le cri de Leo",                 {"ph_altered/le_cri_de_leo.wav"},                BOTH, nil, CAT)
addTaunt("Le rat proche de l'homme",      {"ph_altered/le_rat_proche_de_lhomme.wav"},      BOTH, nil, CAT)
addTaunt("Meow",                          {"ph_altered/m_e_o_w.wav"},                      BOTH, nil, CAT)
addTaunt("Laisse moi dormir zebi",        {"ph_altered/mais_laisse_moi_dormir_zebi_66bzt4t.wav"}, BOTH, nil, CAT)
addTaunt("Mon gros front",                {"ph_altered/mon_gros_front.wav"},               BOTH, nil, CAT)
addTaunt("On me voit",                    {"ph_altered/on_me_voit.wav"},                   BOTH, nil, CAT)
addTaunt("Ouais c'est Greg",              {"ph_altered/ouais_cest_greg.wav"},              BOTH, nil, CAT)
addTaunt("Philipeee",                     {"ph_altered/philipeee.wav"},                    BOTH, nil, CAT)
addTaunt("Président de tous",             {"ph_altered/president_de_tous.wav"},            BOTH, nil, CAT)
addTaunt("Rehehehe",                      {"ph_altered/rehehehe.wav"},                     BOTH, nil, CAT)
addTaunt("Rickroll",                      {"ph_altered/rickroll.wav"},                     BOTH, nil, CAT)
addTaunt("Sale pute",                     {"ph_altered/salepute.wav"},                     BOTH, nil, CAT)
addTaunt("T'es nul",                      {"ph_altered/tes_nul.wav"},                      BOTH, nil, CAT)
addTaunt("Tindeck",                       {"ph_altered/tindeck_1_1.wav"},                  BOTH, nil, CAT)
addTaunt("Ton flingue",                   {"ph_altered/ton_flingue.wav"},                  BOTH, nil, CAT)
addTaunt("Une tuile",                     {"ph_altered/une_tuile.wav"},                    BOTH, nil, CAT)
addTaunt("Weeeeee",                       {"ph_altered/weeeeee.wav"},                      BOTH, nil, CAT)
addTaunt("Why are...",                    {"ph_altered/why_are_yij3kw3.wav"},              BOTH, nil, CAT)
addTaunt("Why are you gay",               {"ph_altered/why_are_you_gay_w5g134p.wav"},      BOTH, nil, CAT)
addTaunt("Women haha",                    {"ph_altered/women_haha.wav"},                   BOTH, nil, CAT)
addTaunt("Yippee tbh",                    {"ph_altered/yippee_tbh.wav"},                   BOTH, nil, CAT)
