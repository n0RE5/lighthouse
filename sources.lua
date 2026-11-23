local sources = {}

-- A source selects a scene.
function lighthouse.register_automation_source(name, definition)
    if not lighthouse.valid_name(name) or type(definition) ~= "table"
            or type(definition.resolve) ~= "function"
            or (definition.available ~= nil and type(definition.available) ~= "function") then
        return nil, "Invalid automation source"
    end
    if sources[name] then
        return nil, "Automation source already registered: " .. name
    end
    sources[name] = {resolve = definition.resolve, available = definition.available}
    return true
end

function lighthouse.list_automation_sources()
    local names = {}
    for name in pairs(sources) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function lighthouse.get_automation_source()
    return lighthouse.data.automation_source or "lighthouse"
end

local function get_source(name)
    local source = sources[name]
    if not source then
        return nil, "Unknown automation source: " .. tostring(name)
    end
    if source.available then
        local ok, ready, message = pcall(source.available)
        if not ok then
            return nil, "Automation source availability failed: " .. name .. ": " .. tostring(ready)
        end
        if not ready then
            return nil, message or ("Automation source unavailable: " .. name)
        end
    end
    return source
end

function lighthouse.set_automation_source(name)
    local source, message = get_source(name)
    if not source then return nil, message end
    lighthouse.data.automation_source = name
    lighthouse.persist()
    for _, player in ipairs(core.get_connected_players()) do
        lighthouse.update_environment(player, nil, true)
    end
    return true
end

function lighthouse.resolve_environment(player, context)
    local name = lighthouse.get_automation_source()
    local source, message = get_source(name)
    if not source then return nil, message, true end
    local selection, diagnostic, pending = source.resolve(player, context)
    if selection ~= nil then
        if type(selection) ~= "table" or not lighthouse.valid_name(selection.name)
                or type(selection.scene) ~= "string" or not lighthouse.scenes[selection.scene]
                or (selection.transition ~= nil and (type(selection.transition) ~= "number"
                    or selection.transition ~= selection.transition
                    or selection.transition < 0 or selection.transition > 60))
                or (selection.context ~= nil and type(selection.context) ~= "table") then
            error("Invalid selection from automation source: " .. name)
        end
    end
    return selection, diagnostic, pending
end