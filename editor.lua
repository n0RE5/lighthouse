lighthouse.ui = {}
local ui = lighthouse.ui
local routine_messages = {
    ["Applied"] = true,
    ["Unchanged"] = true,
    ["Applied to server"] = true,
    ["Preview remains active after closing the editor"] = true,
    ["Preview ended"] = true,
    ["Loaded into editor"] = true,
    ["Profile loaded into editor"] = true,
    ["Environment loaded for editing"] = true,
}

function ui.escape(value)
    return core.formspec_escape(tostring(value or ""))
end

function ui.status_message(success, message, fallback)
    if success and routine_messages[message] then return "" end
    if type(message) == "string" and message ~= "" and message:lower() ~= "true"
            and message:lower() ~= "false" and message:lower() ~= "nil" then
        return message
    end
    return fallback or (success and "" or "Operation failed")
end

function ui.form_style()
    return "style_type[button,button_exit;bgcolor=#344e68;bgcolor_hovered=#456883;bgcolor_pressed=#253c52;textcolor=#f1f6fa;border=true]"
        .. "style_type[label,textarea;textcolor=#e3edf5]"
end

function ui.begin_form(session)
    session.visible, session.rendered = {}, {}
    session.open = true
    session.form_generation = (session.form_generation or 0) + 1
end

function ui.label(x, y, text)
    return ("label[%g,%g;%s]"):format(x, y, ui.escape(text))
end

function ui.button(x, y, width, name, text)
    return ("box[%g,%g;%g,0.59;#71889c]button[%g,%g;%g,0.55;%s;%s]"):format(
        x - 0.02, y - 0.02, width + 0.04, x, y, width, name, ui.escape(text))
end

function ui.field(x, y, width, name, label, value)
    return ("field[%g,%g;%g,0.55;%s;%s;%s]field_close_on_enter[%s;false]"):format(
        x, y, width, name, ui.escape(label), ui.escape(value), name)
end

function ui.text(x, y, width, height, text)
    return ("textarea[%g,%g;%g,%g;;;%s]"):format(x, y, width, height, ui.escape(text))
end

