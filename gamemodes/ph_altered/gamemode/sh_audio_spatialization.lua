-- Système de spatialisation audio pour Prop Hunt
--
-- Principe : on laisse Source gérer le panning stéréo et la loi d'atténuation
-- native via le paramètre soundLevel (SNDLVL_*) et la position passée à
-- EmitSound. Toute la logique de verticalité / occlusion est appliquée
-- côté client via un hook EntityEmitSound unique (cf. cl_audio_spatialization.lua).
--
-- Les anciennes méthodes EmitTaunt3D / EmitDeathSound3D / EmitDisguiseSound3D
-- itéraient sur tous les joueurs et faisaient un ent:EmitSound() par listener.
-- EmitSound broadcaste déjà à tous les clients, la boucle multipliait donc
-- le son N fois. Les aliases ci-dessous font un seul EmitSound natif.

local AudioSpatialization = {}

AudioSpatialization.Config = {
    MaxDistance = 2000,
    MinVolume = 0.1,
    MaxVolume = 1.0,
}

local function safeEmit(ent, soundName, level, pitch, volume, channel)
    if not IsValid(ent) or not soundName or soundName == "" then return end
    ent:EmitSound(
        soundName,
        level or 75,
        pitch or 100,
        math.Clamp(volume or 1, 0, 1),
        channel or CHAN_AUTO
    )
end

function AudioSpatialization:EmitSpatial(ent, soundName, level, pitch, volume, channel)
    safeEmit(ent, soundName, level, pitch, volume, channel)
end

function AudioSpatialization:EmitSound3D(ent, soundName, volume, pitch, channel)
    safeEmit(ent, soundName, 75, pitch, volume, channel)
end

function AudioSpatialization:EmitTaunt3D(ply, soundName, volume, pitch)
    safeEmit(ply, soundName, 80, pitch, volume, CHAN_VOICE)
end

function AudioSpatialization:EmitDeathSound3D(ply, soundName, volume, pitch)
    safeEmit(ply, soundName, 80, pitch, volume, CHAN_VOICE)
end

function AudioSpatialization:EmitDisguiseSound3D(ply, soundName, volume, pitch)
    safeEmit(ply, soundName, 70, pitch, volume, CHAN_STATIC)
end

_G.AudioSpatialization = AudioSpatialization
