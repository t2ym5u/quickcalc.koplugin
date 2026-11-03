local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local Blitbuffer      = require("ffi/blitbuffer")
local Button          = require("ui/widget/button")
local ConfirmBox      = require("ui/widget/confirmbox")
local Device          = require("device")
local Font            = require("ui/font")
local FrameContainer  = require("ui/widget/container/framecontainer")
local Geom            = require("ui/geometry")
local GestureRange    = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan  = require("ui/widget/horizontalspan")
local InfoMessage     = require("ui/widget/infomessage")
local InputContainer  = require("ui/widget/container/inputcontainer")
local LeftContainer   = require("ui/widget/container/leftcontainer")
local LineWidget      = require("ui/widget/linewidget")
local Menu            = require("ui/widget/menu")
local RenderText      = require("ui/rendertext")
local RightContainer  = require("ui/widget/container/rightcontainer")
local Size            = require("ui/size")
local TextBoxWidget   = require("ui/widget/textboxwidget")
local TextWidget      = require("ui/widget/textwidget")
local UIManager       = require("ui/uimanager")
local VerticalGroup   = require("ui/widget/verticalgroup")
local VerticalSpan    = require("ui/widget/verticalspan")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _               = require("i18n")

local ScreenBase = require("screen_base")
local Engine     = lrequire("calc_engine")
local Format     = lrequire("calc_format")
local Forms      = lrequire("forms")

local DeviceScreen = Device.screen

-- ---------------------------------------------------------------------------
-- Help
-- ---------------------------------------------------------------------------

local HELP_EN = _([[
Calculator — Help

Calculator
• Type the expression as you would write it: 2 + 3 × 4 gives 14 (× and ÷ before + and −). Parentheses nest; the ones left open are closed by =.
• The value appears in grey as you type; = shows it in black and adds the calculation to the history.
• After =, a digit starts a new calculation, an operator continues from the result, and √, x², 1/x… apply to the result.
• % works like on a pocket calculator: 200 + 10 % = 220 (10 % of 200 added), 200 × 10 % = 20.
• ± changes the sign of the number being typed. ⌫ erases the last key (hold it to clear everything), CE the number being typed, C everything.
• MC clears the memory, MR recalls it, M+ and M− add the current value to it or subtract it. "M" at the top of the display shows what it holds.
• Hist opens the last 20 results (kept when you close the calculator): tap one to put its value in the current calculation.

Scientific keys (f(x))
• √ square root, ∛ cube root, x², x³, xʸ (power), 1/x, eˣ, 10ˣ, n! (whole numbers up to 69), π, e.
• sin, cos, tan in degrees or radians (the DEG/RAD key switches); log is base 10, ln is natural.
• Ans recalls the last result.
• Division by zero, overflow (10¹⁰⁰ and beyond) and values outside a function's domain (√ of a negative number, tan 90°…) are reported instead of a result.

Percentages
• VAT: amount excluding or including VAT, rate (5.5, 10 and 20 % one tap away) → amount before tax, VAT, amount with VAT.
• Discount: price and discount → final price and saving.
• % change: from one value to another, in percent.
• X % of Y: also gives Y increased and decreased by X %.

Bill split & tip
Total, number of people and tip → tip, total with tip and what each person pays.

Loan & savings
• Loan: amount, annual rate and duration (years or months) → fixed monthly payment, total repaid, total interest.
• Savings: initial amount, annual rate, duration and an optional monthly deposit → final balance, total deposited, interest earned. Interest is compounded monthly and deposits are made at the end of each month.

In the forms, tap a field to type into it; ▲ and ▼ move to the previous and next field. Every value is remembered, as is the last mode used.
]])

