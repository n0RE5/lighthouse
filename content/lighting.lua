-- Static lighting is shared by related scenes so ordinary sky/time changes do
-- not keep rebuilding world meshes.
local curves = {
    natural = {0,5,14,28,46,68,92,116,139,158,176,193,209,225,240,255},
    soft = {0,7,18,34,54,78,102,125,146,164,181,197,212,226,241,255},
    dramatic = {0,3,10,22,39,60,85,110,133,153,172,189,206,223,239,255},
    night = {0,5,14,28,46,68,92,116,139,158,176,193,209,225,240,255},
    dark = {0,3,10,21,36,55,78,101,124,145,164,182,200,218,237,255},
    storm = {0,5,13,27,45,66,89,112,134,153,171,188,204,220,237,255},
}

-- curve, AO gamma, shadow strength, shadow tint, optional saturation.
local looks = {
    ["Natural Day"] = {"natural", 1.25, 0.38, {10,16,25}},
    ["Vibrant Day"] = {"natural", 1.25, 0.4, {8,16,24}, 1.1},
    Cinematic = {"dramatic", 1.1, 0.46, {16,22,34}},
    ["Soft Fantasy"] = {"soft", 1.4, 0.34, {24,22,40}},
    ["Dark Fantasy"] = {"dramatic", 1.05, 0.5, {17,20,31}},
    Sunrise = {"natural", 1.3, 0.36, {24,19,33}},
    ["Clear Morning"] = {"natural", 1.3, 0.34, {14,20,30}},
    Midday = {"natural", 1.25, 0.44, {11,18,27}},
    Afternoon = {"natural", 1.25, 0.4, {14,20,28}},
    Sunset = {"natural", 1.3, 0.4, {30,18,35}},
    ["Blue Hour"] = {"night", 1.35, 0.32, {18,25,43}},
    ["Moonlit Night"] = {"night", 1.35, 0.26, {15,22,40}, 0.88},
    ["Dark Night"] = {"dark", 1.2, 0.3, {12,18,29}, 0.8},
    Cloudy = {"natural", 1.4, 0.24, {20,27,35}},
    Overcast = {"storm", 1.55, 0.18, {24,31,39}},
    Foggy = {"soft", 1.6, 0.16, {28,35,42}},
    ["Light Rain"] = {"storm", 1.55, 0.16, {24,31,39}},
    ["Heavy Rain"] = {"storm", 1.5, 0.12, {22,29,39}},
    Thunderstorm = {"storm", 1.45, 0.1, {18,25,37}},
    Snowfall = {"soft", 1.5, 0.2, {23,34,48}},
    Blizzard = {"soft", 1.6, 0.1, {23,34,48}},
    ["Forest Day"] = {"natural", 1.15, 0.44, {12,25,27}},
    ["Forest Night"] = {"night", 1.2, 0.32, {13,23,34}, 0.86},
    ["Desert Day"] = {"natural", 1.3, 0.38, {27,22,30}, 0.98},
    ["Desert Night"] = {"night", 1.35, 0.28, {24,23,40}},
    ["Snowy Plains"] = {"soft", 1.4, 0.34, {18,29,44}},
    Swamp = {"natural", 1.3, 0.32, {20,30,24}},
    Underground = {"night", 1.25, 0, {0,0,0}},
    ["Deep Cave"] = {false, 1.2, 0, {0,0,0}},
    Underwater = {"soft", 1.5, 0.18, {17,38,51}},
    ["Magical Forest"] = {"soft", 1.3, 0.36, {25,25,41}, 1.08},
    ["Magical Forest Night"] = {"night", 1.4, 0.3, {29,19,43}},
    Dreamscape = {"soft", 1.4, 0.34, {27,22,43}, 1.07},
    ["Liminal Mushroom Day"] = {"soft", 1.35, 0.36, {26,20,41}, 1.07},
    ["Liminal Mushroom Night"] = {"night", 1.4, 0.28, {29,20,41}},
    ["Bright Nights"] = {false, 1.35, 0.22, {16,23,39}},
    ["High Contrast"] = {"dramatic", 1.05, 0.46, {13,18,27}},
    Monochrome = {"natural", 1.2, 0.42, {16,16,16}},
}

function lighthouse.style_builtin_profile(name, profile)
    local look = looks[name]
    if not look then
        return profile
    end
    local tint = look[4]
    local lighting = {
        static = {ao_gamma = look[2]},
        shadows = {intensity = look[3], tint = {r = tint[1], g = tint[2], b = tint[3]}},
    }
    if look[1] then
        lighting.static.light_curve = curves[look[1]]
    end
    if look[5] then
        lighting.saturation = look[5]
    end
    return lighthouse.merge(profile, {lighting = lighting})
end