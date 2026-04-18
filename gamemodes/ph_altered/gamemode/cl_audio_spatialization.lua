-- Client-side audio spatialization
--
-- Un unique hook EntityEmitSound applique des indices perceptuels de
-- verticalité et d'occlusion sans écraser l'atténuation native de Source :
--   * occlusion via trace MASK_SOLID_BRUSHONLY -> DSP muffled + volume réduit
--   * élévation (dz > seuil) -> DSP distinct au-dessus vs en-dessous
--   * source derrière le joueur -> DSP low-pass léger
--
-- On ne recalcule plus le volume linéairement (ça tuait le panning stéréo
-- natif). On ne multiplie plus par 100 (EmitSound attend 0-1).

CreateClientConVar("ph_audio_debug", "0", true, false, "Affiche le debug audio PH")
CreateClientConVar("ph_audio_spatial_enabled", "1", true, false, "Active la spatialisation audio enrichie")

-- DSP presets (cf. https://wiki.facepunch.com/gmod/DSP_Presets)
local DSP_OCCLUDED_ABOVE = 31 -- son étouffé type plafond béton
local DSP_OCCLUDED_BELOW = 26 -- son étouffé type plancher
local DSP_ELEVATION_UP   = 15 -- légère réverbération "ouverte"
local DSP_ELEVATION_DOWN = 20 -- coloration grave
local DSP_BEHIND         = 14 -- atténuation HF derrière

local ELEVATION_THRESHOLD = 100
local OCCLUSION_VOLUME_MULT = 0.55
local OCCLUSION_LEVEL_BOOST = 12

local traceData = {mask = MASK_SOLID_BRUSHONLY}

hook.Add("EntityEmitSound", "PH_SpatialAudio", function(t)
    if not GetConVar("ph_audio_spatial_enabled"):GetBool() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not t.Pos then return end

    local ear = ply:EyePos()
    local delta = t.Pos - ear
    local dz = delta.z
    local adz = math.abs(dz)

    -- Exclure le son émis par le joueur local (pas d'intérêt à spatialiser)
    local ent = t.Entity
    if IsValid(ent) and ent == ply then return end

    -- Occlusion par trace contre les brushes du monde uniquement
    traceData.start = t.Pos
    traceData.endpos = ear
    traceData.filter = ent
    local tr = util.TraceLine(traceData)
    local occluded = tr.Hit and tr.Fraction < 0.98

    local modified = false

    if occluded then
        t.Volume = (t.Volume or 1) * OCCLUSION_VOLUME_MULT
        t.SoundLevel = math.min((t.SoundLevel or 75) + OCCLUSION_LEVEL_BOOST, 160)
        t.DSP = dz > 0 and DSP_OCCLUDED_ABOVE or DSP_OCCLUDED_BELOW
        modified = true
    elseif adz > ELEVATION_THRESHOLD then
        t.DSP = dz > 0 and DSP_ELEVATION_UP or DSP_ELEVATION_DOWN
        modified = true
    else
        local dir = delta:GetNormalized()
        if ply:GetAimVector():Dot(dir) < -0.2 then
            t.DSP = DSP_BEHIND
            modified = true
        end
    end

    if modified then return true end
end)

-- Debug overlay
local function audioDebug()
    if not GetConVar("ph_audio_debug"):GetBool() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local ear = ply:EyePos()
    draw.SimpleText("PH audio debug", "DermaDefault", 10, 10, Color(255, 255, 128))
    draw.SimpleText("Ear: " .. tostring(ear), "DermaDefault", 10, 26, color_white)

    local y = 50
    for _, other in ipairs(player.GetAll()) do
        if other ~= ply and IsValid(other) and other:Alive() then
            local p = other:GetPos()
            local d = ear:Distance(p)
            if d <= 2000 then
                local dz = p.z - ear.z
                draw.SimpleText(
                    string.format("%s  d=%.0f  dz=%+.0f", other:Nick(), d, dz),
                    "DermaDefault", 10, y, color_white)
                y = y + 16
            end
        end
    end
end

hook.Add("HUDPaint", "PH_AudioDebug", audioDebug)
