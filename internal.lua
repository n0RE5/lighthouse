local getters = {
    lighting = "get_lighting",
    sky = "get_sky",
    sun = "get_sun",
    moon = "get_moon",
    stars = "get_stars",
    clouds = "get_clouds",
}

function lighthouse.clear_player_state(player)
    local player_name = player:get_player_name()
    lighthouse.players[player_name] = nil
    lighthouse.sessions[player_name] = nil
end

local function color_string(value)
    if type(value) == "table" then
        return ("#%02x%02x%02x%02x"):format(value.r or 0, value.g or 0, value.b or 0, value.a or 255)
    end
    return value
end

function lighthouse.snapshot(player)
    local raw = {}
    for category, method in pairs(getters) do
        raw[category] = player[method](player, category == "sky" and true or nil)
    end
    -- 5.18 get_clouds() returns speed.y while set_clouds() reads speed.z.
    local speed = raw.clouds and raw.clouds.speed
    if speed and speed.z == nil and speed.y ~= nil then
        speed.z = speed.y
    end
    local ratio = player:get_day_night_ratio()
    raw.day_night = {enabled = ratio ~= nil, ratio = ratio or 1}
    local known = lighthouse.players[player:get_player_name()]
    local profile = {}
    for _, field in ipairs(lighthouse.fields) do
        local value = lighthouse.get(raw, field.path)
        -- Luanti stores the regular-sky palette but hides it from get_sky()
        -- while a plain sky/skybox is active. Keep the last palette we sent.
        if value == nil and field.path:find("sky.sky_color.", 1, true) == 1
                and known and known.applied and raw.sky.type ~= "regular"
                and known.applied.sky.type == raw.sky.type then
            value = lighthouse.get(known.applied, field.path)
        end
        if value ~= nil then
            if field.kind == "color" then
                value = color_string(value)
            end
            lighthouse.put(profile, field.path, lighthouse.copy(value))
        end
    end
    return assert(lighthouse.validate(profile, "full"))
end

function lighthouse.get_player_state(player)
    local player_name = player:get_player_name()
    local state = lighthouse.players[player_name]
    if not state then
        state = {
            baseline = lighthouse.snapshot(player),
            scene = nil,
            changed_at = -math.huge,
        }
        lighthouse.players[player_name] = state
    end
    return state
end

function lighthouse.has_active_profile(player)
    local name = player:get_player_name()
    local state = lighthouse.players[name]
    return not not (lighthouse.data.global
        or (lighthouse.data.personal[name] and lighthouse.allowed(name))
        or (state and (state.preview or state.forced or state.override or state.transition
            or (lighthouse.data.automatic and state.scene))))
end

