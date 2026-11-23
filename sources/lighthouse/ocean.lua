lighthouse.ocean_water_nodes = {
    "default:water_source", "default:water_flowing",
    "mcl_core:water_source", "mcl_core:water_flowing",
}

-- Read counts from the shared environment scan
function lighthouse.detect_ocean(pos, totals)
    local worlds = rawget(_G, "mcl_worlds")
    if core.get_modpath("mcl_core") and worlds and worlds.pos_to_dimension
            and worlds.pos_to_dimension(pos) ~= "overworld" then
        return false, 0
    end
    local count = 0
    for _, name in ipairs(lighthouse.ocean_water_nodes) do
        count = count + (totals[name] or 0)
    end
    return count > lighthouse.config.ocean_water_count, count
end