local HELP_FR = [[
Calculatrice — Aide

Calculatrice
• Tapez l'expression comme vous l'écririez : 2 + 3 × 4 donne 14 (× et ÷ avant + et −). Les parenthèses s'imbriquent ; celles restées ouvertes sont fermées par =.
• Le résultat s'affiche en gris pendant la saisie ; = l'affiche en noir et ajoute le calcul à l'historique.
• Après =, un chiffre commence un nouveau calcul, un opérateur continue à partir du résultat, et √, x², 1/x… s'appliquent au résultat.
• % fonctionne comme sur une calculatrice de poche : 200 + 10 % = 220 (10 % de 200 ajoutés), 200 × 10 % = 20.
• ± change le signe du nombre en cours de saisie. ⌫ efface la dernière touche (appui long : tout effacer), CE le nombre en cours, C tout.
• MC efface la mémoire, MR la rappelle, M+ et M− y ajoutent ou en retirent la valeur affichée. « M » en haut de l'écran indique ce qu'elle contient.
• Hist ouvre les 20 derniers résultats (conservés à la fermeture) : touchez-en un pour reprendre sa valeur dans le calcul en cours.

Touches scientifiques (f(x))
• √ racine carrée, ∛ racine cubique, x², x³, xʸ (puissance), 1/x, eˣ, 10ˣ, n! (entiers jusqu'à 69), π, e.
• sin, cos, tan en degrés ou en radians (la touche DEG/RAD bascule) ; log est en base 10, ln est le logarithme népérien.
• Ans rappelle le dernier résultat.
• La division par zéro, le dépassement (10¹⁰⁰ et au-delà) et les valeurs hors du domaine d'une fonction (√ d'un nombre négatif, tan 90°…) sont signalés au lieu d'un résultat.

Pourcentages
• TVA : montant HT ou TTC, taux (5,5, 10 et 20 % à portée de doigt) → montant HT, TVA, montant TTC.
• Remise : prix et remise → prix final et économie.
• Évolution % : d'une valeur à une autre, en pourcentage.
• X % de Y : donne aussi Y augmenté et diminué de X %.

Addition & pourboire
Total, nombre de personnes et pourboire → pourboire, total avec pourboire et part de chacun.

Prêt & épargne
• Prêt : montant, taux annuel et durée (années ou mois) → mensualité constante, total remboursé, total des intérêts.
• Épargne : montant initial, taux annuel, durée et versement mensuel facultatif → capital final, total versé, intérêts gagnés. Les intérêts sont composés chaque mois et les versements faits en fin de mois.

Dans les formulaires, touchez un champ pour le remplir ; ▲ et ▼ passent au champ précédent et suivant. Toutes les valeurs sont mémorisées, ainsi que le dernier mode utilisé.
]]

local CALC_ERRORS = {
    div0     = _("Cannot divide by zero"),
    overflow = _("Overflow: number too large"),
    domain   = _("Undefined result"),
    syntax   = _("Incomplete expression"),
}

local FORM_ERRORS = {
    zero     = _("The initial value can't be 0."),
    people   = _("People must be a whole number, at least 1."),
    months   = _("The duration must be a whole number of months."),
    rate     = _("The rate must be above −100 %."),
    overflow = _("Overflow: number too large"),
}

-- ---------------------------------------------------------------------------
-- Slot -- a fixed-size box whose content is swapped in place. The display
-- and the form panel live in one, so a key press repaints that rectangle
-- and nothing else (the keypad does not move or flash).
-- ---------------------------------------------------------------------------

local Slot = WidgetContainer:extend{ w = 0, h = 0 }

function Slot:init()
    self.dimen = Geom:new{ x = 0, y = 0, w = self.w, h = self.h }
end

function Slot:getSize()
    return Geom:new{ w = self.w, h = self.h }
end

function Slot:paintTo(bb, x, y)
    self.dimen.x, self.dimen.y = x, y
    if self[1] then self[1]:paintTo(bb, x, y) end
end

function Slot:set(widget)
    if self[1] and self[1].free then self[1]:free() end
    self[1] = widget
end

-- A tappable row (a form field).
local TapRow = InputContainer:extend{ callback = nil }

function TapRow:init()
    self.dimen = Geom:new{ x = 0, y = 0, w = self[1]:getSize().w, h = self[1]:getSize().h }
    self.ges_events = {
        Tap = { GestureRange:new{ ges = "tap", range = function() return self.dimen end } },
    }
end

function TapRow:onTap()
    if self.callback then self.callback() end
    return true
end

-- ---------------------------------------------------------------------------
-- Text helpers
-- ---------------------------------------------------------------------------

local function textWidth(text, face, bold)
    return RenderText:sizeUtf8Text(0, DeviceScreen:getWidth() * 4, face, text, true, bold).x
end

-- The end of `text` that fits in max_w, with "…" in front when cut: the
-- expression line keeps the part being typed in view.
local function fitTail(text, face, max_w, bold)
    if textWidth(text, face, bold) <= max_w then return text end
    local chars = {}
    for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars + 1] = ch end
    local lo = 1
    while lo < #chars do
        local s = "…" .. table.concat(chars, "", lo + 1)
        if textWidth(s, face, bold) <= max_w then return s end
        lo = lo + 1
    end
    return "…"
end

-- The largest face (from size down to min) that fits text in max_w.
local function fitFace(text, name, size, min, max_w, bold)
    local face = Font:getFace(name, size)
    while size > min and textWidth(text, face, bold) > max_w do
        size = size - 2
        face = Font:getFace(name, size)
    end
    return face
end

-- ---------------------------------------------------------------------------
-- Keys
-- ---------------------------------------------------------------------------

