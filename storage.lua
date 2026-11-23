local storage = core.get_mod_storage()
lighthouse.storage = storage

local function empty_state()
    return {
        version = 1,
        presets = {},
        personal = {},
        scenes = {},
        environments = {},
        global = false,
        automatic = lighthouse.config.automatic,
        automation_source = "lighthouse",
    }
end

local function read_entry(entry)
    if type(entry) ~= "table" or type(entry.profile) ~= "string" then
        return nil, "Stored profiles must use the current encoded format"
    end
    local profile, message, mode = lighthouse.decode(entry.profile)
    if not profile then return nil, message end
    return {
        profile = profile,
        mode = mode,
        name = type(entry.name) == "string" and entry.name:sub(1,48) or nil,
        owner = type(entry.owner) == "string" and entry.owner:sub(1,64) or "",
        updated = tonumber(entry.updated) or 0,
    }
end

function lighthouse.read_storage(text)
    local saved = core.parse_json(text, nil, true)
    if type(saved) ~= "table" then
        return nil, "Invalid Lighthouse storage"
    end
    if type(saved.automatic) ~= "boolean" then
        return nil, "Invalid stored automation settings"
    end
    local result = empty_state()
    result.automatic = saved.automatic
    if saved.automation_source ~= nil then
        if not lighthouse.valid_name(saved.automation_source) then
            return nil, "Invalid stored automation source"
        end
        result.automation_source = saved.automation_source
    end
    -- Luanti encodes empty dictionaries as JSON null in the current format.
    for _, key in ipairs({"presets", "personal"}) do
        if saved[key] ~= nil and type(saved[key]) ~= "table" then return nil, "Invalid stored " .. key end
        for name, entry in pairs(saved[key] or {}) do
            local checked, message = read_entry(entry)
            if type(name) ~= "string" or #name > 64 or not checked then
                return nil, "Invalid stored " .. key .. ": " .. tostring(message or name)
            end
            result[key][name] = checked
        end
    end
    if saved.global ~= false then
        local checked, message = read_entry(saved.global)
        if not checked then return nil, "Invalid stored global: " .. tostring(message) end
        result.global = checked
    end
    for _, key in ipairs({"scenes", "environments"}) do
        if saved[key] ~= nil and type(saved[key]) ~= "table" then return nil, "Invalid stored " .. key end
        if saved[key] then result[key] = saved[key] end
    end
    return result
end

local function pack_entry(entry)
    return {
        profile = assert(lighthouse.encode(entry.profile, entry.mode)),
        name = entry.name,
        owner = entry.owner,
        updated = entry.updated,
    }
end

function lighthouse.persist()
    local saved = lighthouse.copy(lighthouse.data)
    for _, key in ipairs({"presets", "personal"}) do
        for name, entry in pairs(saved[key]) do
            saved[key][name] = pack_entry(entry)
        end
    end
    if saved.global then
        saved.global = pack_entry(saved.global)
    end
    storage:set_string("state", core.write_json(saved))
    return true
end

lighthouse.data = empty_state()
local original = storage:get_string("state")
if original ~= "" then
    local saved, message = lighthouse.read_storage(original)
    if not saved then error("[Lighthouse] " .. message .. ", stored data was not changed") end
    lighthouse.data = saved
end

function lighthouse.list_presets()
    local names = {}
    for name in pairs(lighthouse.profiles) do
        names[#names + 1] = name
    end
    for name in pairs(lighthouse.data.presets) do
        if not lighthouse.profiles[name] then
            names[#names + 1] = name
        end
    end
    table.sort(names)
    return names
end

function lighthouse.get_preset(name)
    local entry = lighthouse.profiles[name] or lighthouse.data.presets[name]
    if not entry then
        return nil, "Unknown profile: " .. tostring(name)
    end
    return lighthouse.copy(entry.profile), nil, entry.mode
end

function lighthouse.save_preset(name, profile, owner, overwrite, mode)
    if not lighthouse.valid_name(name) then
        return nil, "Use 1-48 letters, numbers, spaces, _ or -"
    end
    if lighthouse.profiles[name] or (lighthouse.builtin_scenes and lighthouse.builtin_scenes[name]) then
        return nil, "Built-in profiles are read-only"
    end
    if lighthouse.data.presets[name] and not overwrite then
        return nil, "This name already exists"
    end
    local count = 0
    for _ in pairs(lighthouse.data.presets) do
        count = count + 1
    end
    if count >= 200 and not lighthouse.data.presets[name] then
        return nil, "Limit: 200 saved profiles"
    end
    mode = mode or "full"
    local checked, message = lighthouse.validate(profile, mode)
    if not checked then
        return nil, message
    end
    lighthouse.data.presets[name] = {
        profile = checked,
        mode = mode,
        owner = owner or "API",
        updated = os.time(),
    }
    return lighthouse.persist()
end

function lighthouse.delete_preset(name)
    if lighthouse.profiles[name] or not lighthouse.data.presets[name] then
        return nil, "Select a saved user profile"
    end
    for _, scene in pairs(lighthouse.scenes) do
        if scene.profile == name then
            return nil, "This profile is referenced by a scene, change the scene first"
        end
    end
    lighthouse.data.presets[name] = nil
    return lighthouse.persist()
end

function lighthouse.rename_preset(old_name, new_name)
    local entry = lighthouse.data.presets[old_name]
    if not entry or lighthouse.profiles[old_name] then
        return nil, "Select a saved user profile"
    end
    local ok, message = lighthouse.save_preset(new_name, entry.profile, entry.owner, false, entry.mode)
    if not ok then
        return nil, message
    end
    for name, scene in pairs(lighthouse.scenes) do
        if scene.profile == old_name then
            scene.profile = new_name
            if lighthouse.data.scenes[name] then
                lighthouse.data.scenes[name].profile = new_name
            end
        end
    end
    lighthouse.data.presets[old_name] = nil
    return lighthouse.persist()
end

-- Restore custom definitions after built-in profiles, scenes and rules exist.
function lighthouse.restore_definitions()
    for name, definition in pairs(lighthouse.data.scenes) do
        local ok, message = lighthouse.register_scene(name, definition)
        if not ok then
            error("[Lighthouse] Invalid saved scene " .. tostring(name) .. ": " .. tostring(message))
        end
    end
    for name, definition in pairs(lighthouse.data.environments) do
        local ok, message = lighthouse.register_environment(name, definition)
        if not ok then
            error("[Lighthouse] Invalid saved environment " .. tostring(name) .. ": " .. tostring(message))
        end
    end
end