local ui = lighthouse.ui
local navigation = {"SCENES", "ENVIRONMENTS", "EDITOR", "LIBRARY", "SETTINGS"}
local groups = {"Light", "Atmosphere", "Effects", "Advanced"}

function lighthouse.remove_hud(player)
    local state = lighthouse.players[player:get_player_name()]
    if state and state.hud then
        player:hud_remove(state.hud)
        state.hud, state.hud_text = nil, nil
    end
    if state and state.hud_panel then
        player:hud_remove(state.hud_panel)
        state.hud_panel, state.hud_panel_text = nil, nil
    end
end

function lighthouse.update_hud(player)
    local state = lighthouse.get_player_state(player)
    if state.hud_hidden or (not state.preview and not state.hud_requested) then
        lighthouse.remove_hud(player)
        return
    end
    local mode = state.preview and (state.preview.compare and "Before / Engine defaults" or "Preview") or "World"
    local name = state.preview and state.preview.name or (lighthouse.data.automatic and state.scene)
        or (lighthouse.data.global and lighthouse.data.global.name) or "Game baseline"
    local scene = state.scene or "Manual"
    local session = lighthouse.sessions[player:get_player_name()]
    local changed = session and session.dirty and " / edited" or ""
    local text = "LIGHTHOUSE  /  " .. mode .. changed .. "\n" .. name .. "\nScene: " .. scene
        .. "\n/lh compare  |  /lh revert  |  /lh"
    if state.preview and session and session.last_changed then
        text = text .. "\nChanged: " .. session.last_changed
    end
    if state.hud then
        if state.hud_text ~= text then
            player:hud_change(state.hud, "text", text)
        end
    else
        state.hud = player:hud_add({
            type = "text",
            name = "Lighthouse Preview",
            position = {x = 1, y = 0},
            alignment = {x = -1, y = 1},
            offset = {x = -24, y = 28},
            text = text,
            number = 0xe0edf5,
            size = {x = 0.9, y = 1},
            z_index = 100,
        })
    end
    state.hud_text = text
end

function lighthouse.load_scene(player, name, start_preview)
    local profile, message = lighthouse.get_scene_profile(name)
    if not profile then
        profile, message = lighthouse.get_preset(name)
        if profile then
            profile, message = lighthouse.validate(profile, "full")
        end
    end
    if not profile then
        return nil, message
    end
    local session = lighthouse.session(player)
    session.work = profile
    session.name, session.selected = name, name
    if session.category == "Biomes" and not lighthouse.biome_scene_names[name] then
        session.category = "All scenes"
    elseif session.category == "Biomes" then
        local family = lighthouse.biome_families[session.biome_id]
        local present = false
        for _, scene_name in pairs(family and family.phases or {}) do
            if scene_name == name then present = true end
        end
        if not present then session.biome_id = nil end
    end
    session.inputs, session.curve_inputs = {}, nil
    session.dirty, session.pending_preview = false, nil
    if start_preview then
        return lighthouse.preview(player, profile, name)
    end
    return true, "Loaded into editor"
end

function lighthouse.list_scenes()
    local names = {}
    for name in pairs(lighthouse.scenes) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

