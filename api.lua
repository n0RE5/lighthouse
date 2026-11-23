core.register_privilege("lighthouse", {
    description = "Manage Lighthouse scenes, profiles, automation and editor",
    give_to_singleplayer = true,
    give_to_admin = true,
})

function lighthouse.allowed(player_name)
    return core.check_player_privs(player_name, {lighthouse = true})
end

function lighthouse.require(player_name)
    if lighthouse.allowed(player_name) then
        return true
    end
    return nil, "Required: lighthouse"
end

function lighthouse.throttle(player_name, channel)
    local player = core.get_player_by_name(player_name)
    if not player then
        return false
    end
    local state = lighthouse.get_player_state(player)
    state.requests = state.requests or {}
    local now = core.get_us_time()
    local last = state.requests[channel or "command"] or -math.huge
    if now - last < 150000 then
        return false
    end
    state.requests[channel or "command"] = now
    return true
end

-- Read-only copies
function lighthouse.get_active_preset()
    return lighthouse.data.global and lighthouse.data.global.name or nil
end

function lighthouse.get_current_settings()
    return lighthouse.data.global and lighthouse.copy(lighthouse.data.global.profile) or nil
end

function lighthouse.get_active_profile(player)
    return lighthouse.resolve_settings(player)
end

-- Server mods are trusted. Pass actor when the call originates from player input.
function lighthouse.apply_preset(name, options)
    options = options or {}
    if options.actor then
        local ok, message = lighthouse.require(options.actor)
        if not ok then
            return nil, message
        end
    end
    local profile, message = lighthouse.get_preset(name)
    if not profile then
        return nil, message
    end
    return lighthouse.set_global(profile, name, options.replace ~= false, options.manual == true)
end

function lighthouse.apply_to_player(player, name)
    local profile, message = lighthouse.get_preset(name)
    if not profile then
        return nil, message
    end
    local checked, failure = lighthouse.validate(profile, "full")
    if not checked then
        return nil, failure
    end
    local state = lighthouse.get_player_state(player)
    state.forced = checked
    return lighthouse.refresh_player(player, 0, true)
end

function lighthouse.force_scene(player, name)
    local profile, message = lighthouse.get_scene_profile(name)
    if not profile then
        return nil, message
    end
    local state = lighthouse.get_player_state(player)
    state.forced = profile
    return lighthouse.refresh_player(player, 0, true)
end

function lighthouse.clear_forced_scene(player)
    local state = lighthouse.get_player_state(player)
    state.forced, state.override = nil, nil
    return lighthouse.refresh_player(player)
end

function lighthouse.trigger_scene(name, player, context)
    local scene = lighthouse.scenes[name]
    if not scene then
        return nil, "Unknown scene"
    end
    if context then
        local check_def = lighthouse.copy(context)
        check_def.player = player
        check_def.pos = check_def.pos or (player and player:get_pos()) or vector.zero()
        check_def.timeofday = check_def.timeofday or core.get_timeofday()
        if not lighthouse.matches_environment(scene, check_def) then
            return false, "Scene condition not met"
        end
    end
    if player then
        return lighthouse.force_scene(player, name)
    end
    return lighthouse.set_global(lighthouse.get_scene_profile(name), name, true)
end

function lighthouse.dispatch_scene_event(player, context)
    if not player then
        return nil, "A player is required for environment events"
    end
    return lighthouse.update_environment(player, context, true)
end

local help = "/lh [scene <name>|preview [name]|next|prev|compare|revert|apply [name]|save <name>|advanced|auto on/off|source [name]|weather <state>|status|reset|release|presets]"
local commands = {}
commands.source = function(_, argument)
    if argument == "" then
        return true, "Source: " .. lighthouse.get_automation_source() .. ". Available sources: "
            .. table.concat(lighthouse.list_automation_sources(), ", ")
    end
    return lighthouse.set_automation_source(argument)
end
commands.preview = function(player, argument)
    if argument ~= "" then
        return lighthouse.load_scene(player, argument, true)
    end
    local session = lighthouse.session(player)
    return lighthouse.preview(player, session.work, session.name)
end
commands.scene = commands.preview
commands.next = function(player)
    return lighthouse.next_scene(player, 1)
end
commands.prev = function(player)
    return lighthouse.next_scene(player, -1)
end
commands.compare = function(player)
    return lighthouse.compare_preview(player)
end
commands.revert = function(player)
    lighthouse.session(player).pending_preview = nil
    return lighthouse.cancel_preview(player)
