local modpath = core.get_modpath("lighthouse")
dofile(modpath .. "/sources/lighthouse/ocean.lua")
dofile(modpath .. "/sources/lighthouse/context.lua")
dofile(modpath .. "/sources/lighthouse/rules.lua")
lighthouse.register_lighthouse_rules()
lighthouse.builtin_environments = lighthouse.copy(lighthouse.environments)

function lighthouse.get_biome_scene(biome, timeofday)
    if type(timeofday) ~= "number" then return nil end
    local family = lighthouse.get_biome_family(biome)
    if not family or family.id == "caves" then return nil end
    for _, period in ipairs(lighthouse.biome_periods) do
        if lighthouse.time_matches(timeofday, period) then return family.phases[period.key] end
    end
end

local ok, message = lighthouse.register_automation_source("lighthouse", {
    resolve = function(player, context)
        local check_def = context or lighthouse.get_environment_context(player)
        if check_def.loaded == false then
            return nil, "Waiting for map data", true
        end
        local name, definition = lighthouse.select_environment(check_def)
        if not definition then return nil, "No environment matches the current conditions" end
        return {name = name, scene = definition.scene,
            transition = definition.transition, context = check_def}
    end,
})

if not ok then error("[Lighthouse] Built-in automation source: " .. tostring(message)) end