-- Standard keypad: 5 columns. span = columns a key covers.
local STD_KEYS = {
    { { "MC" }, { "MR" }, { "M+" }, { "M-", "M−" }, { "sci", "f(x)" } },
    { { "C" }, { "CE" }, { "(" }, { ")" }, { "back", "⌫" } },
    { { "7" }, { "8" }, { "9" }, { "%" }, { "/", "÷" } },
    { { "4" }, { "5" }, { "6" }, { "neg", "±" }, { "*", "×" } },
    { { "1" }, { "2" }, { "3" }, { "hist" }, { "-", "−" } },
    { { "0", span = 2 }, { "." }, { "=" }, { "+" } },
}

-- Scientific keys, in reading order: 6 per row in portrait, 3 in landscape.
local SCI_KEYS = {
    { "sin(", "sin" }, { "cos(", "cos" }, { "tan(", "tan" },
    { "pi", "π" }, { "e", "e" }, { "angle" },
    { "log(", "log" }, { "ln(", "ln" }, { "!", "n!" },
    { "sqrt(", "√" }, { "cbrt(", "∛" }, { "inv", "1/x" },
    { "sq", "x²" }, { "cube", "x³" }, { "^", "xʸ" },
    { "exp", "eˣ" }, { "pow10", "10ˣ" }, { "ans", "Ans" },
}

-- Form keypad: 4 columns.
local FORM_KEYS = {
    { { "7" }, { "8" }, { "9" }, { "back", "⌫" } },
    { { "4" }, { "5" }, { "6" }, { "C" } },
    { { "1" }, { "2" }, { "3" }, { "prev", "▲" } },
    { { "0" }, { "." }, { "neg", "±" }, { "next", "▼" } },
}

-- Operator glyphs are small in the UI font; these keys get a bigger size.
local BIG_SYMBOLS = { ["+"] = 1, ["-"] = 1, ["*"] = 1, ["/"] = 1, ["="] = 1,
                      back = 1, neg = 1, ["%"] = 1, prev = 1, next = 1 }

local DIGIT_KEYS = { ["0"] = 1, ["1"] = 1, ["2"] = 1, ["3"] = 1, ["4"] = 1,
                     ["5"] = 1, ["6"] = 1, ["7"] = 1, ["8"] = 1, ["9"] = 1 }

-- ---------------------------------------------------------------------------
-- CalcScreen
-- ---------------------------------------------------------------------------

local CalcScreen = ScreenBase:extend{
    vertical_align = "top",
}

function CalcScreen:init()
    local saved = self.plugin:loadState() or {}
    if type(saved) ~= "table" then saved = {} end
    self.lang   = _.lang()
    self.mode   = Forms.mode(saved.mode) and saved.mode or "calc"
    self.sci    = saved.sci and true or false
    self.engine = Engine.new(saved.calc)
    self.subs   = {}
    for _i, m in ipairs(Forms.MODES) do
        local s = type(saved.subs) == "table" and saved.subs[m.id]
        self.subs[m.id] = Forms.FORMS[s or ""] and s or m.subs[1]
    end
    self.forms = {}
    for id in pairs(Forms.FORMS) do
        self.forms[id] = Forms.loadState(id, type(saved.forms) == "table" and saved.forms[id])
    end
    ScreenBase.init(self)
end

function CalcScreen:serializeState()
    local forms = {}
    for id, st in pairs(self.forms) do forms[id] = st end
    return {
        mode  = self.mode,
        sci   = self.sci,
        calc  = self.engine:serialize(),
        subs  = self.subs,
        forms = forms,
    }
end

function CalcScreen:save()
    self.plugin:saveState(self:serializeState())
end

-- ---------------------------------------------------------------------------
-- Layout
-- ---------------------------------------------------------------------------

function CalcScreen:modeTitle()
    if self.mode == "calc" then return _("Calculator") end
    return _(Forms.mode(self.mode).title)
end

