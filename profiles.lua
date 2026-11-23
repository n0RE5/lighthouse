lighthouse.categories = {"lighting", "sky", "sun", "moon", "stars", "clouds", "day_night"}

-- path, label, default, min, max, group, options
lighthouse.fields = {
    {"lighting.saturation", "Color richness", "number", 1, -3, 3, "Light"},
    {"lighting.shadows.intensity", "Shadow depth", "number", 0, 0, 1, "Light"},
    {"lighting.exposure.exposure_correction", "Brightness (EV)", "number", 0, -10, 10, "Effects"},
    {"lighting.exposure.luminance_min", "Minimum luminance", "number", -3, -16, 16, "Effects"},
    {"lighting.exposure.luminance_max", "Maximum luminance", "number", -3, -16, 16, "Effects"},
    {"lighting.exposure.speed_dark_bright", "Adapt to brightness", "number", 1000, 0.01, 1000, "Effects"},
    {"lighting.exposure.speed_bright_dark", "Adapt to darkness", "number", 1000, 0.01, 1000, "Effects"},
    {"lighting.exposure.center_weight_power", "Center weight", "number", 1, 0, 10, "Effects"},
    {"lighting.bloom.intensity", "Glow", "number", 0.05, 0, 1, "Effects"},
    {"lighting.bloom.strength_factor", "Glow strength", "number", 1, 0.1, 10, "Effects"},
    {"lighting.bloom.radius", "Glow spread", "number", 1, 0.1, 8, "Effects"},
    {"lighting.volumetric_light.strength", "Sun rays", "number", 0, 0, 1, "Effects"},
    {"lighting.static.ao_gamma", "Ambient shading (0 = off)", "number", 1.8, 0, 3, "Advanced"},
    {"lighting.static.light_curve", "Light curve", "curve", {}, nil, nil, "Advanced"},
    {"lighting.shadows.tint.r", "Shadow red", "integer", 0, 0, 255, "Advanced"},
    {"lighting.shadows.tint.g", "Shadow green", "integer", 0, 0, 255, "Advanced"},
    {"lighting.shadows.tint.b", "Shadow blue", "integer", 0, 0, 255, "Advanced"},
    {"lighting.shadows.direction.x", "Light direction X", "number", 0, -1, 1, "Advanced"},
    {"lighting.shadows.direction.y", "Light direction Y", "number", 0, -1, 1, "Advanced"},
    {"lighting.shadows.direction.z", "Light direction Z", "number", 0, -1, 1, "Advanced"},
    {"sky.type", "Sky style", "enum", "regular", nil, nil, "Atmosphere", {"regular", "plain", "skybox"}},
    {"sky.base_color", "Plain sky color", "color", "#ffffff", nil, nil, "Atmosphere"},
    {"sky.sky_color.day_sky", "Day sky", "color", "#61b5f5", nil, nil, "Atmosphere"},
    {"sky.sky_color.day_horizon", "Day horizon", "color", "#90d3f6", nil, nil, "Atmosphere"},
    {"sky.sky_color.dawn_sky", "Dawn sky", "color", "#b4bafa", nil, nil, "Atmosphere"},
    {"sky.sky_color.dawn_horizon", "Dawn horizon", "color", "#bac1f0", nil, nil, "Atmosphere"},
    {"sky.sky_color.night_sky", "Night sky", "color", "#006bff", nil, nil, "Atmosphere"},
    {"sky.sky_color.night_horizon", "Night horizon", "color", "#4090ff", nil, nil, "Atmosphere"},
    {"sky.sky_color.indoors", "Indoor sky", "color", "#646464", nil, nil, "Atmosphere"},
    {"sky.sky_color.fog_sun_tint", "Sun fog tint", "color", "#f47d1d", nil, nil, "Atmosphere"},
    {"sky.sky_color.fog_moon_tint", "Moon fog tint", "color", "#7f99cc", nil, nil, "Atmosphere"},
    {"sky.sky_color.fog_tint_type", "Fog tint style", "enum", "default", nil, nil, "Atmosphere", {"default", "custom"}},
    {"sky.fog.fog_color", "Fog color", "color", "#00000000", nil, nil, "Atmosphere"},
    {"sky.fog.fog_start", "Fog start (-1 = client)", "number", -1, -1, 0.99, "Atmosphere"},
    {"sky.fog.fog_distance", "Fog distance (-1 = client)", "integer", -1, -1, 10000, "Atmosphere"},
    {"sky.clouds", "Clouds visible", "boolean", true, nil, nil, "Atmosphere"},
    {"sky.auto_dim_skybox", "Dim skybox underground", "boolean", true, nil, nil, "Atmosphere"},
    {"sky.textures", "Skybox textures (six, separated by |)", "textures", {}, nil, nil, "Atmosphere"},
    {"sun.visible", "Sun visible", "boolean", true, nil, nil, "Atmosphere"},
    {"sun.scale", "Sun size", "number", 1, 0, 10, "Atmosphere"},
    {"sun.texture", "Sun texture", "string", "", nil, nil, "Advanced"},
    {"sun.tonemap", "Sun tonemap", "string", "sun_tonemap.png", nil, nil, "Advanced"},
    {"sun.sunrise", "Sunrise texture", "string", "sunrisebg.png", nil, nil, "Advanced"},
    {"sun.sunrise_visible", "Sunrise visible", "boolean", true, nil, nil, "Atmosphere"},
    {"moon.visible", "Moon visible", "boolean", true, nil, nil, "Atmosphere"},
    {"moon.scale", "Moon size", "number", 1, 0, 10, "Atmosphere"},
    {"moon.texture", "Moon texture", "string", "", nil, nil, "Advanced"},
    {"moon.tonemap", "Moon tonemap", "string", "moon_tonemap.png", nil, nil, "Advanced"},
    {"stars.visible", "Stars visible", "boolean", true, nil, nil, "Atmosphere"},
    {"stars.count", "Star count", "integer", 1000, 0, 16384, "Atmosphere"},
    {"stars.star_color", "Star color", "color", "#ebebff69", nil, nil, "Atmosphere"},
    {"stars.scale", "Star size", "number", 1, 0, 10, "Atmosphere"},
    {"stars.day_opacity", "Stars in daylight", "number", 0, 0, 1, "Atmosphere"},
    {"clouds.density", "Cloud coverage", "number", 0.4, 0, 1, "Atmosphere"},
    {"clouds.color", "Cloud color", "color", "#fff0f0e5", nil, nil, "Atmosphere"},
    {"clouds.ambient", "Cloud ambient color", "color", "#000000", nil, nil, "Atmosphere"},
    {"clouds.shadow", "Cloud underside", "color", "#cccccc", nil, nil, "Atmosphere"},
    {"clouds.height", "Cloud height", "number", 120, -31000, 31000, "Atmosphere"},
    {"clouds.thickness", "Cloud thickness", "number", 16, 0, 1000, "Atmosphere"},
    {"clouds.speed.x", "Wind X", "number", 0, -100, 100, "Atmosphere"},
    {"clouds.speed.z", "Wind Z", "number", -2, -100, 100, "Atmosphere"},
    {"day_night.enabled", "Fixed visual daylight", "boolean", false, nil, nil, "Light"},
    {"day_night.ratio", "Visual daylight", "number", 1, 0, 1, "Light"},
}

