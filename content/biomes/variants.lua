function lighthouse.register_biome_variants()
    local families = lighthouse.biome_families
    local warm = {grassland=true, deciduous_forest=true, grassytwo=true, prairie=true,
        plains=true, grove=true, mediterranean=true, savanna=true, mesa=true,
        mesa_redwood=true, desert=true, sandstone_desert=true}
    local wet = {rainforest=true, rainforest_swamp=true, swamp=true, mangrove=true}
    local cold = {frost=true, taiga=true, tundra=true, icesheet=true, snowy_grassland=true,
        cold_desert=true, mountain=true, coniferous_forest=true}
    local violet = {mushroom=true, magical_forest=true, bamboo=true}
    local function mix(first, second, weight)
        local result = "#"
        for offset = 2, 6, 2 do
            local a, b = tonumber(first:sub(offset,offset+1),16), tonumber(second:sub(offset,offset+1),16)
            result = result .. ("%02x"):format(math.floor(a + (b-a)*weight + 0.5))
        end
        return result
    end
    local function atmosphere(base, sky, horizon, tint, strength)
        return lighthouse.merge(base, {
            lighting = {shadows = {intensity = strength}, volumetric_light = {strength = 0}},
            sun = {visible=true},
            sky = {sky_color = {day_sky=sky, day_horizon=horizon, dawn_sky=sky, dawn_horizon=horizon},
                fog = {fog_color = horizon:sub(1,7) .. "ff"}},
            clouds = {color = tint:sub(1,7) .. "d8"},
        })
    end
    for id, family in pairs(families) do
        if id == "caves" then
            family.phases = {underground=family.day, deep=family.night}
            family.labels = {underground="Underground", deep="Deep Cave"}
        else
            local day = lighthouse.get_scene_profile(family.day)
            local sky, horizon = day.sky.sky_color.day_sky, day.sky.sky_color.day_horizon
            local dawn_sky = mix(sky, violet[id] and "#b4a1cf" or "#b5b5cb", 0.35)
            local dawn_horizon = mix(horizon, wet[id] and "#bbc9bf" or (cold[id] and "#d3cadf" or "#e2bdac"), 0.4)
            local dawn = atmosphere(day, dawn_sky, dawn_horizon, dawn_horizon, 0.3)
            local dusk_sky = mix(sky, violet[id] and "#866a9e" or "#788da9", 0.55)
            local dusk_horizon = mix(horizon, wet[id] and "#879c99" or (cold[id] and "#acb8ce" or "#c3a5b6"), 0.55)
            local dusk = atmosphere(day, dusk_sky, dusk_horizon, dusk_horizon, 0.28)
            local late, late_label
            if family.late then
                late_label = family.late_label
            elseif warm[id] then
                local golden = lighthouse.get_scene_profile("Golden Hour")
                local late_sky = mix(sky, golden.sky.sky_color.day_sky, 0.45)
                local late_horizon = mix(horizon, golden.sky.sky_color.day_horizon, 0.55)
                late = atmosphere(day, late_sky, late_horizon, late_horizon, 0.42)
                late_label = "Golden Hour"
            elseif wet[id] then
                local template = lighthouse.get_preset(id == "rainforest" and "Heavy Rain" or "Foggy")
                late = lighthouse.merge(template, {
                    lighting = {static = day.lighting.static, volumetric_light = {strength=0}},
                    sky = {fog = {fog_color=mix(horizon,"#94aaa6",0.65).."ff", fog_distance=150, fog_start=0.4}},
                    sun = {visible=true},
                })
                late_label = id == "rainforest" and "Monsoon" or "Wet Mist"
            elseif cold[id] then
                late = atmosphere(day, mix(sky,"#8cabc8",0.4), mix(horizon,"#bdcbe0",0.45), "#b5c4da", 0.3)
                late_label = id == "frost" and "Crystal Glow" or "Blue Haze"
            elseif violet[id] then
                late = atmosphere(day, mix(sky,"#a18bc4",0.4), mix(horizon,"#c7a8cd",0.45), "#ceb8d7", 0.32)
                late_label = "Violet Haze"
            elseif id == "grayness" then
                late = lighthouse.merge(lighthouse.get_preset("Overcast"), {
                    lighting = {static=day.lighting.static},
                    sky = {fog={fog_color="#aebbb7ff",fog_distance=190,fog_start=0.5}},
                })
                late_label = "Silver Mist"
            elseif id == "fiery" then
                late = atmosphere(day, "#a99a93", "#c3a78c", "#bba591", 0.4)
                late_label = "Dust Veil"
            else
                late = atmosphere(day, mix(sky,"#a6c2d9",0.2), horizon, horizon, 0.32)
                late_label = "Sea Haze"
            end
            family.phases = {day=family.day, night=family.night}
            family.labels = {dawn=wet[id] and "Mist Dawn" or (violet[id] and "Lavender Dawn" or "Sunrise"),
                day="Day", late=late_label, dusk=violet[id] and "Crimson Dusk" or "Dusk", night="Night"}
            if violet[id] then
                dusk = atmosphere(day, mix(sky,"#876284",0.5), mix(horizon,"#bc8eaa",0.5), "#b99ab9", 0.28)
            end
            family.phases.dawn = lighthouse.add_biome_profile(family.title .. " " .. family.labels.dawn, dawn,
                "Early light and mist.")
            family.phases.dusk = lighthouse.add_biome_profile(family.title .. " " .. family.labels.dusk, dusk,
                "Soft evening light.")
            family.phases.late = family.late or lighthouse.add_biome_profile(family.title .. " " .. late_label, late,
                wet[id] and "Dense mist." or "Late afternoon atmosphere.")
        end
    end
end