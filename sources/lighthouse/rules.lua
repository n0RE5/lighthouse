local function add_rule(name, definition)
    local ok, message = lighthouse.register_environment(name, definition)
    if not ok then
        error("[Lighthouse] Rule " .. name .. ": " .. tostring(message))
    end
end

function lighthouse.register_lighthouse_rules()
    local families = lighthouse.biome_families
    local suffixes = {"_beach", "_shore", "_dunes", "_highland", "_swamp", "_floatland", "_ocean", "_under", "_cave"}
    local night_start = (18 * 60 + 45) / (24 * 60) -- 18:45
    local periods = {
        {key = "dawn", from = 0.2, to = 0.3},
        {key = "day", from = 0.3, to = 0.65},
        {key = "late", from = 0.65, to = 0.75},
        {key = "dusk", from = 0.75, to = night_start},
        {key = "night", from = night_start, to = 0.2},
    }
    lighthouse.biome_periods = periods
    add_rule("underground", {scene = "Underground", y_max = -10, priority = 60})
    add_rule("deep_cave", {scene = "Deep Cave", y_max = -100, priority = 65})
    add_rule("underwater", {scene = "Underwater", priority = 70, underwater = true})

    for state, scene in pairs({cloudy = "Cloudy", overcast = "Overcast", fog = "Foggy", rain = "Light Rain", heavy_rain = "Heavy Rain", thunderstorm = "Thunderstorm", snow = "Snowfall", blizzard = "Blizzard"}) do
        add_rule("weather_" .. state, {scene = scene, weather = {state}, priority = 40, transition = 5})
    end

    for id, family in pairs(families) do
        if id ~= "caves" then
            local names = {id}
            local aliases = {
                deciduous_forest={"Forest", "BirchForest", "RoofedForest"},
                taiga={"Taiga"}, rainforest={"Jungle"}, desert={"Desert"}, mesa={"Mesa"},
                snowy_grassland={"IcePlains", "SnowyPlains"}, coniferous_forest={"SnowyTaiga"},
                swamp={"Swamp", "Swampland", "MangroveSwamp"},
                mushroom={"MushroomIsland", "MushroomIslandShore"},
            }
            for _, name in ipairs(aliases[id] or {}) do names[#names + 1] = name end
            for _, suffix in ipairs(suffixes) do names[#names + 1] = id .. suffix end
            for _, period in ipairs(periods) do
                local ocean = id == "ocean"
                add_rule("biome_" .. id .. "_" .. period.key, {
                    scene = family.phases[period.key], biomes = not ocean and names or nil,
                    priority = ocean and 26 or (id:find("_", 1, true) and 23 or 22),
                    env_check = ocean and function(context)
                        return context.ocean == true
                    end or nil,
                    time = {from = period.from, to = period.to}, transition = 5,
                })
            end
        end
    end
end