function lighthouse.copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = lighthouse.copy(child)
    end
    return result
end

function lighthouse.equal(first, second)
    if type(first) ~= type(second) then
        return false
    end
    if type(first) == "number" then
        return math.abs(first - second) < 0.00001
    end
    if type(first) ~= "table" then
        return first == second
    end
    for key, value in pairs(first) do
        if not lighthouse.equal(value, second[key]) then
            return false
        end
    end
    for key in pairs(second) do
        if first[key] == nil then
            return false
        end
    end
    return true
end

function lighthouse.get(profile, path)
    for key in path:gmatch("[^.]+") do
        if type(profile) ~= "table" then
            return nil
        end
        profile = profile[key]
    end
    return profile
end

function lighthouse.put(profile, path, value)
    local parent, key = path:match("^(.*)%.([^.]+)$")
    if not parent then
        profile[path] = value
        return
    end
    local current = profile
    for part in parent:gmatch("[^.]+") do
        current[part] = current[part] or {}
        current = current[part]
    end
    current[key] = value
end

function lighthouse.merge(base, patch)
    local result = lighthouse.copy(base or {})
    for key, value in pairs(patch or {}) do
        if type(value) == "table" and next(value) and type(result[key]) == "table"
                and key ~= "light_curve" and key ~= "textures" then
            result[key] = lighthouse.merge(result[key], value)
        else
            result[key] = lighthouse.copy(value)
        end
    end
    return result