function CalcScreen:menuItems()
    local items = {
        { text = _("Calculator"), callback = function() self:setMode("calc") end },
    }
    for _i, m in ipairs(Forms.MODES) do
        items[#items + 1] = { text = _(m.title), callback = function() self:setMode(m.id) end }
    end
    items[#items + 1] = { text = _("History"), callback = function() self:showHistory() end }
    if self.mode == "calc" then
        items[#items + 1] = {
            text = self.sci and _("Hide scientific keys") or _("Show scientific keys"),
            callback = function() self:toggleSci() end,
        }
    end
    items[#items + 1] = { text = _("Help"), callback = function()
        self:showRules((_.lang() == "fr" and HELP_FR) or HELP_EN, { title = _("Help") })
    end }
    return items
end

function CalcScreen:buildLayout()
    self.title_bar = self:buildTitleBar(self:modeTitle(), function() return self:menuItems() end)
    self.g   = self:getGutter()
    self.gap = math.max(2, math.floor(DeviceScreen:scaleBySize(4)))
    local body
    if self.mode == "calc" then
        body = self:buildCalcBody()
    else
        body = self:buildFormBody()
    end
    self.layout = VerticalGroup:new{
        align = "center",
        self.title_bar,
        VerticalSpan:new{ width = self.g },
        body,
    }
    self[1] = self.layout
end

function CalcScreen:bodyHeight()
    return self.dimen.h - self.title_bar:getSize().h - 2 * self.g
end

-- Rotating the reader: lay everything out again for the new shape.
function CalcScreen:onScreenResize(dimen)
    self.dimen = Geom:new{ x = 0, y = 0,
        w = dimen and dimen.w or DeviceScreen:getWidth(),
        h = dimen and dimen.h or DeviceScreen:getHeight() }
    self:redraw()
end

function CalcScreen:redraw()
    self:buildLayout()
    UIManager:setDirty(self, function() return "ui", self.dimen end)
end

-- A grid of keys. rows: lists of { id, label, span = n }; cols: columns of
-- the grid; returns the widget.
function CalcScreen:buildKeys(rows, cols, width, row_h, on_key, font_size)
    local gap = self.gap
    local cell = (width - (cols - 1) * gap) / cols
    local group = VerticalGroup:new{ align = "left" }
    for ri, row in ipairs(rows) do
        local hg = HorizontalGroup:new{ align = "center" }
        local col, prev_x1 = 0, 0
        for _ci, key in ipairs(row) do
            local span = key.span or 1
            -- Key edges are rounded on the grid, not key by key, so every
            -- row is exactly `width` wide and the columns line up.
            local x0 = math.floor(col * (cell + gap) + 0.5)
            local x1 = math.floor((col + span) * (cell + gap) - gap + 0.5)
            col = col + span
            if x0 > prev_x1 then hg[#hg + 1] = HorizontalSpan:new{ width = x0 - prev_x1 } end
            prev_x1 = x1
            local id = key[1]
            local label = key[2] or self:keyLabel(id)
            local size = font_size
            if DIGIT_KEYS[id] or id == "." then size = math.floor(font_size * 1.25) end
            if BIG_SYMBOLS[id] then size = math.floor(font_size * 1.45) end
            hg[#hg + 1] = Button:new{
                text           = label,
                width          = x1 - x0,
                -- Button's height excludes its border.
                height         = row_h - 2 * Size.border.button,
                background     = id == "=" and Blitbuffer.COLOR_LIGHT_GRAY or nil,
                padding        = 0,
                bordersize     = Size.border.button,
                radius         = Size.radius.button,
                text_font_face = "cfont",
                text_font_size = size,
                text_font_bold = id ~= "hist",
                callback       = function() on_key(id) end,
                hold_callback  = id == "back" and function() on_key("C") end or nil,
            }
        end
        if ri > 1 then group[#group + 1] = VerticalSpan:new{ width = gap } end
        group[#group + 1] = hg
    end
    return group
end

function CalcScreen:keyLabel(id)
    if id == "." then return Format.decimalSep(self.lang) end
    if id == "angle" then return self.engine.angle == "deg" and "DEG" or "RAD" end
    if id == "hist" then return _("Hist") end
    return id
end

function CalcScreen:keysHeight(rows, row_h)
    return rows * row_h + (rows - 1) * self.gap
end

-- ---------------------------------------------------------------------------
-- Calculator
-- ---------------------------------------------------------------------------

function CalcScreen:buildCalcBody()
    local sw = self.dimen.w
    local g, gap = self.g, self.gap
    local W = sw - 2 * g
    local H = self:bodyHeight()
    local land = self:isLandscape()
    local short = math.min(self.dimen.w, self.dimen.h)

    local sci_rows
    if self.sci then
        sci_rows = {}
        local per = land and 3 or 6
        for i = 1, #SCI_KEYS, per do
            local row = {}
            for j = i, math.min(i + per - 1, #SCI_KEYS) do row[#row + 1] = SCI_KEYS[j] end
            sci_rows[#sci_rows + 1] = row
        end
    end

    -- Rows stacked under the display: in portrait the scientific rows sit on
    -- top of the standard ones; in landscape they are a panel beside them.
    local stacked = #STD_KEYS + ((self.sci and not land) and #sci_rows or 0)
    -- Big result digits when there is room for them.
    self.big_size = (self.sci or land) and 36 or 48
    local min_display = self:displayNeed()
    local max_row = math.floor(short * (land and 0.12 or 0.13))
    local row_h = math.floor((H - min_display - g - (stacked - 1) * gap) / stacked)
    row_h = math.min(row_h, max_row)
    local keys_h = self:keysHeight(stacked, row_h)
    local display_h = H - keys_h - g
    -- A display taller than this is just white space.
    display_h = math.min(display_h, math.floor(short * 0.42))

    self.display_slot = Slot:new{ w = W, h = display_h }
    self.display_w = W
    self:fillDisplay()

    local font = land and 20 or 22
    local function onKey(id) self:onCalcKey(id) end
    local keys
    if self.sci and land then
        local sci_w = math.floor((W - g) * 3 / 8)
        local std_w = W - g - sci_w
        local sci_row_h = math.floor((keys_h - (#sci_rows - 1) * gap) / #sci_rows)
        keys = HorizontalGroup:new{
            align = "top",
            self:buildKeys(sci_rows, 3, sci_w, sci_row_h, onKey, 18),
            HorizontalSpan:new{ width = g },
            self:buildKeys(STD_KEYS, 5, std_w, row_h, onKey, font),
        }
    elseif self.sci then
        keys = VerticalGroup:new{
            align = "left",
            self:buildKeys(sci_rows, 6, W, row_h, onKey, 18),
            VerticalSpan:new{ width = gap },
            self:buildKeys(STD_KEYS, 5, W, row_h, onKey, font),
        }
    else
        keys = self:buildKeys(STD_KEYS, 5, W, row_h, onKey, font)
    end

    return VerticalGroup:new{
        align = "left",
        self.display_slot,
        VerticalSpan:new{ width = g },
        keys,
    }
end

local function lineHeight(face, bold)
    local w = TextWidget:new{ text = "0", face = face, bold = bold }
    local h = w:getSize().h
    w:free()
    return h
end

-- Height the display needs for its three lines at full size.
function CalcScreen:displayNeed()
    return lineHeight(Font:getFace("smallinfofont", 16), true)
         + lineHeight(Font:getFace("cfont", 26))
         + lineHeight(Font:getFace("cfont", self.big_size), true)
         + 2 * Size.padding.large + 2 * Size.border.thin + Size.padding.small
end

function CalcScreen:fillDisplay()
    local e = self.engine
    local W, H = self.display_slot.w, self.display_slot.h
    local pad = Size.padding.large
    local inner = W - 2 * pad - 2 * Size.border.thin
    local big = self.big_size or 40

    local expr, res, res_color, res_bold = "", "", Blitbuffer.COLOR_BLACK, true
    local is_msg = false
    if e.evaluated then
        expr = Format.expression(e.tokens, self.lang) .. " ="
        res = Format.number(e.result, self.lang)
    else
        expr = Format.expression(e.tokens, self.lang)
        if e.error then
            res = CALC_ERRORS[e.error] or CALC_ERRORS.syntax
            is_msg = true
        else
            local p = e:preview()
            if p then
                res = Format.number(p, self.lang)
                res_color = Blitbuffer.Color8(0x55)
                res_bold = false
            elseif #e.tokens == 0 then
                res = "0"
                res_color = Blitbuffer.Color8(0x55)
            end
        end
    end

    local info_face = Font:getFace("smallinfofont", 16)
    local expr_face = fitFace(expr, "cfont", 26, 20, inner)
    local res_face = is_msg and fitFace(res, "cfont", 28, 14, inner, true)
                     or fitFace(res, "cfont", big, 18, inner, res_bold)

    -- Top line: memory on the left, angle unit on the right.
    local mem = e.memory and ("M = " .. Format.number(e.memory, self.lang)) or ""
    local unit = self.sci and (e.angle == "deg" and _("Degrees") or _("Radians")) or ""
    local info_left = TextWidget:new{ text = mem, face = info_face, bold = true,
                                      max_width = math.floor(inner * 0.65) }
    local info_right = TextWidget:new{ text = unit, face = info_face }
    local info_h = info_left:getSize().h
    local info = HorizontalGroup:new{
        LeftContainer:new{ dimen = Geom:new{ w = inner - info_right:getSize().w, h = info_h }, info_left },
        info_right,
    }

    local expr_w = TextWidget:new{
        text = fitTail(expr, expr_face, inner),
        face = expr_face,
    }
    local res_w = TextWidget:new{
        text = is_msg and res or fitTail(res, res_face, inner, res_bold),
        face = res_face,
        bold = res_bold,
        fgcolor = res_color,
    }
    local lines_h = info_h + expr_w:getSize().h + res_w:getSize().h
    local inner_h = H - 2 * pad - 2 * Size.border.thin
    local spare = math.max(0, inner_h - lines_h)

    local content = VerticalGroup:new{
        align = "right",
        info,
        VerticalSpan:new{ width = math.floor(spare * 0.6) },
        RightContainer:new{ dimen = Geom:new{ w = inner, h = expr_w:getSize().h }, expr_w },
        VerticalSpan:new{ width = spare - math.floor(spare * 0.6) },
        RightContainer:new{ dimen = Geom:new{ w = inner, h = res_w:getSize().h }, res_w },
    }
    self.display_slot:set(FrameContainer:new{
        width      = W,
        height     = H,
        bordersize = Size.border.thin,
        radius     = Size.radius.window,
        padding    = pad,
        background = Blitbuffer.COLOR_WHITE,
        content,
    })
end

function CalcScreen:refreshDisplay()
    self:fillDisplay()
    local slot = self.display_slot
    UIManager:setDirty(self, function() return "ui", slot.dimen end)
end

function CalcScreen:onCalcKey(id)
    if id == "sci" then return self:toggleSci() end
    if id == "hist" then return self:showHistory() end
    local e = self.engine
    local had_history = #e.history > 0 and e.history[1]
    e:press(id)
    if id == "angle" then
        -- The key's own label changes: rebuild (rare key, full layout).
        return self:redraw()
    end
    self:refreshDisplay()
    -- A new history line is worth keeping even if the reader is switched off.
    if e.history[1] ~= had_history or id:sub(1, 1) == "M" then self:save() end
end

function CalcScreen:toggleSci()
    self.sci = not self.sci
    self:save()
    self:redraw()
end

-- ---------------------------------------------------------------------------
-- History
-- ---------------------------------------------------------------------------

function CalcScreen:showHistory()
    local e = self.engine
    if #e.history == 0 then
        UIManager:show(InfoMessage:new{ text = _("No calculations yet."), timeout = 2 })
        return
    end
    local menu
    local items = {}
    for i, h in ipairs(e.history) do
        items[#items + 1] = {
            text      = Format.expression(h.tokens, self.lang) .. " =",
            mandatory = Format.number(h.value, self.lang),
            bold      = i == 1,
            index     = i,
        }
    end
    items[#items + 1] = { text = _("Clear history"), clear = true, separator = true }
    menu = Menu:new{
        title      = _("History"),
        subtitle   = _("Tap a result to reuse it."),
        item_table = items,
        width      = DeviceScreen:getWidth(),
        height     = DeviceScreen:getHeight(),
        is_borderless = true,
        is_popout  = false,
        covers_fullscreen = true,
    }
    menu.onMenuChoice = function(_m, item)
        if item.clear then
            UIManager:show(ConfirmBox:new{
                text = _("Clear the history?"),
                ok_text = _("Clear"),
                ok_callback = function()
                    e:clearHistory()
                    self:save()
                    UIManager:close(menu)
                end,
            })
            return
        end
        UIManager:close(menu)
        e:useHistory(item.index)
        if self.mode ~= "calc" then
            self.mode = "calc"
            self:save()
            self:redraw()
        else
            self:refreshDisplay()
        end
    end
    UIManager:show(menu)
end

-- ---------------------------------------------------------------------------
-- Forms
-- ---------------------------------------------------------------------------

function CalcScreen:setMode(mode)
    if mode == self.mode then return end
    self.mode = mode
    self:save()
    self:redraw()
end

function CalcScreen:formId()
    return self.subs[self.mode]
end

function CalcScreen:buildFormBody()
    local sw = self.dimen.w
    local g, gap = self.g, self.gap
    local W = sw - 2 * g
    local H = self:bodyHeight()
    local land = self:isLandscape()
    local short = math.min(self.dimen.w, self.dimen.h)
    local max_row = math.floor(short * 0.13)

    local panel_w, keys_w = W, W
    if land then
        keys_w = math.floor((W - g) * 0.40)
        panel_w = W - g - keys_w
    end
    self.panel_w = panel_w
    -- Measure what the form needs, then hand the rest to the keypad.
    local probe = self:buildPanel(panel_w)
    local need = probe:getSize().h
    probe:free()

    local row_h, panel_h
    if land then
        panel_h = H
        -- Beside the form the keypad has the full height to itself.
        row_h = math.min(math.floor(short * 0.19), math.floor((H - 3 * gap) / 4))
    else
        row_h = math.floor((H - need - g - 3 * gap) / 4)
        row_h = math.max(math.floor(short * 0.085), math.min(max_row, row_h))
        panel_h = H - g - self:keysHeight(4, row_h)
    end
    self.panel_slot = Slot:new{ w = panel_w, h = panel_h }
    self:fillPanel()

    local keys = self:buildKeys(FORM_KEYS, 4, keys_w, row_h,
        function(id) self:onFormKey(id) end, land and 20 or 22)
    if land then
        local kh = self:keysHeight(4, row_h)
        return HorizontalGroup:new{
            align = "top",
            self.panel_slot,
            HorizontalSpan:new{ width = g },
            VerticalGroup:new{
                VerticalSpan:new{ width = math.max(0, H - kh) },
                keys,
            },
        }
    end
    return VerticalGroup:new{
        align = "left",
        self.panel_slot,
        VerticalSpan:new{ width = g },
        keys,
    }
end

-- A row of toggle buttons; choices = { { value, label }, ... }.
function CalcScreen:toggleRow(choices, current, width, height, on_pick, font_size, raw)
    local gap = self.gap
    local n = #choices
    local w = math.floor((width - (n - 1) * gap) / n)
    local hg = HorizontalGroup:new{}
    for i, c in ipairs(choices) do
        local selected = c[1] == current
        if i > 1 then hg[#hg + 1] = HorizontalSpan:new{ width = gap } end
        hg[#hg + 1] = Button:new{
            text           = raw and c[2] or _(c[2]),
            width          = i == n and (width - (n - 1) * (w + gap)) or w,
            height         = height - 2 * (selected and Size.border.thick or Size.border.thin),
            padding        = 0,
            bordersize     = selected and Size.border.thick or Size.border.thin,
            radius         = Size.radius.button,
            background     = selected and Blitbuffer.COLOR_LIGHT_GRAY or nil,
            text_font_face = "cfont",
            text_font_size = font_size or 18,
            text_font_bold = selected,
            callback       = function() on_pick(c[1]) end,
        }
    end
    return hg
end

function CalcScreen:fieldText(field, text)
    if text == "" then return "" end
    return Format.localise(text, self.lang)
end

function CalcScreen:resultText(row)
    if row.value == nil then return "—" end
    local v, lang = row.value, self.lang
    local pct = self.lang == "fr" and "\u{202F}%" or "%"
    if row.kind == "money" then return Format.money(v, lang) end
    if row.kind == "percent" then return Format.number(v, lang, 2) .. pct end
    if row.kind == "signed_percent" then
        return (v > 0 and "+" or "") .. Format.number(v, lang, 2) .. pct
    end
    if row.kind == "signed" then
        return (v > 0 and "+" or "") .. Format.number(v, lang)
    end
    return Format.number(v, lang)
end

function CalcScreen:buildPanel(width)
    local form_id = self:formId()
    local form = Forms.FORMS[form_id]
    local st = self.forms[form_id]
    local mode = Forms.mode(self.mode)
    local short = math.min(self.dimen.w, self.dimen.h)
    local gap, g = self.gap, self.g
    local btn_h = math.floor(short * 0.072)
    local field_h = math.floor(short * 0.086)

    local vg = VerticalGroup:new{ align = "left" }
    local function add(w, space)
        if #vg > 0 then vg[#vg + 1] = VerticalSpan:new{ width = space or g } end
        vg[#vg + 1] = w
    end

    if #mode.subs > 1 then
        local choices = {}
        for i, s in ipairs(mode.subs) do choices[i] = { s, Forms.FORMS[s].tab } end
        add(self:toggleRow(choices, form_id, width, btn_h, function(s)
            if s == self.subs[self.mode] then return end
            self.subs[self.mode] = s
            self:save()
            self:redraw()
        end, 17))
    end
    if form.option then
        add(self:toggleRow(form.option.choices, st.opts[form.option.id], width, btn_h,
            function(v)
                st.opts[form.option.id] = v
                self:refreshPanel()
            end, 17))
    end

    local label_face = Font:getFace("cfont", 17)
    local value_face = Font:getFace("cfont", 22)
    local label_w = math.floor(width * 0.36)
    local extra_w = math.floor(width * 0.12)
    for i, f in ipairs(form.fields) do
        local active = st.active == i
        local extras = {}
        if f.units then
            local opt = f.units[1]
            for j = 2, #f.units do
                local u = f.units[j]
                extras[#extras + 1] = { _(u[2]), function()
                    st.opts[opt] = u[1]
                    self:refreshPanel()
                end, st.opts[opt] == u[1], 1.6 }
            end
        end
        local ex_total = 0
        for _j, ex in ipairs(extras) do ex_total = ex_total + math.floor(extra_w * (ex[4] or 1)) + gap end
        local box_w = width - label_w - gap - ex_total

        local label = TextBoxWidget:new{
            text  = _(Forms.fieldLabel(f, st.opts)),
            face  = label_face,
            width = label_w,
            bold  = active,
            height = field_h,
            height_adjust = true,
            height_overflow_show_ellipsis = true,
        }
        local text = self:fieldText(f, st.values[f.id])
        local bw = active and Size.border.thick * 2 or Size.border.thin
        local pad = Size.padding.default
        local inner_w = box_w - 2 * bw - 2 * pad
        local value = TextWidget:new{
            text = fitTail(text .. (active and "▏" or ""), value_face, inner_w, true),
            face = value_face,
            bold = true,
        }
        local box = FrameContainer:new{
            bordersize = bw,
            padding    = 0,
            padding_left = pad, padding_right = pad,
            -- No rounded corners: a thick rounded border leaves notches.
            background = Blitbuffer.COLOR_WHITE,
            RightContainer:new{ dimen = Geom:new{ w = inner_w, h = field_h - 2 * bw }, value },
        }
        -- The label and the box are one tap target; the extras keep theirs.
        local full = HorizontalGroup:new{
            align = "center",
            TapRow:new{
                callback = function()
                    st.active = i
                    self:refreshPanel()
                end,
                HorizontalGroup:new{
                    align = "center",
                    LeftContainer:new{ dimen = Geom:new{ w = label_w, h = field_h }, label },
                    HorizontalSpan:new{ width = gap },
                    box,
                },
            },
        }
        for _j, ex in ipairs(extras) do
            full[#full + 1] = HorizontalSpan:new{ width = gap }
            full[#full + 1] = Button:new{
                text           = ex[1],
                width          = math.floor(extra_w * (ex[4] or 1)),
                height         = math.floor(field_h * 0.8) - 2 * (ex[3] and Size.border.thick or Size.border.thin),
                padding        = 0,
                bordersize     = ex[3] and Size.border.thick or Size.border.thin,
                background     = ex[3] and Blitbuffer.COLOR_LIGHT_GRAY or nil,
                radius         = Size.radius.button,
                text_font_face = "cfont",
                text_font_size = 16,
                text_font_bold = ex[3],
                callback       = ex[2],
            }
        end
        add(full, gap * 2)
        -- Presets go on a line of their own under the box: beside it they
        -- left no room for the value.
        if f.presets then
            local choices = {}
            for j, p in ipairs(f.presets) do choices[j] = { p, Format.localise(p, self.lang) } end
            add(HorizontalGroup:new{
                HorizontalSpan:new{ width = label_w + gap },
                self:toggleRow(choices, st.values[f.id], width - label_w - gap,
                    math.floor(field_h * 0.72), function(p)
                        st.values[f.id] = p
                        st.active = i
                        self:refreshPanel()
                    end, 16, true),
            }, gap)
        end
    end

    -- Results
    local rows, err = Forms.compute(form_id, st)
    add(LineWidget:new{ dimen = Geom:new{ w = width, h = Size.line.thick } }, g)
    local res_label_face = Font:getFace("cfont", 18)
    local res_face = Font:getFace("cfont", 22)
    for _j, r in ipairs(rows) do
        local val = TextWidget:new{ text = self:resultText(r), face = res_face, bold = true }
        local lab = TextWidget:new{
            text = _(r.label), face = res_label_face,
            max_width = width - val:getSize().w - g,
        }
        local h = math.max(lab:getSize().h, val:getSize().h)
        add(HorizontalGroup:new{
            align = "center",
            LeftContainer:new{ dimen = Geom:new{ w = width - val:getSize().w, h = h }, lab },
            val,
        }, gap)
    end
    if err then
        add(TextBoxWidget:new{
            text = FORM_ERRORS[err] or FORM_ERRORS.overflow,
            face = Font:getFace("cfont", 17),
            width = width,
            bold = true,
        }, gap)
    end
    return vg
end

function CalcScreen:fillPanel()
    self.panel_slot:set(self:buildPanel(self.panel_slot.w))
end

function CalcScreen:refreshPanel()
    self:fillPanel()
    local slot = self.panel_slot
    UIManager:setDirty(self, function() return "ui", slot.dimen end)
end

function CalcScreen:onFormKey(id)
    local form_id = self:formId()
    local form = Forms.FORMS[form_id]
    local st = self.forms[form_id]
    local n = #form.fields
    if id == "prev" then
        st.active = st.active > 1 and st.active - 1 or n
    elseif id == "next" then
        st.active = st.active < n and st.active + 1 or 1
    else
        local f = form.fields[st.active]
        st.values[f.id] = Forms.edit(st.values[f.id], id, f.integer)
    end
    self:refreshPanel()
end

return CalcScreen