function ui.dropdown(x, y, width, name, choices, selected)
    local labels = {}
    local index = 1
    for number, choice in ipairs(choices) do
        labels[#labels + 1] = ui.escape(choice)
        if choice == selected then
            index = number
        end
    end
    return ("dropdown[%g,%g;%g,0.55;%s;%s;%d;true]"):format(x, y, width, name, table.concat(labels, ","), index)
end

function ui.checkbox(x, y, name, label, checked)
    return ("checkbox[%g,%g;%s;%s;%s]"):format(x, y, name, ui.escape(label), tostring(checked == true))
end

function lighthouse.session(player)
    local player_name = player:get_player_name()
    local session = lighthouse.sessions[player_name]
    if not session then
        session = {
            tab = "SCENES",
            group = "Light",
            page = 1,
            work = assert(lighthouse.resolve_settings(player)),
            selected = lighthouse.get_player_state(player).scene
                or (lighthouse.data.global and lighthouse.data.global.name),
            category = "Biomes",
            name = "Current world",
            inputs = {},
            visible = {},
            message = "",
            save_name = "My Scene",
            curve_kind = "Gamma",
            curve_amount = "1.2",
        }
        lighthouse.sessions[player_name] = session
    end
    return session
end

function ui.display_value(session, field)
    local name = "f" .. field.index
    if session.inputs[name] ~= nil then
        return session.inputs[name]
    end
    local value = lighthouse.get(session.work, field.path)
    if field.kind == "textures" then
        return table.concat(value or {}, " | ")
    end
    return value
end

function ui.profile_field(session, field, x, y, width, slider)
    local name = "f" .. field.index
    session.visible[name] = field
    local value = ui.display_value(session, field)
    session.rendered = session.rendered or {}
    session.rendered[name] = tostring(value)
    local result
    if field.kind == "boolean" then
        local checked = value == true or value == "true"
        result = ui.checkbox(x, y + 0.2, name, field.label, checked)
    elseif field.kind == "enum" then
        result = ui.label(x, y - 0.2, field.label)
            .. ui.dropdown(x, y, width, name, field.options, value)
    else
        result = ui.field(x, y, width, name, field.label, value)
        if slider and field.kind == "number" then
            local minimum, maximum = field.minimum, field.maximum
            if field.path == "lighting.saturation" then
                minimum, maximum = 0, 1.5
            elseif field.path == "lighting.exposure.exposure_correction" then
                minimum, maximum = -1, 1
            end
            local position = ((tonumber(value) or field.default) - minimum) / (maximum - minimum)
            session.visible["slider" .. field.index] = {field = field, minimum = minimum, maximum = maximum}
            result = result .. ("scrollbaroptions[min=0;max=1000;smallstep=10]scrollbar[%g,%g;%g,0.25;horizontal;slider%d;%d]"):format(
                x, y + 0.64, width, field.index, math.max(0, math.min(1000, math.floor(position * 1000))))
        elseif field.kind == "color" and type(value) == "string" and value:match("^#%x+$") then
            result = result .. ("box[%g,%g;%g,0.18;%s]"):format(x, y + 0.65, width, ui.escape(value))
        end
    end
    local help = field.path
    if field.path:find("lighting.static", 1, true) then
        help = "Use Apply static to update this setting."
    elseif field.group == "Effects" then
        help = help .. ": requires the corresponding client graphics setting"
    end
    return result .. "tooltip[" .. name .. ";" .. ui.escape(help) .. "]"
end

local function parse_input(field, raw)
    if field.kind == "number" or field.kind == "integer" then
        return tonumber(raw)
    elseif field.kind == "boolean" then
        if raw == "true" or raw == true then
            return true
        elseif raw == "false" or raw == false then
            return false
        end
        return nil
    elseif field.kind == "textures" then
        local values = {}
        for texture in tostring(raw):gmatch("[^|]+") do
            values[#values + 1] = texture:match("^%s*(.-)%s*$")
        end
        return values
    end
    return raw
end

-- Raw edits survive navigation, even when temporarily invalid. Only a validated copy can preview.
function ui.read_fields(session, fields)
    local changed = false
    local ordered = {}
    for name in pairs(session.visible) do
        ordered[#ordered + 1] = name
    end
    table.sort(ordered, function(first, second)
        local first_slider = first:match("^slider") ~= nil
        local second_slider = second:match("^slider") ~= nil
        if first_slider ~= second_slider then
            return not first_slider
        end
        return first < second
    end)
    for _, name in ipairs(ordered) do
        local definition = session.visible[name]
        local raw = fields[name]
        if raw ~= nil then
            if type(raw) ~= "string" or #raw > 2048 then
                return nil, "Field is too long"
            end
            if name:match("^slider") then
                local event = core.explode_scrollbar_event(raw)
                if event.type == "CHG" then
                    local position = math.max(0, math.min(1000, event.value)) / 1000
                    local value = definition.minimum + position * (definition.maximum - definition.minimum)
                    local input_name = "f" .. definition.field.index
                    session.inputs[input_name] = tostring(math.floor(value * 1000 + 0.5) / 1000)
                    changed = true
                end
            else
                local value = raw
                if definition.kind == "enum" then
                    value = definition.options[tonumber(raw) or 0]
                    if not value then
                        return nil, "Invalid choice"
                    end
                end
                -- Unchanged text accompanies scrollbar/button events. It may be
                -- older than the live slider value held by this session.
                local echo = (session.rendered or {})[name] == tostring(value)
                    and fields.key_enter_field ~= name
                if not echo then
                    if tostring(ui.display_value(session, definition)) ~= tostring(value) then
                        changed = true
                    end
                    session.inputs[name] = value
                end
            end
        end
    end
    local candidate = lighthouse.copy(session.work)
    for name, raw in pairs(session.inputs) do
        local field = lighthouse.fields[tonumber(name:match("^f(%d+)$"))]
        if field and session.visible[name] then
            local value = parse_input(field, raw)
            if value == nil then
                return nil, field.label .. ": enter a valid value"
            end
            lighthouse.put(candidate, field.path, value)
        end
    end
    if session.advanced and session.group == "Advanced" and session.page == 1 then
        local current = lighthouse.get(candidate, "lighting.static.light_curve")
        local curve = #current == 0 and lighthouse.curve("Linear") or lighthouse.copy(current)
        local curve_changed = false
        for level = 1, 16 do
            local name = "level" .. level
            if fields[name] then
                session.curve_inputs = session.curve_inputs or {}
                session.curve_inputs[level] = fields[name]:sub(1, 32)
            end
            local raw = session.curve_inputs and session.curve_inputs[level]
            if raw then
                local value = tonumber(raw)
                if not value then
                    return nil, "Curve level " .. (level - 1) .. " must be a number"
                end
                if value ~= curve[level] then
                    curve_changed = true
                end
                curve[level] = value
            end
        end
        if curve_changed then
            lighthouse.put(candidate, "lighting.static.light_curve", curve)
            changed = true
        end
    end
    local checked, message = lighthouse.validate(candidate, "full")
    if not checked then
        return nil, message
    end
    if not lighthouse.equal(session.work, checked) then
        changed = true
        session.dirty = true
        session.work = checked
    end
    return true, nil, changed
end

function ui.curve_editor(session)
    local kinds = {"Engine Default", "Linear", "Gamma", "Soft Contrast", "High Contrast", "Bright Nights", "Deep Darkness", "Custom"}
    local curve = lighthouse.get(session.work, "lighting.static.light_curve")
    local shown = #curve == 0 and lighthouse.curve("Linear") or curve
    local result = ui.dropdown(0.6, 1.7, 3.2, "curve_kind", kinds, session.curve_kind)
        .. ui.field(4.1, 1.7, 2, "curve_amount", "Curve amount", session.curve_amount)
        .. ui.button(6.5, 1.7, 2.5, "generate", "Generate")
        .. ui.button(9.3, 1.7, 3.9, "curve_default", "Engine curve")
        .. ui.label(0.6, 2.65, #curve == 0 and "Engine curve active. The graph shows a linear reference." or "Brightness 0 to 255. Light levels 0 to 15.")
        .. "box[1,3.1;0.02,1.8;#667a90]box[1,4.9;11.8,0.02;#667a90]"
        .. ui.label(0.35, 3.2, "255") .. ui.label(0.55, 4.9, "0")
    for level = 1, 16 do
        local x = 1.15 + (level - 1) * 0.72
        local height = math.max(0.015, shown[level] / 255 * 1.65)
        result = result .. ("box[%g,%g;0.42,%g;#6fbdaf]"):format(x, 4.9 - height, height)
            .. ui.label(x, 5.12, level - 1)
        local raw = session.curve_inputs and session.curve_inputs[level] or shown[level]
        result = result .. ui.field(0.6 + ((level - 1) % 8) * 1.6, 5.9 + math.floor((level - 1) / 8) * 1.2,
            1.3, "level" .. level, "Level " .. (level - 1), raw)
    end
    result = result .. ui.profile_field(session, lighthouse.schema["lighting.static.ao_gamma"], 0.6, 8.3, 4, false)
        .. ui.button(4.9, 8.3, 2.4, "ao_off", "Disable AO")
        .. ui.button(8, 8.3, 4.7, "apply_static", "Apply static to Preview")
    return result
end

function lighthouse.show_advanced(player, group)
    if not lighthouse.allowed(player:get_player_name()) then
        return nil, "Lighthouse privilege required"
    end
    local session = lighthouse.session(player)
    session.advanced = true
    session.group = group or session.group
    ui.begin_form(session)
    if session.group == "Advanced" then
        local count = 0
        for _, field in ipairs(lighthouse.fields) do
            if field.group == "Advanced" and field.kind ~= "curve" then
                count = count + 1
            end
        end
        session.pages = 1 + math.ceil(count / 6)
    end
    local groups = {"Light", "Atmosphere", "Effects", "Advanced", "Conditions"}
    local result = "formspec_version[6]size[14,10.8]no_prepend[]bgcolor[#152032;false;#00000000]"
        .. ui.form_style()
        .. ui.label(0.6, 0.45, "LIGHTHOUSE")
        .. ui.label(0.6, 0.95, "Advanced Editor")
        .. ui.dropdown(5.5, 0.2, 4.5, "group", groups, session.group)
        .. ui.button(10.4, 0.2, 3, "quick", "Back to menu")
    if session.group == "Conditions" then
        result = result .. ui.field(0.6, 1.7, 6, "environment_name", "Environment name", session.environment_name or "My Rule")
            .. ("textarea[0.6,3;12.7,4.8;conditions;Environment JSON;%s]"):format(ui.escape(session.conditions or '{"scene":"Natural Day","priority":80,"transition":5}'))
            .. ui.button(0.6, 8.3, 4, "save_environment", "Save environment")
            .. ui.button(0.6, 9.2, 4, "delete_environment", "Remove saved rule")
            .. ui.text(5, 8.1, 8.2, 1.5, "Set the scene and its conditions in JSON. Higher priority wins. Removing a custom edit restores the original rule.")
    elseif session.group == "Advanced" and session.page == 1 then
        result = result .. ui.curve_editor(session)
    else
        local fields = {}
        for _, field in ipairs(lighthouse.fields) do
            if field.group == session.group and field.kind ~= "curve" then
                fields[#fields + 1] = field
            end
        end
        local offset = session.group == "Advanced" and 1 or 0
        local pages = math.ceil(#fields / 6) + offset
        session.page = math.max(1 + offset, math.min(session.page, math.max(1 + offset, pages)))
        local start = (session.page - 1 - offset) * 6
        for slot = 1, 6 do
            local field = fields[start + slot]
            if field then
                result = result .. ui.profile_field(session, field, 0.6 + math.floor((slot - 1) / 3) * 6.5,
                    2.1 + ((slot - 1) % 3) * 2.0, 5.8, false)
            end
        end
        session.pages = math.max(pages, 1)
    end
    if session.group ~= "Conditions" then
        result = result .. ui.button(0.6, 9.5, 1.2, "page_prev", "<")
            .. ui.label(2.1, 9.8, "Page " .. session.page)
            .. ui.button(3.6, 9.5, 1.2, "page_next", ">")
            .. ui.button(5.2, 9.5, 2.5, "preview", "Preview")
            .. ui.button(8, 9.5, 2.5, "apply", "Apply global")
            .. ui.button(10.8, 9.5, 2.5, "revert", "Revert")
    end
    result = result .. ui.text(0.6, 10.25, 12.7, 0.5, (session.message or ""):sub(1, 120))
    session.form = result
    core.show_formspec(player:get_player_name(), "lighthouse:advanced", result)
end