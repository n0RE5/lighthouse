core.register_on_mods_loaded(function()
    if not core.get_modpath("weather") or type(weather) ~= "table"
            or type(weather.get) ~= "function" then
        return
    end
    -- MTG Weather updates clouds and lighting every 8 seconds &
    -- resetting lighting settings.
    -- While a Lighthouse profile is active, omit lighting and clouds
    -- from weather.get results to prevent MTG from overwriting mod settings.
    -- Keep the original function for reading cloud cover.
    -- May use it in future updates...
    local get_weather = weather.get
    weather.get = function(player)
        local values = get_weather(player)
        if values and lighthouse.has_active_profile(player) then
            values = lighthouse.copy(values)
            values.lighting, values.clouds = nil, nil
        end
        return values
    end
    if lighthouse.config.mtg_clouds then
        lighthouse.register_weather_source("MTG clouds", function(player)
            local values = get_weather(player)
            local density = values and values.clouds and values.clouds.density
            if type(density) ~= "number" then
                return nil
            end
            if density >= 0.8 then
                return "overcast"
            elseif density >= 0.45 then
                return "cloudy"
            end
            return "clear"
        end, -10)
    end
end)