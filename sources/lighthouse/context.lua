local function collect_node_names()
    local names, seen = {}, {}
    for _, name in ipairs(lighthouse.ocean_water_nodes) do
        seen[name] = true
        names[#names + 1] = name
    end
    for _, definition in pairs(lighthouse.environments) do
        for _, name in ipairs(definition.nodes or {}) do
            if not seen[name] then
                seen[name] = true
                names[#names + 1] = name
            end
        end
    end
    return names
end

function lighthouse.get_environment_context(player)
    local state = lighthouse.get_player_state(player)
    local pos = player:get_pos()
    local node_pos = vector.round(pos)
    local cache = state.context
    local weather, source = lighthouse.get_weather(player)
    if cache and vector.equals(cache.node_pos, node_pos)
            and lighthouse.current_time - cache.checked_at < lighthouse.config.check_interval then
        cache.timeofday = core.get_timeofday()
        cache.weather, cache.weather_source = weather, source
        return cache
    end
    local biome_data = core.get_biome_data(pos)
    local head = core.get_node_or_nil({x = pos.x, y = pos.y + 1.5, z = pos.z})
    local definition = head and core.registered_nodes[head.name]
    local check_def = {
        player = player,
        pos = pos,
        node_pos = node_pos,
        checked_at = lighthouse.current_time,
        timeofday = core.get_timeofday(),
        biome = biome_data and core.get_biome_name(biome_data.biome) or "",
        loaded = biome_data ~= nil and head ~= nil and head.name ~= "ignore",
        weather = weather,
        weather_source = source,
        underwater = definition and definition.liquidtype ~= nil and definition.liquidtype ~= "none" or false,
        totals = {},
        positions = {},
    }
    local nodes = collect_node_names()
    if check_def.loaded then
        local radius = lighthouse.config.detection_radius
        check_def.positions, check_def.totals = core.find_nodes_in_area(
            vector.subtract(node_pos, radius), vector.add(node_pos, radius), nodes)
        check_def.ocean, check_def.ocean_water_count = lighthouse.detect_ocean(node_pos, check_def.totals)
        -- Group selectors are aggregated once so callbacks and nodes_min share the same totals.
        for _, selector in ipairs(nodes) do
            local group = selector:match("^group:(.+)$")
            if group then
                local count = 0
                for node, total in pairs(check_def.totals) do
                    if not node:match("^group:") and core.get_item_group(node, group) > 0 then
                        count = count + total
                    end
                end
                check_def.totals[selector] = count
            end
        end
    end
    state.context = check_def
    return check_def
end