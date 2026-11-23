local modpath = core.get_modpath("lighthouse")

function lighthouse.add_builtin_profile(name, profile)
    local ok, message = lighthouse.register_preset(name, profile)
    if not ok then
        error("[Lighthouse] Built-in profile " .. name .. ": " .. tostring(message))
    end
end

function lighthouse.add_builtin_scene(name, definition)
    local ok, message = lighthouse.register_scene(name, definition)
    if not ok then
        error("[Lighthouse] Built-in scene " .. name .. ": " .. tostring(message))
    end
    lighthouse.builtin_scenes[name] = true
end

function lighthouse.add_biome_profile(name, profile, description)
    lighthouse.add_builtin_profile(name, profile)
    lighthouse.add_builtin_scene(name, {profile = name, category = "Biomes", description = description, transition = 5})
    return name
end

lighthouse.builtin_scenes = {}
dofile(modpath .. "/content/lighting.lua")
dofile(modpath .. "/content/presets.lua")
dofile(modpath .. "/content/biomes/palettes.lua")
dofile(modpath .. "/content/biomes/variants.lua")
dofile(modpath .. "/content/biomes.lua")

lighthouse.register_builtin_presets()
lighthouse.register_biome_content()