local function field_difference(current, target, category)
    local patch = {}
    for _, field in ipairs(lighthouse.fields) do
        if field.path:match("^([^.]+)") == category then
            local value = lighthouse.get(target, field.path)
            if value ~= nil and not lighthouse.equal(value, lighthouse.get(current, field.path)) then
                local relative_path = field.path:sub(#category + 2)
                lighthouse.put(patch, relative_path, lighthouse.copy(value))
            end
        end
    end
    return patch
end

local function write_category(player, category, target, patch)
    if category == "day_night" then
        player:override_day_night_ratio(target.enabled and target.ratio or nil)
        return
    end
    -- Native RGB/vector substructures must be complete. Preserve fields outside our schema.
    local current = player[getters[category]](player, category == "sky" and true or nil)
    local complete = lighthouse.merge(current, target)
    if category == "clouds" and complete.speed then
        complete.speed.y = nil
    end
    if category == "sky" then
        complete.textures = lighthouse.copy(target.textures)
    end
    if category == "lighting" then
        complete.static = patch.static
    end
    player["set_" .. category](player, complete)
end

function lighthouse.apply_settings(player, profile)
    local target, message = lighthouse.validate(profile, "full")
    if not target then
        return nil, message
    end
    local state = lighthouse.get_player_state(player)
    local before = lighthouse.snapshot(player)
    if lighthouse.equal(before, target) then
        state.applied = lighthouse.copy(target)
        state.last_actual = before
        return true, "Unchanged", 0
    end
    local written = {}
    local calls = 0
    local ok, failure = pcall(function()
        for _, category in ipairs(lighthouse.categories) do
            local patch = field_difference(before, target, category)
            if next(patch) then
                -- Include the failing category in rollback if a native call changes it partially.
                written[#written + 1] = category
                write_category(player, category, target[category], patch)
                calls = calls + 1
            end
        end
    end)
    if not ok then
        for _, category in ipairs(written) do
            pcall(write_category, player, category, before[category], before[category])
        end
        state.applied = nil
        core.log("warning", "[Lighthouse] Player update failed: " .. tostring(failure))
        return nil, "Visual update failed, previous values restored where possible"
    end
    state.applied = lighthouse.copy(target)
    state.last_actual = lighthouse.snapshot(player)
    return true, "Applied", calls
end

function lighthouse.resolve_settings(player, without_preview)
    local state = lighthouse.get_player_state(player)
    local profile = lighthouse.copy(state.baseline)
    if lighthouse.data.global then
        profile = lighthouse.merge(profile, lighthouse.data.global.profile)
    end
    if lighthouse.data.automatic and state.scene then
        local scene_profile = lighthouse.get_scene_profile(state.scene)
        if scene_profile then
            profile = lighthouse.merge(profile, scene_profile)
        end
    end
    local personal = lighthouse.data.personal[player:get_player_name()]
    if personal and lighthouse.allowed(player:get_player_name()) then
        profile = lighthouse.merge(profile, personal.profile)
    end
    if state.forced then
        profile = lighthouse.merge(profile, state.forced)
    end
    if state.override then
        profile = lighthouse.merge(profile, state.override)
    end
    if state.preview and not without_preview and not state.preview.compare then
        profile = lighthouse.merge(profile, state.preview.profile)
    end
    if state.preview and not without_preview and state.preview.compare then
        return lighthouse.validate(lighthouse.defaults, "full")
    end
    return lighthouse.validate(profile, "full")
end

local function interpolate_color(first, second, weight)
    local result = "#"
    for offset = 2, 8, 2 do
        local start = tonumber(first:sub(offset, offset + 1), 16)
        local finish = tonumber(second:sub(offset, offset + 1), 16)
        result = result .. ("%02x"):format(math.floor(start + (finish - start) * weight + 0.5))
    end
    return result
end

function lighthouse.interpolate(first, second, weight)
    local result = lighthouse.copy(second)
    for _, field in ipairs(lighthouse.fields) do
        local start = lighthouse.get(first, field.path)
        local finish = lighthouse.get(second, field.path)
        local cheap = not field.path:find("lighting.static", 1, true)
        -- Negative fog values delegate to the client.
        if (field.path == "sky.fog.fog_start" or field.path == "sky.fog.fog_distance")
                and (start < 0 or finish < 0) then
            cheap = false
        end
        -- Fog alpha selects automatic/custom color in Luanti
        -- Mixing the automatic #00000000 sentinel would briefly enable black fog.
        if field.path == "sky.fog.fog_color"
                and (start:sub(8, 9) == "00" or finish:sub(8, 9) == "00") then
            cheap = false
        end
        if cheap and (field.kind == "number" or field.kind == "integer")
                and type(start) == "number" and type(finish) == "number" then
            local value = start + (finish - start) * weight
            -- Blend integer settings too, then round for the engine API.
            -- This avoids instant jumps in shadow RGB, fog distance and star count.
            if field.kind == "integer" then
                value = math.floor(value + 0.5)
            end
            lighthouse.put(result, field.path, value)
        elseif cheap and field.kind == "color" and type(start) == "string" and type(finish) == "string" then
            lighthouse.put(result, field.path, interpolate_color(start, finish, weight))
        end
    end
    return result
end

function lighthouse.refresh_player(player, duration, force)
    local state = lighthouse.get_player_state(player)
    local target, message = lighthouse.resolve_settings(player)
    if not target then
        return nil, message
    end
    if not force and state.transition and lighthouse.equal(state.transition.target, target) then
        return true
    end
    if state.applied and lighthouse.equal(state.applied, target) then
        state.transition = nil
        if force then
            return lighthouse.apply_settings(player, target)
        end
        return true
    end
    duration = duration or 0
    if duration > 0 and state.applied and not state.preview then
        state.transition = {
            from = lighthouse.copy(state.applied),
            target = target,
            started = lighthouse.current_time,
            duration = duration,
        }
        -- Discrete values, including the LUT/AO, switch once at the start.
        return lighthouse.apply_settings(player, lighthouse.interpolate(state.applied, target, 0))
    end
    state.transition = nil
    return lighthouse.apply_settings(player, target)
end

function lighthouse.update_transitions()
    for player_name, state in pairs(lighthouse.players) do
        if state.transition then
            local player = core.get_player_by_name(player_name)
            if not player then
                state.transition = nil
            else
                local transition = state.transition
                local weight = math.max(0, math.min(1,
                    (lighthouse.current_time - transition.started) / transition.duration))
                -- Smoothstep eases into and out of automatic transitions.
                weight = weight * weight * (3 - 2 * weight)
                local ok = lighthouse.apply_settings(player, lighthouse.interpolate(transition.from, transition.target, weight))
                if not ok or weight >= 1 then
                    state.transition = nil
                end
            end
        end
    end
end

function lighthouse.refresh_all()
    local errors = {}
    for _, player in ipairs(core.get_connected_players()) do
        local ok, message = lighthouse.refresh_player(player, 0, true)
        if not ok then
            errors[#errors + 1] = player:get_player_name() .. ": " .. message
        end
        lighthouse.update_hud(player)
    end
    return true, #errors > 0 and table.concat(errors, ". ") or "Applied to server"
end

function lighthouse.preview(player, profile, label, mode)
    local checked, message = lighthouse.validate(profile, mode or "full")
    if not checked then
        return nil, message
    end
    local state = lighthouse.get_player_state(player)
    local previous = state.preview
    state.preview = {profile = checked, name = label or "Custom", compare = false}
    local ok, failure = lighthouse.refresh_player(player, 0, true)
    if not ok then
        state.preview = previous
        return nil, failure
    end
    lighthouse.update_hud(player)
    return true, "Preview remains active after closing the editor"
end

function lighthouse.cancel_preview(player)
    local session = lighthouse.sessions[player:get_player_name()]
    if session then
        session.pending_preview = nil
    end
    local state = lighthouse.get_player_state(player)
    if state.preview and state.last_actual then
        local current = lighthouse.snapshot(player)
        for _, field in ipairs(lighthouse.fields) do
            local value = lighthouse.get(current, field.path)
            if not lighthouse.equal(value, lighthouse.get(state.last_actual, field.path)) then
                lighthouse.put(state.baseline, field.path, lighthouse.copy(value))
            end
        end
    end
    state.preview = nil
    state.transition = nil
    local ok, message = lighthouse.refresh_player(player)
    lighthouse.update_hud(player)
    return ok, message
end

function lighthouse.compare_preview(player)
    local state = lighthouse.get_player_state(player)
    if not state.preview then
        return nil, "Start Preview first"
    end
    state.preview.compare = not state.preview.compare
    local ok, message = lighthouse.refresh_player(player)
    lighthouse.update_hud(player)
    return ok, message
end

function lighthouse.set_global(profile, name, replace, manual)
    local mode = replace == false and "patch" or "full"
    local checked, message = lighthouse.validate(profile, mode)
    if not checked then
        return nil, message
    end
    if mode == "patch" then
        local base = lighthouse.data.global and lighthouse.data.global.profile or lighthouse.defaults
        checked, message = lighthouse.validate(lighthouse.merge(base, checked), "full")
        if not checked then
            return nil, message
        end
    end
    local previous_global, previous_automatic = lighthouse.data.global, lighthouse.data.automatic
    lighthouse.data.global = {profile = checked, mode = "full", name = name or "Custom"}
    if manual then
        lighthouse.data.automatic = false
    end
    local ok, failure = lighthouse.persist()
    if not ok then
        lighthouse.data.global, lighthouse.data.automatic = previous_global, previous_automatic
        return nil, failure
    end
    if manual then
        for _, player in ipairs(core.get_connected_players()) do
            local state = lighthouse.get_player_state(player)
            state.scene, state.environment = nil, nil
            state.transition, state.candidate, state.automation_message = nil, nil, nil
        end
    end
    return lighthouse.refresh_all()
end

function lighthouse.reset_global()
    lighthouse.data.global = false
    lighthouse.persist()
    return lighthouse.refresh_all()
end

function lighthouse.apply_profile(player, profile, track)
    local checked, message = lighthouse.validate(profile, "patch")
    if not checked then
        return nil, message
    end
    if track == false then
        return lighthouse.preview(player, checked, "Temporary patch", "patch")
    end
    local state = lighthouse.get_player_state(player)
    local old_override = state.override
    state.override = lighthouse.merge(state.override, checked)
    local ok, failure = lighthouse.refresh_player(player)
    if not ok then
        state.override = old_override
    end
    return ok, failure
end

function lighthouse.reset_player(player)
    local session = lighthouse.sessions[player:get_player_name()]
    if session then
        session.pending_preview = nil
    end
    local state = lighthouse.get_player_state(player)
    state.preview, state.forced, state.override = nil, nil, nil
    state.transition = nil
    local ok, message = lighthouse.refresh_player(player)
    lighthouse.update_hud(player)
    return ok, message
end

function lighthouse.reset_category(player, category)
    if not getters[category] and category ~= "day_night" then
        return nil, "Unknown category"
    end
    return lighthouse.apply_profile(player, {[category] = lighthouse.defaults[category]}, true)
end

function lighthouse.reset_engine(player)
    local ok, message = pcall(function()
        for _, category in ipairs(lighthouse.categories) do
            if category == "day_night" then
                player:override_day_night_ratio(nil)
            else
                player["set_" .. category](player, nil)
            end
        end
    end)
    if not ok then
        return nil, tostring(message)
    end
    local state = lighthouse.get_player_state(player)
    state.override = lighthouse.snapshot(player)
    state.applied, state.transition = nil, nil
    state.preview, state.forced = nil, nil
    return lighthouse.refresh_player(player)
end

function lighthouse.save_personal(player, profile)
    local checked, message = lighthouse.validate(profile, "full")
    if not checked then
        return nil, message
    end
    local player_name = player:get_player_name()
    lighthouse.data.personal[player_name] = {profile = checked, mode = "full", owner = player_name}
    lighthouse.get_player_state(player).preview = nil
    lighthouse.persist()
    return lighthouse.refresh_player(player)
end