end

lighthouse.schema = {}
lighthouse.defaults = {}
local allowed_paths = {}
for index, field in ipairs(lighthouse.fields) do
    field.path, field.label, field.kind = field[1], field[2], field[3]
    field.default, field.minimum, field.maximum = field[4], field[5], field[6]
    field.group, field.options, field.index = field[7], field[8], index
    lighthouse.schema[field.path] = field
    lighthouse.put(lighthouse.defaults, field.path, lighthouse.copy(field.default))
    local path = field.path
    while path do
        allowed_paths[path] = true
        path = path:match("^(.*)%.[^.]+$")
    end
end

function lighthouse.valid_name(name)
    return type(name) == "string" and #name > 0 and #name <= 48
        and name:match("^[%w _%-]+$") ~= nil
end

function lighthouse.curve(kind, amount)
    amount = tonumber(amount) or 2.2
    if amount ~= amount or amount < 0.1 or amount > 8 then
        return nil, "Curve amount must be between 0.1 and 8"
    end
    if kind == "Engine Default" then
        return {}
    end
    local values = {}
    for level = 0, 15 do
        local value = level / 15
        local brightness = value
        if kind == "Gamma" then
            brightness = value ^ amount
        elseif kind == "Soft Contrast" then
            brightness = value + (0.5 - value) * value * (1 - value) * math.min(amount, 3)
        elseif kind == "High Contrast" then
            brightness = value ^ amount / (value ^ amount + (1 - value) ^ amount)
        elseif kind == "Bright Nights" then
            brightness = 0.04 + 0.96 * value ^ 0.9
        elseif kind == "Deep Darkness" then
            brightness = value ^ 1.35
        elseif kind ~= "Linear" and kind ~= "Custom" then
            return nil, "Unknown curve generator"
        end
        values[level + 1] = math.floor(brightness * 255 + 0.5)
    end
    values[16] = 255
    return values
end

local function check_array(value, maximum)
    if type(value) ~= "table" then
        return nil
    end
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > maximum then
            return nil
        end
        count = count + 1
    end
    for index = 1, count do
        if value[index] == nil then
            return nil
        end
    end
    return count
end

function lighthouse.validate_curve(value)
    local count = check_array(value, 16)
    if count ~= 0 and count ~= 16 then
        return nil, "A curve needs 16 numbers, or an empty table for engine defaults"
    end
    local previous = -1
    for index = 1, count do
        local brightness = value[index]
        if type(brightness) ~= "number" or brightness ~= brightness
                or brightness < previous or brightness < 0 or brightness > 255 then
            return nil, "Curve values must be nondecreasing numbers in 0-255"
        end
        previous = brightness
    end
    if count == 16 and value[16] ~= 255 then
        return nil, "The last curve value must be 255"
    end
    return lighthouse.copy(value)
end

local function check_value(field, value)
    if field.kind == "number" or field.kind == "integer" then
        if type(value) ~= "number" or value ~= value or value < field.minimum or value > field.maximum then
            return nil, "Expected a number in " .. field.minimum .. " to " .. field.maximum
        end
        if field.kind == "integer" and value % 1 ~= 0 then
            return nil, "Expected a whole number"
        end
    elseif field.kind == "boolean" then
        if type(value) ~= "boolean" then
            return nil, "Expected true or false"
        end
    elseif field.kind == "curve" then
        return lighthouse.validate_curve(value)
    elseif field.kind == "textures" then
        local count = check_array(value, 6)
        if count ~= 0 and count ~= 6 then
            return nil, "Supply six skybox textures"
        end
        for _, texture in ipairs(value) do
            if type(texture) ~= "string" or #texture == 0 or #texture > 256 or texture:find("[%c]") then
                return nil, "Invalid skybox texture"
            end
        end
    elseif field.kind == "enum" then
        local found = false
        for _, option in ipairs(field.options) do
            if value == option then
                found = true
            end
        end
        if not found then
            return nil, "Unknown option"
        end
    elseif field.kind == "color" then
        if type(value) ~= "string" or not (value:match("^#%x%x%x%x%x%x$")
                or value:match("^#%x%x%x%x%x%x%x%x$")) then
            return nil, "Use #RRGGBB or #RRGGBBAA"
        end
        if #value == 7 then
            value = value .. "ff"
        end
        value = value:lower()
    elseif type(value) ~= "string" or #value > 256 or value:find("[%c]") then
        return nil, "Text must be at most 256 characters"
    end
    return lighthouse.copy(value)
