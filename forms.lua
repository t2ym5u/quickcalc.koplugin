-- forms.lua -- the fill-in modes (Percentages, Bill split & tip, Loan &
-- savings): which fields each form has, how a field is typed on the
-- keypad, and what the form computes. Pure Lua; labels are English source
-- strings that the screen passes through _().

local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local Finance = lrequire("finance")

local unpack = table.unpack or unpack

local Forms = {}

-- Title-bar menu order. Each mode is one or more forms, picked by tabs.
Forms.MODES = {
    { id = "percent", title = "Percentages",      subs = { "vat", "discount", "change", "pctof" } },
    { id = "split",   title = "Bill split & tip", subs = { "split" } },
    { id = "loan",    title = "Loan & savings",   subs = { "loan", "savings" } },
}

function Forms.mode(id)
    for _i, m in ipairs(Forms.MODES) do
        if m.id == id then return m end
    end
end

-- Field spec:
--   id, label            label may also be a table keyed by an option value
--   default              initial text ("" when absent)
--   presets              list of values offered as buttons beside the field
--   integer              only whole numbers can be typed
--   units                { option id, { value, label }, ... } toggle beside
--                        the field (the duration's years/months)
-- Form spec:
--   tab, fields, option ({ id, default, choices = { { value, label } } }),
--   compute(values, opts) -> rows | nil, error code
-- Rows: { label =, value = number or nil, kind = "money" | "percent" |
--         "signed_percent" | "number" | "signed" }

local function num(values, id) return values[id] end

local function rows(spec, ...)
    local vals = { ... }
    local out = {}
    for i, r in ipairs(spec) do
        out[i] = { label = r[1], kind = r[2], value = vals[i] }
    end
    return out
end

Forms.FORMS = {
    vat = {
        tab = "VAT",
        option = { id = "dir", default = "ht2ttc", choices = {
            { "ht2ttc", "Excl. → incl. VAT" },
            { "ttc2ht", "Incl. → excl. VAT" },
        } },
        fields = {
            { id = "amount", label = { ht2ttc = "Amount excl. VAT", ttc2ht = "Amount incl. VAT" } },
            { id = "rate", label = "VAT rate (%)", default = "20", presets = { "5.5", "10", "20" } },
        },
        results = { { "Excl. VAT", "money" }, { "VAT", "money" }, { "Incl. VAT", "money" } },
        compute = function(v, o)
            local a, r = num(v, "amount"), num(v, "rate")
            if not (a and r) then return nil end
            return Finance.vat(a, r, o.dir)
        end,
    },
    discount = {
        tab = "Discount",
        fields = {
            { id = "price", label = "Price" },
            { id = "pct", label = "Discount (%)", presets = { "10", "20", "30", "50" } },
        },
        results = { { "Final price", "money" }, { "Saving", "money" } },
        compute = function(v)
            local p, d = num(v, "price"), num(v, "pct")
            if not (p and d) then return nil end
            return Finance.discount(p, d)
        end,
    },
    change = {
        tab = "% change",
        fields = {
            { id = "from", label = "Initial value" },
            { id = "to", label = "Final value" },
        },
        results = { { "Change", "signed_percent" }, { "Difference", "signed" } },
        compute = function(v)
            local a, b = num(v, "from"), num(v, "to")
            if not (a and b) then return nil end
            return Finance.change(a, b)
        end,
    },
    pctof = {
        tab = "X % of Y",
        fields = {
            { id = "x", label = "Percentage X (%)" },
            { id = "y", label = "Value Y" },
        },
        results = { { "X % of Y", "number" }, { "Y + X %", "number" }, { "Y − X %", "number" } },
        compute = function(v)
            local x, y = num(v, "x"), num(v, "y")
            if not (x and y) then return nil end
            local p = Finance.percentOf(x, y)
            return p, y + p, y - p
        end,
    },
    split = {
        tab = "Bill split & tip",
        fields = {
            { id = "total", label = "Bill total" },
            { id = "people", label = "People", default = "2", integer = true },
            { id = "tip", label = "Tip (%)", default = "0", presets = { "0", "5", "10", "15" } },
        },
        results = { { "Tip", "money" }, { "Total with tip", "money" }, { "Per person", "money" } },
        compute = function(v)
            local t, n = num(v, "total"), num(v, "people")
            if not (t and n) then return nil end
            return Finance.split(t, n, num(v, "tip") or 0)
        end,
    },
    loan = {
        tab = "Loan",
        fields = {
            { id = "amount", label = "Amount borrowed" },
            { id = "rate", label = "Annual rate (%)" },
            { id = "duration", label = "Duration",
              units = { "unit", { "years", "years" }, { "months", "months" } } },
        },
        defaults_opts = { unit = "years" },
        results = { { "Monthly payment", "money" }, { "Total repaid", "money" },
                    { "Total interest", "money" } },
        compute = function(v, o)
            local p, r, d = num(v, "amount"), num(v, "rate"), num(v, "duration")
            if not (p and r and d) then return nil end
            return Finance.loan(p, r, Finance.months(d, o.unit))
        end,
    },
    savings = {
        tab = "Savings",
        fields = {
            { id = "initial", label = "Initial amount" },
            { id = "rate", label = "Annual rate (%)" },
            { id = "duration", label = "Duration",
              units = { "unit", { "years", "years" }, { "months", "months" } } },
            { id = "deposit", label = "Monthly deposit" },
        },
        defaults_opts = { unit = "years" },
        results = { { "Final balance", "money" }, { "Total deposited", "money" },
                    { "Interest earned", "money" } },
        compute = function(v, o)
            local p, r, d = num(v, "initial"), num(v, "rate"), num(v, "duration")
            local dep = num(v, "deposit")
            if not (r and d) or not (p or dep) then return nil end
            return Finance.savings(p or 0, r, Finance.months(d, o.unit), dep or 0)
        end,
    },
}

-- The label of a field under the form's current options.
function Forms.fieldLabel(field, opts)
    if type(field.label) == "table" then
        for _k, v in pairs(opts or {}) do
            if field.label[v] then return field.label[v] end
        end
        local _k, first = next(field.label)
        return first
    end
    return field.label
end

-- A fresh form state: { values = { id = text }, opts = {...}, active = 1 }.
function Forms.newState(form_id)
    local form = Forms.FORMS[form_id]
    local st = { values = {}, opts = {}, active = 1 }
    for _i, f in ipairs(form.fields) do st.values[f.id] = f.default or "" end
    if form.option then st.opts[form.option.id] = form.option.default end
    for k, v in pairs(form.defaults_opts or {}) do st.opts[k] = v end
    return st
end

-- A saved state, checked field by field against the form (a field that a
-- newer version added gets its default; garbage is dropped).
function Forms.loadState(form_id, saved)
    local st = Forms.newState(form_id)
    if type(saved) ~= "table" then return st end
    local form = Forms.FORMS[form_id]
    for _i, f in ipairs(form.fields) do
        local s = type(saved.values) == "table" and saved.values[f.id]
        if type(s) == "string" and #s <= 16 and s:match("^%-?%d*%.?%d*$") then
            st.values[f.id] = s
        end
    end
    if type(saved.opts) == "table" then
        for k, _v in pairs(st.opts) do
            if type(saved.opts[k]) == "string" then st.opts[k] = saved.opts[k] end
        end
    end
    local a = tonumber(saved.active)
    if a and a >= 1 and a <= #form.fields then st.active = math.floor(a) end
    return st
end

Forms.MAX_LEN = 12

-- Typing into a field: text -> new text. Keys "0".."9", ".", "neg" (±),
-- "back", "C". integer fields refuse the decimal point.
function Forms.edit(text, key, integer)
    text = text or ""
    if key == "C" then return "" end
    if key == "back" then return text:sub(1, -2) end
    if key == "neg" then
        if text:sub(1, 1) == "-" then return text:sub(2) end
        return "-" .. text
    end
    local digits = #text:gsub("[^%d]", "")
    if key == "." then
        if integer or text:find(".", 1, true) then return text end
        if text == "" or text == "-" then return text .. "0." end
        return text .. "."
    end
    if key:match("^%d$") then
        if digits >= Forms.MAX_LEN then return text end
        if text == "0" then return key end
        if text == "-0" then return "-" .. key end
        return text .. key
    end
    return text
end

-- Field text -> number, or nil while empty or unfinished ("-").
function Forms.parse(text)
    if type(text) ~= "string" or text == "" or text == "-" or text == "." or text == "-." then
        return nil
    end
    return tonumber(text)
end

-- Evaluate a form: returns rows (value nil where nothing can be computed
-- yet), and an error code when the input can't give a result.
function Forms.compute(form_id, st)
    local form = Forms.FORMS[form_id]
    local values = {}
    for _i, f in ipairs(form.fields) do values[f.id] = Forms.parse(st.values[f.id]) end
    local res = { form.compute(values, st.opts) }
    local err
    if res[1] == nil and type(res[2]) == "string" then
        err = res[2]
        res = {}
    end
    for i = 1, #form.results do
        local v = res[i]
        if v ~= nil and (v ~= v or v == math.huge or v == -math.huge) then
            err = "overflow"
            res = {}
            break
        end
    end
    return rows(form.results, unpack(res, 1, #form.results)), err
end

return Forms