end
commands.apply = function(player, argument)
    local session = lighthouse.session(player)
    session.pending_preview = nil
    local profile, message
    local name = argument ~= "" and argument or session.name
    if argument ~= "" then
        profile, message = lighthouse.get_scene_profile(name)
        if not profile then
            profile, message = lighthouse.get_preset(name)
        end
    else
        profile = session.work
    end
    if not profile then
        return nil, message
    end
    local ok, failure = lighthouse.set_global(profile, name, true, true)
    if ok then
        lighthouse.cancel_preview(player)
    end
    return ok, failure
end
commands.save = function(player, argument)
    local session = lighthouse.session(player)
    local ok, message = lighthouse.save_preset(argument, session.work, player:get_player_name(), false, "full")
    if not ok then
        return nil, message
    end
    local definition = {profile = argument, description = "Saved custom scene", category = "Custom"}
    lighthouse.register_scene(argument, definition)
    lighthouse.data.scenes[argument] = definition
    lighthouse.persist()
    session.name, session.dirty = argument, false
    return true, "Scene saved"
end
commands.auto = function(_, argument)
    if argument ~= "on" and argument ~= "off" then
        return nil, "Use /lh auto on or /lh auto off"
    end
    return lighthouse.set_automatic(argument == "on")
end
commands.weather = function(_, argument)
    if argument == "auto" then
        return lighthouse.clear_weather()
    end
    return lighthouse.set_weather(argument)
end
commands.reset = function()
    return lighthouse.set_global(lighthouse.defaults, "Default", true)
end
commands.release = function()
    return lighthouse.reset_global()
end
commands.tool = function(player)
    player:get_inventory():add_item("main", "lighthouse:editor")
    return true, "Editor tool added: left click next, right click editor, sneak + left compare"
end

local function command(player_name, parameter)
    local allowed, message = lighthouse.require(player_name)
    if not allowed then
        return false, message
    end
    local subcommand, argument = parameter:match("^%s*(%S*)%s*(.-)%s*$")
    if subcommand == "help" then
        return true, help
    elseif subcommand == "presets" then
        return true, table.concat(lighthouse.list_presets(), ", ")
    end
    local player = core.get_player_by_name(player_name)
    if not player then
        return false, "Join the server first"
    end
    if subcommand == "" then
        return lighthouse.show(player)
    elseif subcommand == "advanced" then
        lighthouse.show_advanced(player)
        return true
    elseif subcommand == "status" then
        local state = lighthouse.get_player_state(player)
        return true, "Base: " .. (lighthouse.get_active_preset() or "game") .. ". Scene: "
            .. (state.scene or "manual")
            .. ". Source: " .. lighthouse.get_automation_source()
            .. ". Preview: " .. (state.preview and state.preview.name or "off")
            .. (state.automation_message and ". " .. state.automation_message or "")
    end
    local handler = commands[subcommand]
    if not handler then
        return false, help
    end
    allowed, message = lighthouse.require(player_name)
    if not allowed then
        return false, message
    end
    if not lighthouse.throttle(player_name, "command") then
        return false, "Please wait a moment"
    end
    local ok, result, detail = pcall(handler, player, argument)
    if not ok then
        core.log("warning", "[Lighthouse] Command: " .. tostring(result))
        return false, "Operation failed. Check the server log."
    end
    return result == true, lighthouse.ui.status_message(result == true, detail)
end

for _, name in ipairs({"lighthouse", "lh"}) do
    core.register_chatcommand(name, {params = "[action] [name]", description = "Lighthouse scenes and quick editor", func = command})
end

core.register_tool("lighthouse:editor", {
    description = "Lighthouse Scene Editor",
    inventory_image = "lighthouse_wand.png",
    groups = {not_in_creative_inventory = 1},
    on_use = function(itemstack, player)
        if player and lighthouse.allowed(player:get_player_name())
                and lighthouse.throttle(player:get_player_name(), "tool") then
            if player:get_player_control().sneak then
                lighthouse.compare_preview(player)
            else
                lighthouse.next_scene(player, 1)
            end
        end
        return itemstack
    end,
    on_secondary_use = function(itemstack, player)
        if player and lighthouse.allowed(player:get_player_name()) then
            lighthouse.show(player)
        end
        return itemstack
    end,
    on_place = function(itemstack, player)
        if player and lighthouse.allowed(player:get_player_name()) then
            lighthouse.show(player)
        end
        return itemstack
    end,
})