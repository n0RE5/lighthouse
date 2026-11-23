lighthouse = {}

local modpath = core.get_modpath("lighthouse")
dofile(modpath .. "/settings.lua")
dofile(modpath .. "/profiles.lua")
dofile(modpath .. "/storage.lua")
dofile(modpath .. "/internal.lua")
dofile(modpath .. "/environments.lua")
dofile(modpath .. "/weather.lua")
dofile(modpath .. "/sources.lua")
dofile(modpath .. "/automation.lua")
dofile(modpath .. "/editor.lua")
dofile(modpath .. "/interface.lua")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/adapters/mtg_weather.lua")

dofile(modpath .. "/content.lua")
dofile(modpath .. "/sources/lighthouse.lua")
lighthouse.restore_definitions()

local check_timer = 0
local transition_timer = 0
core.register_globalstep(function(dtime)
    lighthouse.current_time = lighthouse.current_time + dtime
    check_timer = check_timer + dtime
    transition_timer = transition_timer + dtime

    if check_timer >= lighthouse.config.check_interval then
        check_timer = 0
        for _, player in ipairs(core.get_connected_players()) do
            local ok, message = pcall(lighthouse.update_environment, player)
            if not ok then
                core.log("warning", "[Lighthouse] Environment update: " .. tostring(message))
            end
        end
    end

    if transition_timer >= lighthouse.config.transition_interval then
        transition_timer = 0
        lighthouse.update_transitions()
    end
end)

core.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    core.after(0, function()
        local connected_player = core.get_player_by_name(player_name)
        if connected_player then
            local ok, message = pcall(lighthouse.update_environment, connected_player, nil, true)
            if not ok then
                core.log("warning", "[Lighthouse] Join update: " .. tostring(message))
            end
        end
    end)
end)

core.register_on_leaveplayer(lighthouse.clear_player_state)

core.register_on_priv_revoke(function(player_name, _, privilege)
    if privilege == "lighthouse" then
        local player = core.get_player_by_name(player_name)
        if player then
            lighthouse.cancel_preview(player)
            lighthouse.remove_hud(player)
        end
        lighthouse.sessions[player_name] = nil
    end
end)

core.log("action", "[Lighthouse] Visual environments loaded")