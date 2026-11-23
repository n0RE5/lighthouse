local function finite(value, minimum, maximum)
    return type(value) == "number" and value == value and value >= minimum and value <= maximum
end

local function string_list(value)
    if type(value) ~= "table" or #value > 128 then
        return false
    end
    local count = 0
    for index, item in pairs(value) do
        count = count + 1
        if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #value
                or type(item) ~= "string" or #item > 128 then
            return false
        end
    end
    return count == #value
end

local function contains(list, value)
    for _, item in ipairs(list) do
        if item == value then
            return true
        end
    end
    return false
end

function lighthouse.time_matches(timeofday, interval)
    if not interval then
        return true
    end
    if interval.from == interval.to then
        return true
    end
    if interval.from < interval.to then
        return timeofday >= interval.from and timeofday < interval.to
    end
    return timeofday >= interval.from or timeofday < interval.to
end

local condition_keys = {
    profile = true, description = true, category = true, priority = true, transition = true,
    biomes = true, time = true, weather = true, y_min = true, y_max = true,
    nodes = true, nodes_min = true, zone = true, env_check = true,
    scene = true, automatic = true,
    underwater = true,
}

-- Definitions from Lua may use callbacks. JSON/UI definitions use only serializable conditions.
function lighthouse.validate_environment(definition)
    if type(definition) ~= "table" then
        return nil, "Environment must be a table"
    end
    local result = lighthouse.copy(definition)
    for key in pairs(result) do
        if not condition_keys[key] then
            return nil, "Unknown environment field: " .. tostring(key)
        end
    end
    for _, key in ipairs({"biomes", "weather", "nodes"}) do
        if result[key] ~= nil and not string_list(result[key]) then
            return nil, key .. " must be a list of names"
        end
    end
    if result.weather then
        for _, name in ipairs(result.weather) do
            if not lighthouse.weather_states[name] then
                return nil, "Unknown weather state: " .. name
            end
        end
    end
    for _, key in ipairs({"description", "category", "scene"}) do
        if result[key] ~= nil and (type(result[key]) ~= "string" or #result[key] > 200 or result[key]:find("[%c]")) then
            return nil, "Invalid " .. key
        end
    end
    if result.env_check ~= nil and type(result.env_check) ~= "function" then
        return nil, "env_check must be a function"
    end
    if result.automatic ~= nil and type(result.automatic) ~= "boolean" then
        return nil, "automatic must be boolean"
    end
    if result.underwater ~= nil and type(result.underwater) ~= "boolean" then
        return nil, "underwater must be boolean"
    end
    for _, key in ipairs({"y_min", "y_max"}) do
        if result[key] ~= nil and not finite(result[key], -31000, 31000) then
            return nil, "Invalid height"
        end
    end
    if result.y_min and result.y_max and result.y_min > result.y_max then
        return nil, "Minimum height exceeds maximum"
    end
    if result.nodes_min ~= nil and not finite(result.nodes_min, 1, 4096) then
        return nil, "Invalid node count"
    end
    if result.time then
        if type(result.time) ~= "table" or not finite(result.time.from, 0, 1)
                or not finite(result.time.to, 0, 1) then
            return nil, "Time interval needs from/to in 0-1"
        end
        for key in pairs(result.time) do
            if key ~= "from" and key ~= "to" then
                return nil, "Unknown time field"
            end
        end
    end
    if result.zone then
        if type(result.zone) ~= "table" then
            return nil, "Zone needs min and max positions"
        end
        for _, corner in ipairs({"min", "max"}) do
            if type(result.zone[corner]) ~= "table" then
                return nil, "Zone needs min and max positions"
            end
            for _, axis in ipairs({"x", "y", "z"}) do
                if not finite(result.zone[corner][axis], -31000, 31000) then
                    return nil, "Invalid zone coordinate"
                end
            end
        end
        for _, axis in ipairs({"x", "y", "z"}) do
            if result.zone.min[axis] > result.zone.max[axis] then
                return nil, "Zone min exceeds max"
            end
        end
    end
    result.priority = result.priority or 0
    result.transition = result.transition or 5
    if not finite(result.priority, -1000, 1000) or not finite(result.transition, 0, 60) then
        return nil, "Priority must be -1000..1000, transition 0..60 seconds"
    end
    return result
end

-- Register a reusable scene. Profile names remain references instead of copied settings.
function lighthouse.register_scene(name, definition)
    if not lighthouse.valid_name(name) then
        return nil, "Invalid scene name"
    end
    local checked, message = lighthouse.validate_environment(definition)
    if not checked then
        return nil, message
    end
    if type(checked.profile) == "table" then
        checked.profile, message = lighthouse.validate(checked.profile, "full")
        if not checked.profile then
            return nil, message
        end
    elseif type(checked.profile) ~= "string" or not lighthouse.get_preset(checked.profile) then
        return nil, "Scene needs a registered profile"
    end
    checked.description = checked.description or name
    checked.category = checked.category or "Custom"
    lighthouse.scenes[name] = checked
    if checked.automatic then
        lighthouse.environments[name] = lighthouse.merge(checked, {scene = name})
    end
    return true
end

function lighthouse.register_environment(name, definition)
    if not lighthouse.valid_name(name) then
        return nil, "Invalid environment name"
    end
    local checked, message = lighthouse.validate_environment(definition)
    if not checked then
        return nil, message
    end
    if not checked.scene or not lighthouse.scenes[checked.scene] then
        return nil, "Environment needs a registered scene"
    end
    lighthouse.environments[name] = checked
    return true
end

function lighthouse.get_scene_profile(name)
    local scene = lighthouse.scenes[name]
    if not scene then
        return nil, "Unknown scene: " .. tostring(name)
    end
    local profile = scene.profile
    if type(profile) == "string" then
        profile = lighthouse.get_preset(profile)
    end
    if not profile then
        return nil, "Scene profile is unavailable"
    end
    return lighthouse.validate(profile, "full")
end

function lighthouse.matches_environment(definition, check_def)
    if definition.underwater ~= nil and definition.underwater ~= (check_def.underwater == true) then
        return false
    end
    if definition.biomes and #definition.biomes > 0 and not contains(definition.biomes, check_def.biome) then
        return false
    end
    if not lighthouse.time_matches(check_def.timeofday, definition.time) then
        return false
    end
    if definition.y_min and check_def.pos.y < definition.y_min then
        return false
    end
    if definition.y_max and check_def.pos.y > definition.y_max then
        return false
    end
    if definition.weather and not contains(definition.weather, check_def.weather) then
        return false
    end

    if definition.zone then
        for _, axis in ipairs({"x", "y", "z"}) do
            if check_def.pos[axis] < definition.zone.min[axis] or check_def.pos[axis] > definition.zone.max[axis] then
                return false
            end
        end
    end
    if definition.nodes and #definition.nodes > 0 then
        local count = 0
        for _, node in ipairs(definition.nodes) do
            count = count + ((check_def.totals or {})[node] or 0)
        end
        if count < (definition.nodes_min or 1) then
            return false
        end
    end
    local callback = definition.env_check
    if callback then
        local ok, matches = pcall(callback, check_def)
        if not ok then
            error("Environment callback failed: " .. tostring(matches))
        end
        return matches == true
    end
    return true
end

function lighthouse.select_environment(check_def)
    local selected_name, selected
    for name, definition in pairs(lighthouse.environments) do
        if lighthouse.matches_environment(definition, check_def) then
            if not selected or definition.priority > selected.priority
                    or (definition.priority == selected.priority and name < selected_name) then
                selected_name, selected = name, definition
            end
        end
    end
    return selected_name, selected
end