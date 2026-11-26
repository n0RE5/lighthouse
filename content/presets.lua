function lighthouse.register_builtin_presets()
    local function get_profile(name)
        local profile, message = lighthouse.get_preset(name)
        if not profile then error("[Lighthouse] Built-in profile " .. name .. ": " .. tostring(message)) end
        return profile
    end
    local natural = {
        lighting = {
            saturation = 1,
            shadows = {intensity = 0.32},
            bloom = {intensity = 0.12, strength_factor = 1.25, radius = 2},
            volumetric_light = {strength = 0.05},
        },
    }

    local function register_profile(name, patch, base)
        local profile = lighthouse.merge(base or natural, patch)
        profile = lighthouse.style_builtin_profile(name, profile)
        lighthouse.add_builtin_profile(name, profile)
    end

    lighthouse.add_builtin_profile("Default", lighthouse.defaults)
    register_profile("Natural Day", {lighting = {volumetric_light = {strength = 0.05}}})
    register_profile("Vibrant Day", {lighting = {saturation = 1.18, shadows = {intensity = 0.28}}})
    register_profile("Cinematic", {
        lighting = {
            saturation = 0.92,
            shadows = {intensity = 0.48, tint = {r = 12, g = 16, b = 24}},
            bloom = {intensity = 0.16, strength_factor = 1.25, radius = 2.3},
            volumetric_light = {strength = 0.07},
            exposure = {exposure_correction = -0.15},
        },
    })
    register_profile("Classic", {lighting = {shadows = {intensity = 0}, bloom = {intensity = 0}, volumetric_light = {strength = 0}}})
    register_profile("Soft Fantasy", {
        lighting = {saturation = 1.06, shadows = {intensity = 0.2}, bloom = {intensity = 0.22, strength_factor = 1.3, radius = 2.6}, volumetric_light = {strength = 0.08}},
        sky = {sky_color = {day_sky = "#83bde5", day_horizon = "#c4dfef"}},
    })
    register_profile("Dark Fantasy", {
        lighting = {saturation = 0.78, shadows = {intensity = 0.52}, exposure = {exposure_correction = -0.2}},
        sky = {sky_color = {day_sky = "#788993", day_horizon = "#a4aeb7"}},
        clouds = {density = 0.65, color = "#bcc5cfe0"},
    })
    register_profile("Sunrise", {
        sky = {sky_color = {day_sky = "#c4bdce", day_horizon = "#e7bd97", dawn_sky = "#d4bad1", dawn_horizon = "#eab786"}},
        lighting = {shadows = {intensity = 0.26}, saturation = 0.98},
        clouds = {color = "#e6d2c6da", density = 0.25},
    })
    register_profile("Clear Morning", {
        sky = {sky_color = {day_sky = "#82bdeb", day_horizon = "#bddbed"}},
        clouds = {density = 0.22, color = "#edece6da"},
    })
    register_profile("Midday", {lighting = {shadows = {intensity = 0.38}}, clouds = {density = 0.15}})
    register_profile("Afternoon", {sky = {sky_color = {day_sky = "#72afe1", day_horizon = "#bdd3df"}}, clouds = {density = 0.3}})
    register_profile("Golden Hour", {
        lighting = {saturation = 1.06, shadows = {intensity = 0.42, tint = {r = 20, g = 15, b = 9}},
            bloom = {intensity = 0.18, strength_factor = 1.2, radius = 2.8}, volumetric_light = {strength = 0}},
        sun = {visible = true},
        sky = {sky_color = {day_sky = "#b9b3c3", day_horizon = "#e8c59b", dawn_horizon = "#dba276"}},
        clouds = {color = "#e3c8a9df", density = 0.22},
    })
    register_profile("Sunset", {
        lighting = {saturation = 0.95, shadows = {intensity = 0.34}},
        sky = {sky_color = {day_sky = "#a78ea9", day_horizon = "#dba486", dawn_sky = "#b199ba", dawn_horizon = "#d89b7d"}},
        clouds = {color = "#c9a7acdd", density = 0.3},
    })
    register_profile("Blue Hour", {
        lighting = {saturation = 0.86, shadows = {intensity = 0.3, tint = {r = 9, g = 15, b = 25}}},
        sky = {sky_color = {day_sky = "#6e83ac", day_horizon = "#9ba9c4", dawn_sky = "#8999bd", dawn_horizon = "#9faac4"}},
        clouds = {color = "#acb7d0d8"},
        stars = {day_opacity = 0.08, star_color = "#cbdcff80"},
    })
    register_profile("Moonlit Night", {
        lighting = {saturation = 0.82, shadows = {intensity = 0.24}, volumetric_light = {strength = 0}},
        sky = {sky_color = {night_sky = "#224578", night_horizon = "#4c6591"}},
        stars = {count = 1800, star_color = "#dbe6ff90"},
        moon = {scale = 1.15},
        clouds = {density = 0.18, color = "#aab8d4c8"},
    })
    register_profile("Dark Night", {
        lighting = {saturation = 0.72, shadows = {intensity = 0.36}, volumetric_light = {strength = 0}},
        sky = {sky_color = {night_sky = "#112844", night_horizon = "#294062"}},
        stars = {count = 2200, star_color = "#dbe7ff88"},
        clouds = {density = 0.12},
    })

    local overcast = {
        lighting = {saturation = 0.88, shadows = {intensity = 0.12}, bloom = {intensity = 0.1, strength_factor = 1.35, radius = 2}, volumetric_light = {strength = 0}},
        sky = {sky_color = {day_sky = "#a3b0bc", day_horizon = "#bbc5cd", dawn_sky = "#a9aab9", dawn_horizon = "#beb3b0"}},
        clouds = {density = 0.9, color = "#bdc7d1ee", thickness = 28},
    }
    register_profile("Cloudy", {
        clouds = {density = 0.6, color = "#d2dbe2e5", thickness = 22},
        lighting = {saturation = 0.97, shadows = {intensity = 0.2}, volumetric_light = {strength = 0.06}},
    })
    register_profile("Overcast", overcast)
    register_profile("Foggy", {
        sky = {fog = {fog_start = 0.15, fog_distance = 120, fog_color = "#b8c6cfff"}},
        clouds = {density = 0.55},
        lighting = {saturation = 0.9, shadows = {intensity = 0.14}},
    })
    register_profile("Light Rain", {
        sky = {fog = {fog_start = 0.45, fog_distance = 180, fog_color = "#9facbaff"}},
        clouds = {density = 0.85, speed = {x = 1, z = -3}},
    }, overcast)
    register_profile("Heavy Rain", {
        lighting = {saturation = 0.78, exposure = {exposure_correction = -0.12}},
        sky = {fog = {fog_start = 0.25, fog_distance = 100, fog_color = "#8798a8ff"}},
        clouds = {density = 1, color = "#8f9dacee", speed = {x = 2, z = -5}},
    }, overcast)
    register_profile("Thunderstorm", {
        lighting = {saturation = 0.72, exposure = {exposure_correction = -0.25}, shadows = {intensity = 0.08}},
        sky = {sky_color = {day_sky = "#627585", day_horizon = "#81909e"}, fog = {fog_start = 0.2, fog_distance = 85, fog_color = "#718392ff"}},
        clouds = {density = 1, color = "#7e8a99ef", thickness = 36, speed = {x = 3, z = -6}},
    }, overcast)
    register_profile("Snowfall", {
        lighting = {saturation = 0.86, shadows = {intensity = 0.12}},
        sky = {sky_color = {day_sky = "#b3c7d8", day_horizon = "#d2dfe8"}, fog = {fog_start = 0.4, fog_distance = 160, fog_color = "#c6d6e2ff"}},
        clouds = {density = 0.8, color = "#d6e0e8ec"},
    })
    register_profile("Blizzard", {
        sky = {sky_color = {day_sky = "#a3b6c6", day_horizon = "#bccbd7"}, fog = {fog_start = 0.1, fog_distance = 55, fog_color = "#b1c5d5ff"}},
        lighting = {saturation = 0.72, shadows = {intensity = 0.05}},
        clouds = {density = 1, speed = {x = 5, z = -8}, color = "#bdccd9ee"},
    })

    register_profile("Forest Day", {lighting = {saturation = 1.04, shadows = {intensity = 0.4}}, sky = {sky_color = {day_sky = "#78afd2"}}})
    register_profile("Forest Night", {lighting = {saturation = 0.78, shadows = {intensity = 0.3}}, clouds = {density = 0.25}}, get_profile("Moonlit Night"))
    register_profile("Desert Day", {lighting = {saturation = 0.94}, sky = {sky_color = {day_sky = "#91bddb", day_horizon = "#dccab2"}}, clouds = {density = 0.05}})
    register_profile("Desert Night", {sky = {sky_color = {night_sky = "#263b65", night_horizon = "#66698b"}}, clouds = {density = 0.03}, stars = {count = 2600}}, get_profile("Moonlit Night"))
    register_profile("Snowy Plains", {lighting = {saturation = 0.92, shadows = {intensity = 0.25, tint = {r = 13, g = 22, b = 35}}}, sky = {sky_color = {day_sky = "#a1c3dd"}}, clouds = {density = 0.25}})
    register_profile("Swamp", {lighting = {saturation = 0.85, shadows = {intensity = 0.25}}, sky = {fog = {fog_distance = 160, fog_start = 0.4, fog_color = "#a6b7a4ff"}}, clouds = {density = 0.65}})
    register_profile("Underground", {lighting = {saturation = 0.93, shadows = {intensity = 0}, volumetric_light = {strength = 0}}, sky = {clouds = false}, sun = {visible = false}, moon = {visible = false}, stars = {visible = false}})
    register_profile("Deep Cave", {lighting = {saturation = 0.82, shadows = {intensity = 0}, volumetric_light = {strength = 0}, static = {light_curve = lighthouse.curve("Deep Darkness")}}, sky = {clouds = false}, sun = {visible = false}, moon = {visible = false}, stars = {visible = false}})
    register_profile("Underwater", {lighting = {saturation = 0.84, shadows = {intensity = 0.12}}, sky = {fog = {fog_distance = 45, fog_start = 0.25, fog_color = "#497b92ff"}}, clouds = {density = 0}})
    register_profile("Magical Forest", {lighting = {saturation = 1.12, bloom = {intensity = 0.24, strength_factor = 1.35, radius = 3.2}, volumetric_light = {strength = 0.08}}, sky = {fog = {fog_distance = 180, fog_start = 0.6, fog_color = "#a6c5b7ff"}}})
    register_profile("Magical Forest Night", {
        lighting = {
            saturation = 0.95,
            exposure = {exposure_correction = -0.35},
            bloom = {intensity = 0.22, strength_factor = 1.3, radius = 3},
        },
        sky = {
            sky_color = {night_sky = "#100d20", night_horizon = "#231936", indoors = "#15131e",
                fog_tint_type = "custom", fog_moon_tint = "#30253f"},
            fog = {fog_distance = 160, fog_start = 0.5, fog_color = "#171326ff"},
        },
        clouds = {density = 0.3, color = "#514263b0", ambient = "#000000", shadow = "#191422"},
    }, get_profile("Forest Night"))

    register_profile("Dreamscape", {
        lighting = {
            saturation = 1.12, shadows = {intensity = 0.2},
            bloom = {intensity = 0.18, strength_factor = 1.2, radius = 2.8},
            volumetric_light = {strength = 0},
        },
        sun = {visible = true},
        sky = {sky_color = {day_sky = "#af96dc", day_horizon = "#f5ccdd"}},
        clouds = {density = 0.3, color = "#dac7e4ce"},
    })
    register_profile("Liminal Mushroom Day", {
        lighting = {
            saturation = 1.13, shadows = {intensity = 0.3, tint = {r = 19, g = 13, b = 31}},
            exposure = {exposure_correction = -0.15},
            bloom = {intensity = 0.18, strength_factor = 1.2, radius = 2.8},
            volumetric_light = {strength = 0},
        },
        sun = {visible = true},
        sky = {
            type = "plain", base_color = "#808e9d", clouds = false, auto_dim_skybox = false,
            sky_color = {day_sky = "#6b8eac", day_horizon = "#b3b5b3",
                dawn_sky = "#9185a8", dawn_horizon = "#b49fae",
                fog_tint_type = "custom", fog_sun_tint = "#b5bac5"},
            fog = {fog_distance = 155, fog_start = 0.35, fog_color = "#808e9dff"},
        },
        clouds = {density = 0.38, color = "#b5acccce", shadow = "#68637a"},
    })
    register_profile("Liminal Mushroom Night", {
        lighting = {
            saturation = 1.04, exposure = {exposure_correction = -0.4},
            bloom = {intensity = 0.18, strength_factor = 1.2, radius = 2.8},
            volumetric_light = {strength = 0},
        },
        sky = {
            type = "plain", base_color = "#211629", clouds = false, auto_dim_skybox = false,
            sky_color = {night_sky = "#100c20", night_horizon = "#2a1738", indoors = "#151321",
                fog_tint_type = "custom", fog_moon_tint = "#362546"},
            fog = {fog_distance = 125, fog_start = 0.4, fog_color = "#211629ff"},
        },
        clouds = {density = 0.28, color = "#4b355ab0", ambient = "#050409", shadow = "#191122"},
        stars = {count = 2000, star_color = "#dac8ff90"},
    }, get_profile("Magical Forest Night"))

    register_profile("Bright Nights", {lighting = {static = {light_curve = lighthouse.curve("Bright Nights")}, shadows = {intensity = 0.18}}})
    register_profile("High Contrast", {lighting = {static = {light_curve = lighthouse.curve("High Contrast", 1.2)}, shadows = {intensity = 0.42}}})
    register_profile("Monochrome", {lighting = {saturation = 0}})

    local scene_groups = {
        {"Essentials", {"Default", "Natural Day", "Vibrant Day", "Cinematic", "Classic", "Soft Fantasy", "Dark Fantasy", "Dreamscape"}},
        {"Time of day", {"Sunrise", "Clear Morning", "Midday", "Afternoon", "Golden Hour", "Sunset", "Blue Hour", "Moonlit Night", "Dark Night"}},
        {"Weather", {"Cloudy", "Overcast", "Foggy", "Light Rain", "Heavy Rain", "Thunderstorm", "Snowfall", "Blizzard"}},
        {"Places", {"Forest Day", "Forest Night", "Desert Day", "Desert Night", "Snowy Plains", "Swamp", "Underground", "Deep Cave", "Underwater", "Magical Forest", "Magical Forest Night", "Liminal Mushroom Day", "Liminal Mushroom Night"}},
    }
    local descriptions = {
        ["Dreamscape"] = "Pastel violet sky, broad luminous halos.",
        ["Golden Hour"] = "Warm sky and glowing highlights.",
        ["Magical Forest"] = "Daytime enchanted woodland with a pale green mist.",
        ["Magical Forest Night"] = "Dark violet mist and natural night lighting.",
        ["Liminal Mushroom Day"] = "Cool mist, broad dreamlike bloom.",
        ["Liminal Mushroom Night"] = "Deep purple mist and a glow around bright mushrooms.",
        ["Natural Day"] = "Balanced color, readable shadows, gentle glow and sun rays.",
        ["Cinematic"] = "Cool shadows, glowing highlights and visible sun rays.",
        ["Soft Fantasy"] = "Pastel sky with broad soft glow and sun rays.",
        ["Thunderstorm"] = "Dark clouds and reduced visibility.",
        ["Snowfall"] = "Cold colors and pale fog.",
        ["Deep Cave"] = "Deeper darkness while keeping lit surfaces readable.",
    }
    for _, group in ipairs(scene_groups) do
        for _, name in ipairs(group[2]) do
            lighthouse.add_builtin_scene(name, {
                profile = name,
                category = group[1],
                description = descriptions[name] or (name .. " lighting and atmosphere."),
                transition = 5,
            })
        end
    end
    lighthouse.add_builtin_scene("Foggy Morning", {profile = "Foggy", category = "Weather", description = "Soft fog for a quiet morning."})
    lighthouse.add_builtin_scene("Clear Day", {profile = "Natural Day", category = "Essentials", description = "Neutral daylight."})
    lighthouse.add_builtin_scene("Clear Night", {profile = "Dark Night", category = "Time of day", description = "Clear stars and darker surroundings."})
    lighthouse.add_builtin_scene("Rainy Day", {profile = "Light Rain", category = "Weather", description = "Rain atmosphere."})
    lighthouse.add_builtin_scene("Dark Forest", {profile = "Forest Night", category = "Places", description = "A cool, shaded woodland."})
end