local categories = {"All scenes", "Essentials", "Time of day", "Weather", "Places", "Custom", "Biomes"}
local function scene_choices(category, session)
    local names = {}
    if category == "Biomes" and session then
        local families = lighthouse.biome_families
        if not families[session.biome_id] then
            for id, family in pairs(families) do
                for _, name in pairs(family.phases) do
                    if name == session.selected then session.biome_id = id end
                end
            end
        end
        local family = families[session.biome_id]
        if not family then return names end
        for _, key in ipairs({"dawn", "day", "late", "dusk", "night", "underground", "deep"}) do
            if family.phases[key] then names[#names + 1] = family.phases[key] end
        end
        return names
    end
    for _, name in ipairs(lighthouse.list_scenes()) do
        if category == "All scenes" or lighthouse.scenes[name].category == category
                or (category == "Biomes" and lighthouse.biome_scene_names[name]) then
            names[#names + 1] = name
        end
    end
    return names
end

function lighthouse.next_scene(player, direction)
    local session = lighthouse.session(player)
    local names = scene_choices(session.category, session)
    if #names == 0 then return nil, "No scenes in this category" end
    local selected = 1
    for index, name in ipairs(names) do
        if name == session.selected then
            selected = index
        end
    end
    selected = ((selected - 1 + direction) % #names) + 1
    return lighthouse.load_scene(player, names[selected], true)
end

local function scenes_panel(session)
    session.scene_names = scene_choices(session.category, session)
    local selected_present = false
    for _, name in ipairs(session.scene_names) do
        if name == session.selected then
            selected_present = true
        end
    end
    if not selected_present then
        session.selected = session.scene_names[1]
    end
    local scene = lighthouse.scenes[session.selected]
    local biome_picker = ""
    if session.category == "Biomes" then
        session.biome_ids, session.biome_titles = {}, {}
        for id in pairs(lighthouse.biome_families) do session.biome_ids[#session.biome_ids + 1] = id end
        table.sort(session.biome_ids)
        for _, id in ipairs(session.biome_ids) do
            session.biome_titles[#session.biome_titles + 1] = lighthouse.biome_families[id].title
        end
        table.insert(session.biome_ids, 1, false)
        table.insert(session.biome_titles, 1, "Choose a biome")
        biome_picker = ui.dropdown(0.4, 2.8, 6, "biome_family", session.biome_titles,
            session.biome_id and lighthouse.biome_families[session.biome_id].title or "Choose a biome")
    end
    return ui.dropdown(0.4, 2.1, 6, "category", categories, session.category)
        .. biome_picker
        .. ui.dropdown(0.4, session.category == "Biomes" and 3.5 or 3, 6, "scene", session.scene_names, session.selected)
        .. ui.text(0.4, session.category == "Biomes" and 4.25 or 4, 6, 1.3, scene and scene.description or "No scene selected")
        .. ui.button(0.4, 5.8, 1.8, "preview_scene", "Preview")
        .. ui.button(2.5, 5.8, 1.8, "apply_scene", "Apply")
        .. ui.button(4.6, 5.8, 1.8, "edit_scene", "Edit")
        .. ui.button(0.4, 6.7, 2.8, "previous_scene", "Previous")
        .. ui.button(3.6, 6.7, 2.8, "next_scene", "Next")
        .. ui.text(0.4, 7.8, 6, 1.7, "Preview affects only you. Apply changes the world and pauses automation. Preview stays active when you close this menu.")
end

local quick_fields = {
    Light = {"lighting.exposure.exposure_correction", "lighting.saturation", "lighting.shadows.intensity", "day_night.ratio"},
    Atmosphere = {"clouds.density", "sky.fog.fog_start", "clouds.height", "clouds.thickness"},
    Effects = {"lighting.bloom.intensity", "lighting.volumetric_light.strength", "lighting.bloom.strength_factor", "lighting.bloom.radius"},
}

local function editor_panel(session)
    local result = ui.dropdown(0.4, 2.1, 6, "group", groups, session.group)
    for index, path in ipairs(quick_fields[session.group] or {}) do
        local field = lighthouse.schema[path]
        result = result .. ui.profile_field(session, field, 0.4, 3.4 + (index - 1) * 1.3, 6, true)
    end
    if session.group == "Light" then
        result = result .. ui.profile_field(session, lighthouse.schema["day_night.enabled"], 0.4, 8.45, 6, false)
    end
    return result .. ui.button(0.4, 9.2, 2.8, "advanced", "Advanced")
        .. ui.button(3.6, 9.2, 2.8, "apply", "Apply global")
end

local function environments_panel(session, player)
    local state = lighthouse.get_player_state(player)
    local weather_name = lighthouse.get_weather(player)
    session.environment_names = {}
    for name in pairs(lighthouse.environments) do
        session.environment_names[#session.environment_names + 1] = name
    end
    table.sort(session.environment_names)
    -- Dropdowns submit their displayed value with unrelated controls too.
    if not lighthouse.environments[session.environment_name or ""] then
        session.environment_name = session.environment_names[1]
    end
    session.automation_sources = lighthouse.list_automation_sources()
    return ui.checkbox(0.4, 2.3, "automatic", "Automatic environments", lighthouse.data.automatic)
        .. ui.dropdown(0.4, 2.7, 6, "automation_source", session.automation_sources, lighthouse.get_automation_source())
        .. ui.text(0.4, 3.4, 6, 1.7, "Rule: " .. (state.environment or "manual") .. "\nScene: " .. (state.scene or "none") .. "\n" .. (state.automation_message or (weather_name and "Weather: " .. weather_name or "")))
        .. ui.dropdown(0.4, 5.2, 6, "environment", session.environment_names, session.environment_name)
        .. ui.button(0.4, 6.2, 2.8, "edit_environment", "Edit conditions")
        .. ui.button(3.6, 6.2, 2.8, "new_environment", "New rule")
        .. ui.text(0.4, 7.3, 6, 2.3, "Automation chooses scenes as players move. Rules apply to the Lighthouse source. Higher priority wins.")
end

local function library_panel(session)
    session.profile_names = lighthouse.list_presets()
    if not lighthouse.get_preset(session.library_selected or "") then
        session.library_selected = session.profile_names[1]
    end
    return ui.dropdown(0.4, 2.1, 6, "profile", session.profile_names, session.library_selected or session.name)
        .. ui.button(0.4, 3, 1.8, "load_profile", "Load")
        .. ui.button(2.5, 3, 1.8, "duplicate", "Duplicate")
        .. ui.button(4.6, 3, 1.8, "delete", "Delete")
        .. ui.field(0.4, 4.2, 6, "save_name", "Scene name", session.save_name)
        .. ui.button(0.4, 5.1, 1.8, "save", "Save new")
        .. ui.button(2.5, 5.1, 1.8, "overwrite", "Overwrite")
        .. ui.button(4.6, 5.1, 1.8, "rename", "Rename")
        .. ("textarea[0.4,6.2;6,2;json;Profile JSON;%s]"):format(ui.escape(session.json or ""))
        .. ui.button(0.4, 8.6, 2.8, "import", "Import to editor")
        .. ui.button(3.6, 8.6, 2.8, "export", "Export working")
        .. ui.text(0.4, 9.4, 6, 0.6, "Save a copy to edit a built in scene.")
end

local function settings_panel(session, player)
    local hidden = lighthouse.get_player_state(player).hud_hidden
    return ui.checkbox(0.4, 2.3, "automatic", "Automatic environments", lighthouse.data.automatic)
        .. ui.button(0.4, 3.2, 6, "personal", "Save current as personal profile")
        .. ui.button(0.4, 4.1, 6, "clear_personal", "Clear personal profile")
        .. ui.button(0.4, 5, 6, "release", "Restore world appearance")
        .. ui.button(0.4, 5.9, 6, "engine_reset", "Use engine defaults for me")
        .. ui.button(0.4, 6.8, 6, hidden and "hud_on" or "hud_off", hidden and "Show HUD" or "Hide HUD")
        .. ui.text(0.4, 7.8, 6, 2, "Personal settings affect only you. World settings affect all players. Requires Bloom and dynamic shadows to be enabled in the graphics settings.")
end

function lighthouse.show(player)
    if not lighthouse.allowed(player:get_player_name()) then
        return nil, "Lighthouse privilege required"
    end
    local session = lighthouse.session(player)
    session.advanced = false
    ui.begin_form(session)
    local state = lighthouse.get_player_state(player)
    state.hud_requested = true
    lighthouse.update_hud(player)
    local result = "formspec_version[6]size[6.8,11.55]position[0.99,0.5]anchor[1,0.5]padding[0.01,0.02]"
        .. "no_prepend[]bgcolor[#142034ed;false;#00000000]"
        .. ui.form_style()
        .. ui.label(0.4, 0.5, "LIGHTHOUSE")
        .. ui.label(3.4, 0.5, state.preview and "Preview" or "World")
        .. "button_exit[5.8,0.2;0.6,0.5;close;X]"
    result = result .. ui.dropdown(0.4, 1.1, 6, "section", navigation, session.tab)
    if session.tab == "SCENES" then
        result = result .. scenes_panel(session)
    elseif session.tab == "EDITOR" then
        result = result .. editor_panel(session)
    elseif session.tab == "ENVIRONMENTS" then
        result = result .. environments_panel(session, player)
    elseif session.tab == "LIBRARY" then
        result = result .. library_panel(session)
    else
        result = result .. settings_panel(session, player)
    end
    result = result .. ui.text(0.4, 10, 6, 0.5, (session.message or ""):sub(1, 140))
        .. ui.button(0.4, 10.55, 2.8, "compare", "Compare")
        .. ui.button(3.6, 10.55, 2.8, "revert", "End Preview")
    session.form = result
    core.show_formspec(player:get_player_name(), "lighthouse:quick", result)
    return true
end

local function preview_work(player, session, include_static)
    local profile = lighthouse.copy(session.work)
    if not include_static then
        local state = lighthouse.get_player_state(player)
        local previous = state.preview and state.preview.profile or state.applied or lighthouse.resolve_settings(player, true)
        profile.lighting.static = lighthouse.copy(previous.lighting.static)
    end
    return lighthouse.preview(player, profile, session.name)
end

local function apply_work(player, session)
    session.pending_preview = nil
    local ok, message = lighthouse.set_global(session.work, session.name, true, true)
    if ok then
        lighthouse.cancel_preview(player)
        session.dirty = false
        return true, "Applied to the world. Automation paused."
    end
    return ok, message
end

local handlers = {}
handlers.preview = function(player, session)
    return preview_work(player, session, false)
end
handlers.apply_static = function(player, session)
    return preview_work(player, session, true)
end
handlers.preview_scene = function(player, session)
    return lighthouse.load_scene(player, session.selected, true)
end
handlers.apply_scene = function(player, session)
    local profile, message = lighthouse.get_scene_profile(session.selected)
    if not profile then
        return nil, message
    end
    session.work, session.name, session.pending_preview = profile, session.selected, nil
    session.inputs, session.curve_inputs, session.dirty = {}, nil, false
    return apply_work(player, session)
end
handlers.apply = apply_work
handlers.compare = function(player)
    return lighthouse.compare_preview(player)
end
handlers.revert = function(player, session)
    session.pending_preview = nil
    local ok, message = lighthouse.cancel_preview(player)
    return ok, ok and "Preview ended" or message
end
handlers.next_scene = function(player)
    return lighthouse.next_scene(player, 1)
end
handlers.previous_scene = function(player)
    return lighthouse.next_scene(player, -1)
end
handlers.edit_scene = function(player, session)
    local ok, message = lighthouse.load_scene(player, session.selected, false)
    if ok then
        session.tab = "EDITOR"
    end
    return ok, message
end
handlers.load_profile = function(player, session)
    local profile, message = lighthouse.get_preset(session.library_selected or session.name)
    if not profile then
        return nil, message
    end
    session.work = assert(lighthouse.validate(profile, "full"))
    session.name = session.library_selected or session.name
    session.inputs, session.curve_inputs, session.pending_preview = {}, nil, nil
    session.dirty = false
    return true, "Profile loaded into editor"
end
handlers.preview_profile = function(player, session)
    local ok, message = handlers.load_profile(player, session)
    if not ok then
        return nil, message
    end
    return lighthouse.preview(player, session.work, session.name)
end
handlers.save = function(player, session)
    local ok, message = lighthouse.save_preset(session.save_name, session.work, player:get_player_name(), false, "full")
    if not ok then
        return nil, message
    end
    local definition = {profile = session.save_name, category = "Custom", description = "Saved custom scene", transition = 5}
    lighthouse.register_scene(session.save_name, definition)
    lighthouse.data.scenes[session.save_name] = definition
    lighthouse.persist()
    session.name, session.dirty = session.save_name, false
    return true, "Scene saved"
end
handlers.overwrite = function(player, session)
    return lighthouse.save_preset(session.library_selected or session.name, session.work, player:get_player_name(), true, "full")
end
handlers.duplicate = function(player, session)
    local profile, message = lighthouse.get_preset(session.library_selected or session.name)
    if not profile then
        return nil, message
    end
    return lighthouse.save_preset(session.save_name, profile, player:get_player_name(), false, "full")
end
handlers.rename = function(_, session)
    local name = session.library_selected or session.name
    local ok, message = lighthouse.rename_preset(name, session.save_name)
    if ok then
        session.library_selected = session.save_name
        if session.name == name then
            session.name = session.save_name
        end
    end
    return ok, message
end
handlers.delete = function(_, session)
    local name = session.library_selected or session.name
    if lighthouse.profiles[name] then
        return nil, "Save a copy to edit this scene."
    end
    -- A user-created scene with the same name is the UI's direct reference to this profile.
    local scene = lighthouse.data.scenes[name]
    for _, definition in pairs(lighthouse.environments) do
        if definition.scene == name then
            return nil, "A rule uses this scene. Change that rule first."
        end
    end
    if scene and scene.profile == name then
        lighthouse.data.scenes[name], lighthouse.scenes[name] = nil, nil
    end
    local ok, message = lighthouse.delete_preset(name)
    if not ok and scene then
        lighthouse.data.scenes[name], lighthouse.scenes[name] = scene, scene
    end
    return ok, message
end
handlers.export = function(_, session)
    session.json = lighthouse.encode(session.work, "full")
    return true, "Copy JSON from the library"
end
handlers.import = function(_, session)
    local profile, message, mode = lighthouse.decode(session.json or "")
    if not profile then
        return nil, message
    end
    session.work = mode == "patch" and lighthouse.merge(session.work, profile) or profile
    session.inputs, session.curve_inputs = {}, nil
    session.name, session.dirty = "Imported", true
    return true, "Imported. Save to keep this scene."
end
handlers.release = function()
    return lighthouse.reset_global()
end
handlers.personal = function(player, session)
    session.pending_preview = nil
    return lighthouse.save_personal(player, session.work)
end
handlers.clear_personal = function(player)
    lighthouse.data.personal[player:get_player_name()] = nil
    lighthouse.persist()
    return lighthouse.refresh_player(player)
end
handlers.engine_reset = function(player, session)
    session.pending_preview = nil
    return lighthouse.reset_engine(player)
end
handlers.hud_off = function(player)
    local state = lighthouse.get_player_state(player)
    state.hud_requested, state.hud_hidden = nil, true
    lighthouse.remove_hud(player)
    return true
end
handlers.hud_on = function(player)
    local state = lighthouse.get_player_state(player)
    state.hud_requested, state.hud_hidden = true, false
    lighthouse.update_hud(player)
    return true
end
handlers.generate = function(_, session)
    if session.curve_kind == "Custom" then
        return true, "Edit the sixteen levels directly"
    end
    local curve, message = lighthouse.curve(session.curve_kind, session.curve_amount)
    if not curve then
        return nil, message
    end
    lighthouse.put(session.work, "lighting.static.light_curve", curve)
    session.curve_inputs, session.dirty = nil, true
    return true, "Use Apply static to update the curve."
end
handlers.curve_default = function(_, session)
    lighthouse.put(session.work, "lighting.static.light_curve", {})
    session.curve_inputs, session.dirty = nil, true
    return true, "Use Apply static to restore the engine curve."
end
handlers.ao_off = function(_, session)
    lighthouse.put(session.work, "lighting.static.ao_gamma", 0)
    session.inputs["f" .. lighthouse.schema["lighting.static.ao_gamma"].index] = "0"
    session.dirty = true
    return true, "Use Apply static to disable ambient shading."
end
handlers.edit_environment = function(_, session)
    local definition = lighthouse.environments[session.environment_name or ""]
    if not definition then
        return nil, "Choose an environment"
    end
    if definition.env_check then
        return nil, "Lua callback rules must be edited in the mod that registers them"
    end
    local serializable = lighthouse.copy(definition)
    serializable.env_check = nil
    session.conditions = core.write_json(serializable, true)
    session.group, session.advanced, session.page = "Conditions", true, 1
    return true, "Environment loaded for editing"
end
handlers.new_environment = function(_, session)
    local definition = {scene = session.selected or "Natural Day", priority = 80, transition = 5}
    session.conditions = core.write_json(definition, true)
    session.environment_name = "My Rule"
    session.group, session.advanced, session.page = "Conditions", true, 1
    return true
end
handlers.save_environment = function(_, session)
    if #tostring(session.conditions) > 32768 then
        return nil, "Oversized definition"
    end
    local definition = core.parse_json(session.conditions or "", nil, true)
    local ok, message = lighthouse.register_environment(session.environment_name, definition)
    if not ok then
        return nil, message
    end
    lighthouse.data.environments[session.environment_name] = lighthouse.copy(definition)
    lighthouse.persist()
    return true, "Environment saved"
end
handlers.delete_environment = function(_, session)
    local name = session.environment_name
    if not lighthouse.data.environments[name] then
        return nil, "Choose a saved rule. Built in rules can only be edited."
    end
    lighthouse.data.environments[name] = nil
    lighthouse.environments[name] = lighthouse.copy(lighthouse.builtin_environments[name])
    lighthouse.persist()
    for _, player in ipairs(core.get_connected_players()) do
        lighthouse.update_environment(player, nil, true)
    end
    return true, "Saved rule removed"
end

local function capture_controls(session, fields)
    local changed_family = false
    if fields.biome_family then
        local id = (session.biome_ids or {})[tonumber(fields.biome_family) or 0]
        if id and id ~= session.biome_id then
            session.biome_id = id
            session.scene_names = scene_choices("Biomes", session)
            session.selected = lighthouse.biome_families[id].day
            changed_family = true
        end
    end
    local lists = {
        scene = {"scene_names", "selected"},
        profile = {"profile_names", "library_selected"},
        environment = {"environment_names", "environment_name"},
    }
    for field, mapping in pairs(lists) do
        if fields[field] and not (field == "scene" and changed_family) then
            session[mapping[2]] = (session[mapping[1]] or {})[tonumber(fields[field]) or 0] or session[mapping[2]]
        end
    end
    for field, limit in pairs({save_name = 48, json = 32768, environment_name = 48, conditions = 32768, curve_amount = 16}) do
        if fields[field] then
            if #fields[field] > limit then
                return nil, field .. " is too long"
            end
            session[field] = fields[field]
        end
    end
    if fields.curve_kind then
        session.curve_kind = ({"Engine Default", "Linear", "Gamma", "Soft Contrast", "High Contrast", "Bright Nights", "Deep Darkness", "Custom"})[tonumber(fields.curve_kind) or 0] or session.curve_kind
    end
    if fields.category then
        session.category = categories[tonumber(fields.category) or 0] or session.category
    end
    return true
end

local function navigate(session, fields)
    if fields.section then
        session.tab = navigation[tonumber(fields.section) or 0] or session.tab
        session.advanced = false
    end
    for index, name in ipairs(navigation) do
        if fields["nav" .. index] then
            session.tab, session.advanced = name, false
        end
    end
    if fields.group then
        local group = ({"Light", "Atmosphere", "Effects", "Advanced", "Conditions"})[tonumber(fields.group) or 0]
        if group and group ~= session.group then
            session.group, session.page = group, 1
        end
        if session.group == "Advanced" or session.group == "Conditions" then
            session.advanced = true
        end
    end
    if fields.advanced then
        session.advanced = true
        session.page = 1
    end
    if fields.quick then
        session.advanced = false
        session.tab = session.group == "Conditions" and "ENVIRONMENTS" or "EDITOR"
        if session.group == "Advanced" or session.group == "Conditions" then session.group = "Light" end
    end
    if fields.page_prev then
        session.page = math.max(1, session.page - 1)
    elseif fields.page_next then
        session.page = math.min(session.pages or 20, session.page + 1)
    end
end

local function schedule_preview(player, session)
    if not lighthouse.allowed(player:get_player_name()) then
        return
    end
    if session.pending_preview then
        return
    end
    local token = {}
    session.pending_preview = token
    local player_name = player:get_player_name()
    core.after(0.1, function()
        if lighthouse.sessions[player_name] ~= session or session.pending_preview ~= token then
            return
        end
        session.pending_preview = nil
        local connected = core.get_player_by_name(player_name)
        if connected and lighthouse.allowed(player_name) then
            local ok, message = preview_work(connected, session, false)
            session.message = ui.status_message(ok, message)
            if not ok then
                core.chat_send_player(player_name, "[Lighthouse] " .. session.message)
            end
        end
    end)
end

local function schedule_redraw(player, session)
    local token = {}
    session.pending_redraw = token
    local generation = session.form_generation
    local player_name = player:get_player_name()
    -- Replace the form after a quiet interval, so numeric fields catch up
    -- without rebuilding the form on every step of a drag.
    core.after(0.35, function()
        if lighthouse.sessions[player_name] ~= session or session.pending_redraw ~= token
                or not session.open or session.form_generation ~= generation then
            return
        end
        session.pending_redraw = nil
        local connected = core.get_player_by_name(player_name)
        if connected and lighthouse.allowed(player_name) then
            if session.advanced then
                lighthouse.show_advanced(connected)
            else
                lighthouse.show(connected)
            end
        end
    end)
end

function lighthouse.receive_fields(player, formname, fields)
    if formname ~= "lighthouse:quick" and formname ~= "lighthouse:advanced" then
        return false
    end
    local player_name = player:get_player_name()
    local session = lighthouse.sessions[player_name]
    if not session or not lighthouse.allowed(player_name) then
        return true
    end
    local valid, validation_message, changed = ui.read_fields(session, fields)
    local previous_scene = session.selected
    local previous_profile, previous_environment = session.library_selected, session.environment_name
    local previous_tab, previous_group, previous_page, previous_advanced = session.tab, session.group, session.page, session.advanced
    local captured, capture_message = capture_controls(session, fields)
    if not captured then
        session.message = capture_message
        return true
    end
    session.message = validation_message or ""
    navigate(session, fields)
    local explicit_action = false
    local selection_action = false
    for name in pairs(handlers) do
        if fields[name] then
            explicit_action = true
        end
    end
    if not explicit_action then
        if previous_scene ~= session.selected and (fields.scene or fields.biome_family) then
            fields.preview_scene = "true"
            selection_action = true
        elseif previous_profile ~= session.library_selected and fields.profile then
            fields.preview_profile = "true"
            selection_action = true
        elseif previous_environment ~= session.environment_name and fields.environment then
            fields.edit_environment = "true"
            selection_action = true
        end
    end
    if fields.quit then
        session.open, session.pending_redraw = false, nil
        if valid and changed then
            schedule_preview(player, session)
        end
        return true
    end
    if fields.automation_source then
        local allowed, message = lighthouse.require(player_name)
        local source = (session.automation_sources or {})[tonumber(fields.automation_source) or 0]
        if allowed and source ~= lighthouse.get_automation_source() then
            allowed, message = lighthouse.set_automation_source(source)
        end
        session.message = allowed and "" or ui.status_message(false, message)
    end
    if fields.automatic ~= nil and (fields.automatic == "true") ~= lighthouse.data.automatic then
        local allowed, message = lighthouse.require(player_name)
        if allowed then
            allowed, message = lighthouse.set_automatic(fields.automatic == "true")
        end
        session.message = allowed and "" or ui.status_message(false, message)
    end
    local handled = false
    for name, handler in pairs(handlers) do
        if fields[name] then
            handled = true
            local allowed, message = lighthouse.require(player_name)
            local needs_valid = name == "preview" or name == "apply" or name == "apply_static"
                or name == "personal" or name == "save" or name == "overwrite"
            if allowed and needs_valid and not valid then
                allowed, message = nil, validation_message
            end
            if allowed and not selection_action and not lighthouse.throttle(player_name, "form") then
                allowed, message = nil, "Please wait a moment"
            end
            if allowed then
                local ran, result, detail = pcall(handler, player, session)
                if ran then
                    allowed, message = result == true, detail
                else
                    core.log("warning", "[Lighthouse] Editor action: " .. tostring(result))
                    allowed, message = nil, "Operation failed. Check the server log."
                end
            end
            session.message = ui.status_message(allowed, message)
            if allowed and fields.hud_off then
                session.open, session.pending_redraw = false, nil
                core.close_formspec(player_name, formname)
                return true
            end
            if not allowed then
                core.chat_send_player(player_name, "[Lighthouse] " .. session.message)
            end
            break
        end
    end
    if valid and changed and not handled then
        schedule_preview(player, session)
        session.last_changed = session.group
    end
    local only_slider = false
    for name, raw in pairs(fields) do
        if name:match("^slider") then
            only_slider = only_slider or core.explode_scrollbar_event(raw).type == "CHG"
        end
    end
    -- Redraw immediately on navigation.
    -- Defer redraw only while a slider is being adjusted.
    only_slider = only_slider and previous_tab == session.tab and previous_group == session.group
        and previous_page == session.page and previous_advanced == session.advanced
        and not fields.key_enter_field
    if only_slider and valid and not handled then
        schedule_redraw(player, session)
        return true
    end
    if session.advanced then
        lighthouse.show_advanced(player)
    else
        lighthouse.show(player)
    end
    return true
end

core.register_on_player_receive_fields(function(player, formname, fields)
    local ok, result = pcall(lighthouse.receive_fields, player, formname, fields)
    if not ok then
        core.log("warning", "[Lighthouse] Form input: " .. tostring(result))
        return formname:sub(1, 11) == "lighthouse:"
    end
    return result
end)