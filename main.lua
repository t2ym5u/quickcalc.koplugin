-- Add the plugin dir and game-common to the Lua path.
local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
package.path = _dir .. "?.lua;" .. _dir .. "common/?.lua;" .. package.path

-- This plugin's own modules are loaded by path, not by name: names like
-- "screen" or "format" are shared by every plugin in package.loaded.
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local PluginBase = require("plugin_base")
local _          = require("i18n")

require("i18n").extend(lrequire("i18n_fr"))
local CalcScreen = lrequire("screen")

-- ---------------------------------------------------------------------------
-- QuickCalc
--
-- A utility, not a game: like Plugin Manager or Dashboard it gets its own
-- entry in KOReader's Tools menu instead of joining Tools → Games, and it
-- keeps no play statistics (a calculator has no business in Dashboard's
-- "recently played").
-- ---------------------------------------------------------------------------

local QuickCalc = PluginBase:extend{
    -- MUST equal the plugin directory's basename (quickcalc.koplugin).
    name      = "quickcalc",
    menu_text = _("Calculator"),
    menu_hint = "tools",
}

function QuickCalc:addToMainMenu(menu_items)
    menu_items.quickcalc = {
        text         = _("Calculator"),
        sorting_hint = "tools",
        callback     = function() self:showGame() end,
    }
end

function QuickCalc:showGame()
    if self.screen then return end
    self.screen = self:createScreen()
    require("ui/uimanager"):show(self.screen)
end

function QuickCalc:onScreenClosed()
    self.screen = nil
end

-- Nothing of ours lives in the shared game_stats.lua.
function QuickCalc:deletePluginSettings() end

function QuickCalc:createScreen()
    return CalcScreen:new{ plugin = self }
end

return QuickCalc