end

function lighthouse.validate(profile, mode)
    if mode ~= nil and mode ~= "full" and mode ~= "patch" then
        return nil, "Profile mode must be full or patch"
    end
    if type(profile) ~= "table" then
        return nil, "Profile must be a table"
    end
    local result = {}
    local count = 0
    local function check_table(values, parent, depth)
        if depth > 6 then
            return nil, "Profile nesting limit exceeded"
        end
        for key, value in pairs(values) do
            count = count + 1
            if count > 256 or type(key) ~= "string" then
                return nil, "Invalid or oversized profile"
            end
            local path = parent == "" and key or parent .. "." .. key
            local field = lighthouse.schema[path]
            if field then
                local checked, message = check_value(field, value)
                if checked == nil then
                    return nil, field.label .. ": " .. message
                end
                lighthouse.put(result, path, checked)
            elseif allowed_paths[path] and type(value) == "table" then
                local ok, message = check_table(value, path, depth + 1)
                if not ok then
                    return nil, message
                end
            else
                return nil, "Unknown profile field: " .. path
            end
        end
        return true
    end
    local ok, message = check_table(profile, "", 1)
    if not ok then
        return nil, message
    end
    if mode == "full" then
        result = lighthouse.merge(lighthouse.defaults, result)
        -- Normalize default colors in exactly the same way as supplied colors.
        for _, field in ipairs(lighthouse.fields) do
            if field.kind == "color" then
                lighthouse.put(result, field.path, check_value(field, lighthouse.get(result, field.path)))
            end
        end
    end
    local exposure = result.lighting and result.lighting.exposure
    if exposure and exposure.luminance_min and exposure.luminance_max
            and exposure.luminance_min > exposure.luminance_max then
        return nil, "Minimum luminance exceeds maximum luminance"
    end
    if result.sky and result.sky.type == "skybox" and mode == "full"
            and #result.sky.textures ~= 6 then
        return nil, "Supply six textures before applying a skybox"
    end
    return result
end

-- JSON null cannot represent the special empty-table reset in Luanti's serializer.
function lighthouse.encode(profile, mode)
    local checked, message = lighthouse.validate(profile, mode)
    if not checked then
        return nil, message
    end
    for _, field in ipairs(lighthouse.fields) do
        if field.kind == "curve" or field.kind == "textures" then
            local value = lighthouse.get(checked, field.path)
            if value and not next(value) then
                lighthouse.put(checked, field.path, "engine_default")
            end
        end
    end
    return core.write_json({version = 1, mode = mode or "patch", profile = checked}, true)
end

function lighthouse.decode(text)
    if type(text) ~= "string" or #text > 32768 then
        return nil, "Import limit is 32 KiB"
    end
    local value = core.parse_json(text, nil, true)
    if type(value) ~= "table" then
        return nil, "Invalid profile JSON"
    end
    local profile = value.profile
    if type(profile) ~= "table" then
        return nil, "Missing profile"
    end
    for _, field in ipairs(lighthouse.fields) do
        if (field.kind == "curve" or field.kind == "textures")
                and lighthouse.get(profile, field.path) == "engine_default" then
            lighthouse.put(profile, field.path, {})
        end
    end
    local mode = value.mode
    if mode ~= "patch" and mode ~= "full" then
        return nil, "Profile mode must be full or patch"
    end
    local checked, message = lighthouse.validate(profile, mode)
    return checked, message, mode
end

-- register_preset is also available to game adapters and other trusted server mods.
function lighthouse.register_preset(name, definition, mode)
    if not lighthouse.valid_name(name) or lighthouse.profiles[name] or lighthouse.data.presets[name] then
        return nil, "Invalid or existing profile name"
    end
    local profile, message = lighthouse.validate(definition, mode or "full")
    if not profile then
        return nil, message
    end
    lighthouse.profiles[name] = {profile = profile, mode = mode or "full"}
    return true
end