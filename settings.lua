local function number_setting(name, default, minimum, maximum)
    local value = tonumber(core.settings:get(name)) or default
    if value ~= value then
        return default
    end
    return math.max(minimum, math.min(maximum, value))
end

lighthouse.config = {
    check_interval = number_setting("lighthouse_interval", 0.5, 0.5, 30),
    transition_interval = number_setting("lighthouse_transition_interval", 0.05, 0.05, 2),
    hold_time = number_setting("lighthouse_hold_time", 4, 0, 60),
    detection_radius = number_setting("lighthouse_detection_radius", 12, 1, 20),
    ocean_water_count = number_setting("lighthouse_ocean_water_count", 200, 0, 68921),
    automatic = core.settings:get_bool("lighthouse_automatic", false),
    mtg_clouds = core.settings:get_bool("lighthouse_mtg_clouds", false),
}

lighthouse.current_time = 0
lighthouse.players = {}
lighthouse.sessions = {}
lighthouse.profiles = {}
lighthouse.scenes = {}
lighthouse.environments = {}
lighthouse.weather_sources = {}
lighthouse.weather_states = {
    clear = true,
    cloudy = true,
    overcast = true,
    fog = true,
    rain = true,
    heavy_rain = true,
    thunderstorm = true,
    snow = true,
    blizzard = true,
}