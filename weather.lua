local weather_override
local source_order = {}
local function finite(value, minimum, maximum)
    return type(value) == "number" and value == value and value >= minimum and value <= maximum
end

function lighthouse.register_weather_source(name, callback, priority)
    if not lighthouse.valid_name(name) or type(callback) ~= "function"
            or not finite(priority or 0, -1000, 1000) then
        return nil, "Invalid weather source"
    end
    lighthouse.weather_sources[name] = {callback = callback, priority = priority or 0}
    source_order = {}
    for source in pairs(lighthouse.weather_sources) do
        source_order[#source_order + 1] = source
    end
    table.sort(source_order, function(first, second)
        local a, b = lighthouse.weather_sources[first], lighthouse.weather_sources[second]
        return a.priority > b.priority or (a.priority == b.priority and first < second)
    end)
    return true
end

function lighthouse.get_weather(player)
    local state = lighthouse.get_player_state(player)
    for _, override in ipairs({state.weather or false, weather_override or false}) do
        if override and (not override.expires or lighthouse.current_time < override.expires) then
            return override.name, override.source
        end
    end
    for _, name in ipairs(source_order) do
        local source = lighthouse.weather_sources[name]
        if source then
            local ok, weather = pcall(source.callback, player)
            if not ok then error("Weather source failed: " .. name .. ": " .. tostring(weather)) end
            if weather ~= nil then
                if not lighthouse.weather_states[weather] then error("Invalid weather from source: " .. name) end
                return weather, name
            end
        end
    end
    return nil, nil
end

function lighthouse.set_weather(name, player, lifetime)
    if not lighthouse.weather_states[name] or (lifetime and not finite(lifetime, 0.1, 86400)) then
        return nil, "Invalid weather state or lifetime"
    end
    local override = {name = name, source = "explicit", expires = lifetime and lighthouse.current_time + lifetime}
    -- player=nil affects all players.
    if player then
        lighthouse.get_player_state(player).weather = override
        return lighthouse.update_environment(player, nil, true)
    end
    weather_override = override
    for _, connected_player in ipairs(core.get_connected_players()) do
        lighthouse.update_environment(connected_player, nil, true)
    end
    return true
end

function lighthouse.clear_weather(player)
    if player then
        lighthouse.get_player_state(player).weather = nil
        return lighthouse.update_environment(player, nil, true)
    end
    weather_override = nil
    for _, connected_player in ipairs(core.get_connected_players()) do
        lighthouse.update_environment(connected_player, nil, true)
    end
    return true
end