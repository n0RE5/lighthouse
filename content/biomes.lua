function lighthouse.register_biome_content()
    local function get_profile(name)
        local profile, message = lighthouse.get_preset(name)
        if not profile then error("[Lighthouse] Biome base profile " .. tostring(name) .. ": " .. tostring(message)) end
        return profile
    end
    local function resolve_scene(definition)
        if type(definition) == "string" then
            if not lighthouse.scenes[definition] then
                error("[Lighthouse] Unknown biome scene: " .. definition)
            end
            return definition
        end
        local profile = lighthouse.merge(get_profile(definition.base), definition.profile)
        return lighthouse.add_biome_profile(definition.name, profile, definition.description)
    end
    lighthouse.original_profile_names = lighthouse.list_presets()
    local catalogue = lighthouse.biome_palettes
    local families, scene_names = {}, {}
    local suffixes = {"_beach", "_shore", "_dunes", "_highland", "_swamp", "_floatland", "_ocean", "_under", "_cave"}

    local function brighten(color, amount)
        local r, g, b = color:match("^#(%x%x)(%x%x)(%x%x)$")
        return ("#%02x%02x%02x"):format(math.min(255, tonumber(r,16) + amount),
            math.min(255, tonumber(g,16) + amount), math.min(255, tonumber(b,16) + amount))
    end

    for _, row in ipairs(catalogue) do
        local id, title = row[1], row[2]
        local day_name, night_name, late_name
        if row.scenes then
            day_name = resolve_scene(row.scenes.day)
            night_name = resolve_scene(row.scenes.night)
            late_name = row.scenes.late and resolve_scene(row.scenes.late)
        elseif row.existing then
            day_name, night_name = row.existing[1], row.existing[2]
        else
            local day = lighthouse.merge(get_profile(row[3]), {
                lighting = {saturation = row[7], static = {ao_gamma = row[8]},
                    shadows = {tint = {r = row[9][1], g = row[9][2], b = row[9][3]}},
                    bloom = {intensity = row[10], strength_factor = 1.2, radius = 2.8},
                    volumetric_light = {strength = 0}},
                sun = {visible = true},
                sky = {type = "regular", clouds = true, auto_dim_skybox = true,
                    sky_color = {day_sky = row[4], day_horizon = row[5], dawn_sky = row[4], dawn_horizon = row[5]},
                    fog = {fog_color = row[5] .. "ff", fog_start = 0.65, fog_distance = row[11]}},
                clouds = {color = row[5] .. "de", density = row[3] == "Swamp" and 0.55 or 0.25},
            })
            local night = lighthouse.merge(get_profile("Forest Night"), {
                lighting = {saturation = math.max(0.8, row[7] * 0.9), static = {ao_gamma = math.max(1.3, row[8])},
                    shadows = {intensity = 0.26, tint = {r = row[9][1], g = row[9][2], b = row[9][3]}},
                    bloom = {intensity = row[10], strength_factor = 1.2, radius = 2.8},
                    volumetric_light = {strength = 0}},
                sky = {sky_color = {night_sky = row[6], night_horizon = brighten(row[6], 12),
                        indoors = row[6], fog_tint_type = "custom", fog_moon_tint = brighten(row[6], 8)},
                    fog = {fog_color = row[6] .. "ff", fog_start = 0.6, fog_distance = math.min(row[11], 240)}},
                clouds = {color = brighten(row[6], 24) .. "b0", ambient = "#000000", shadow = row[6], density = 0.2},
            })
            day_name = lighthouse.add_biome_profile(title .. " Day", day, "Daylight and colors suited to this biome.")
            night_name = lighthouse.add_biome_profile(title .. " Night", night, "Dark mist with visible local lights.")
        end
        families[id] = {id = id, title = title, day = day_name, night = night_name,
            late = late_name, late_label = late_name and (row.labels and row.labels.late or "Late")}
        scene_names[day_name], scene_names[night_name] = true, true
    end

    lighthouse.biome_families = families
    lighthouse.register_biome_variants()
    for _, family in pairs(families) do
        for _, name in pairs(family.phases) do scene_names[name] = true end
    end
    lighthouse.biome_scene_names = scene_names

    function lighthouse.get_biome_family(biome)
        if type(biome) ~= "string" then return nil end
        if families[biome] then return families[biome] end
        for _, suffix in ipairs(suffixes) do
            if biome:sub(-#suffix) == suffix then
                return families[biome:sub(1, -#suffix - 1)]
            end
        end
    end
end