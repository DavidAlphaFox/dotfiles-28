local testable = require("util.testable")
local gcolor = require("gears.color")

--- Convert decimal integers to hexadecimal
---@param number number the number to convert
---@return string hex that number in hexadecimal
local function num_to_hex(number)
    local rounded = math.floor(number)

    return string.format("%x", rounded)
end

--- Lighten a given color a bit
---@param color string|table the color, as hex or gears.color, or whatever gears.color.parse_color takes as an argument
---@param amount number?
---@return string lightened the color, now lighter, in hexadecimal format
local function lighten_color(color, amount)
    amount = amount or 0.1

    local channels = table.pack(gcolor.parse_color(color))

    local hex_channels = { "", "", "", "" }

    for i, channel in ipairs(channels) do
        -- Don't adjust transparency
        if i ~= 4 then
            hex_channels[i] = num_to_hex((channel + amount) * 255)
        else
            hex_channels[i] = num_to_hex(channel * 255)
        end
    end

    -- Goofy ahh string concatenation is faster than a cleaner looking solution
    return "#" .. hex_channels[1] .. hex_channels[2] .. hex_channels[3] .. hex_channels[4]
end

return testable(lighten_color, {
    testable.assert(function()
        return lighten_color("#000000", 0.1) == "#191919ff"
    end, "Lighten Slightly"),
    testable.assert(function()
        return lighten_color("#000000") == "#191919ff"
    end, "Lighten Automatically"),
    testable.assert(function()
        return lighten_color("#000000", 1.0) == "#ffffffff"
    end, "Lighten Entirely"),
})