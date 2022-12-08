local wibox     = require("wibox")
local awful     = require("awful")
local gears     = require("gears")
local config    = require("config")
local no_scroll = require("src.widgets.helper.no_scroll")

local shapes = require("src.util.shapes")
local redshift = require("src.util.redshift")

local music_widget           = require("src.widgets.music")
-- local network_manager_widget = require("src.widgets.network_manager")
local dropdown               = require("src.widgets.util.dropdown")
local cmd_slider             = require("src.widgets.components.cmd_slider")
local icon_button            = require("src.widgets.components.icon_button")

local config_dir = gears.filesystem.get_configuration_dir()

-- TODO volume/brightness sliders don't have correct initial values

local function toggle_icon_button(icon, callback, tooltip, initial)
    local state = initial or false

    local button = icon_button(icon, nil, tooltip)

    local function update_color()
        if state then
            button.bg = config.button.active

            button.old_bg = nil
        else
            button.bg = config.button.normal

            button.old_bg = nil
        end
    end

    button:connect_signal("button::press", no_scroll(function()
        state = not state

        update_color()

        callback(state)
    end))

    update_color()

    return button
end

local function create_control_center()
    local widget = wibox.widget {
        {
            {
                music_widget(),
                bg = config.button.normal,
                widget = wibox.container.background,
                shape = shapes.rounded_rect(),
                id = "music-widget-container"
            },
            {
                layout = wibox.layout.grid,
                forced_num_rows = 4,
                forced_num_cols = 3,
                forced_height = 320,
                forced_width = 290,
                spacing = 10,
                id = "layout-grid",
                expand = true,
                homogeneous = true
            },
            layout = wibox.layout.fixed.horizontal,
            spacing = 10,
        },
        widget = wibox.container.margin,
        margins = 10
    }

    local dropdown = dropdown {
        widget = widget,
        shape = shapes.rounded_rect(),

        icon_closed = config_dir .. "icon/options-outline.svg",
        icon_open = config_dir .. "icon/options-outline.svg",
    }

    local grid = widget:get_children_by_id("layout-grid")[1]

    local brightness_control = cmd_slider {
        image = config_dir .. "icon/sunny-outline.svg",
        on_value_change = function(slider_value)
            awful.spawn("xbacklight -set " .. slider_value)
        end,
        update_command = "xbacklight -get",
    }

    -- brightness slider
    grid:add_widget_at(
        brightness_control,
        1, 1, 3, 1
    )

    local volume_control = cmd_slider {
        image = config_dir .. "icon/volume/volume-high-outline.svg",
        on_value_change = function(slider_value)
            awful.spawn("pactl -- set-sink-volume 0 " .. slider_value .. "%")
        end,
        update_command = "pactl list sinks | grep '^[[:space:]]Volume:' | head -n $(( $SINK + 1 )) | tail -n 1 | sed -e 's,.* \\([0-9][0-9]*\\)%.*,\\1,'",
        id = "cmd-slider-volume"
    }

    -- volume slider
    grid:add_widget_at(
        volume_control,
        1, 2, 3, 1
    )

    -- network manager
    grid:add_widget_at(
        icon_button(config_dir .. "icon/control-center/wifi-outline.svg", function()
            -- network_manager_widget()
        end, "Network Configuration"),
        1, 3, 1, 1
    )

    -- bluetooth
    grid:add_widget_at(
        icon_button(config_dir .. "icon/control-center/bluetooth-outline.svg", function(state)
            -- TODO bluetooth applet
        end, "Bluetooth Configuration"),
        2, 3, 1, 1
    )

    grid:add_widget_at(
        toggle_icon_button(config_dir .. "icon/control-center/moon.svg", function(state)
            redshift.toggle()
        end, "Toggle Night Colors", redshift.state == 1),
        3, 3, 1, 1
    )

    -- TODO this button
    -- do not disturb
    -- might need to be a toggle_icon_button
    grid:add_widget_at(
        icon_button(config_dir .. "icon/control-center/notifications-outline.svg", function()
            -- TODO change icon to notifications-off-outline, toggle do not disturb
        end),
        4, 1, 1, 1
    )

    -- system specs
    grid:add_widget_at(
        icon_button(config_dir .. "icon/control-center/hardware-chip-outline.svg", function ()
            SystemInfo.toggle()
        end),
        4, 2, 1, 1
    )

    -- power menu
    grid:add_widget_at(
        icon_button(config_dir .. "icon/exit-outline.svg", function()
            awesome.emit_signal('module::exit_screen:show')
        end),
        4, 3, 1, 1
    )

    local music_widget = widget:get_children_by_id("music-widget-container")[1].widget

    brightness_control.visible = false
    volume_control.visible = false

    widget:connect_signal("property::visible", function(w)
        local visible = w.visible

        music_widget.visible = visible
        music_widget:emit_signal("property::visible")

        brightness_control.visible = visible
        volume_control.visible = visible
    end)

    return dropdown:get_button()
end

return create_control_center