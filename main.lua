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

-- The game screen -- and the boards, word lists and puzzle banks it pulls
-- in -- loads the first time the game is opened, not when KOReader starts:
-- KOReader loads every plugin at startup and keeps it all session, so a
-- top-level require here costs memory even if the game is never played.
-- KOReader has put package.path back by then, so our directories are added
-- again while the module loads (common/ stays as a fallback for the shared
-- modules the game requires later on).
local function lazyrequire(name)
    local saved = package.path
    package.path = _dir .. "?.lua;" .. _dir .. "common/?.lua;" .. saved
    local ok, mod = pcall(lrequire, name)
    package.path = saved
    if not package.path:find(_dir .. "common/?.lua", 1, true) then
        package.path = package.path .. ";" .. _dir .. "common/?.lua"
    end
    if not ok then error(mod, 0) end
    return mod
end

local PluginBase = require("plugin_base")
local _          = require("i18n")

require("i18n").extend(lrequire("i18n_fr"))

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
    return lazyrequire("screen"):new{ plugin = self }
end

return QuickCalc
