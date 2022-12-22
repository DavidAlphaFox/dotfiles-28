--[[
    Test handler injector for awesomewm signal / standalone tests
]]

-- TODO unload files once tests completed

local test = require("lib.test")
local fake_require = require("lib.test.fake_require")

local spawn = require("src.agnostic.spawn")
local print = require("src.agnostic.print")

local fs = require("src.util.fs")
local directories = fs.dirs

--- Split a string into an array by newlines
---@param s string the string to split up
---@return string[] lines
local function split_newlines(s)
    local lines = {}
    for sub in string.gmatch(s, "[^\r\n]+") do
        table.insert(lines, sub)
    end

    return lines
end

--- Convert a filesystem path to a lua module name
---@param path string
---@return string
local function as_module(path)
    local new_path = path
        -- remove ./
        :gsub("%./", "")
        -- remove .lua
        :gsub(".lua", "")
        -- / -> .
        :gsub("/", ".")

    return new_path
end

--[[
--- Load a function as if using require() but without using cache
---@param path string
local function load_module(path)
    local true_path = directories.config .. path

    local contents = fs.read(true_path)

    if not contents then
        print("File " .. path .. " does not load")
    else
        load(inject_require .. contents)()
    end
end
]]

local function perform_tests()
    print("\27[1m\n\n" .. string.rep("=", 80) .. "\nRunning unit tests\n" .. string.rep("=", 80) .. "\n\27[0m")

    spawn("cd " .. directories.config .. "; find test -name \"*.lua\" | grep -v \"test/init.lua\"",
        function(res)
            local lines = split_newlines(res)

            for _, line in ipairs(lines) do
                local modname = as_module(line)

                fake_require(modname)
                
                -- load_module(line)

                -- this approach works but leaves data in the require cache
                --[[    
                local as_module = as_module(line)

                require(as_module)

                -- some versions of lua ( < 5.1?) use _LOADED? idk man
                package.loaded[as_module] = false
                ]]
            end
        end)
end

if test.has_awesome() then
    awesome.connect_signal("awesome::dotfiles::test", function()
        perform_tests()
    end)
else
    perform_tests()
end

--[[
test.suite("example suite",
    test.assert(false, "falsey"),
    test.assert(true, "truthy"),
    test.test(function ()
        local a = nil

        a.b = 't'
    end, "fail throw"),
    test.test(function () end, "all good"),
    test.awesome_only_test(function () end, "awesome only")
)
]]
