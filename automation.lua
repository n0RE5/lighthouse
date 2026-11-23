function lighthouse.update_environment(player, context, immediate)
    local state = lighthouse.get_player_state(player)
    local source = lighthouse.get_automation_source()
    if state.automation_source ~= source then
        state.automation_source = source
        state.candidate, state.environment, state.scene = nil, nil, nil
        state.environment_transition, state.weather_name = nil, nil
        immediate = true
    end
    local selection, diagnostic, pending
    if lighthouse.data.automatic then
        local ok, result, message, waiting = pcall(lighthouse.resolve_environment, player, context)
        if ok then
            selection, diagnostic, pending = result, message, waiting == true
        else
            diagnostic = "Automation source " .. source .. " failed: " .. tostring(result)
            pending = true
            core.log("warning", "[Lighthouse] " .. diagnostic)
        end
    end
    state.automation_message = diagnostic
    if selection and selection.scene and not lighthouse.scenes[selection.scene] then
        state.automation_message = "Unknown scene: " .. tostring(selection.scene)
        selection = nil
    end
    if pending and lighthouse.data.automatic then
        state.candidate, state.candidate_since = nil, lighthouse.current_time
        local ok, message = lighthouse.refresh_player(player)
        lighthouse.update_hud(player)
        return ok, message
    end
    local candidate = selection and selection.name or false
    if state.candidate ~= candidate then
        state.candidate, state.candidate_since = candidate, lighthouse.current_time
    end
    local stable = lighthouse.current_time - state.candidate_since >= lighthouse.config.check_interval
    local held = lighthouse.current_time - state.changed_at >= lighthouse.config.hold_time
    if immediate or not lighthouse.data.automatic or not selection or not state.environment or (stable and held) then
        if state.environment ~= (selection and selection.name) or state.scene ~= (selection and selection.scene) then
            state.changed_at = lighthouse.current_time
        end
        state.environment = selection and selection.name
        state.scene = selection and selection.scene
        state.environment_transition = selection and selection.transition
    end
    state.weather_name = selection and selection.context and selection.context.weather
    local ok, message = lighthouse.refresh_player(player, immediate and 0 or (state.environment_transition or 5))
    lighthouse.update_hud(player)
    return ok, message
end

function lighthouse.set_automatic(enabled)
    if type(enabled) ~= "boolean" then
        return nil, "Invalid automatic setting"
    end
    lighthouse.data.automatic = enabled
    lighthouse.persist()
    for _, player in ipairs(core.get_connected_players()) do
        lighthouse.update_environment(player, nil, true)
    end
    return true
end