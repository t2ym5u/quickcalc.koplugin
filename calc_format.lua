-- calc_format.lua -- numbers and expressions as the reader sees them.
--
-- Values are computed with "." as the decimal point; only what is shown
-- follows the UI language: "1 234,5" in French, "1,234.5" in English.
-- Pure Lua, no KOReader: the language code is passed in.

local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local Parser = lrequire("calc_parser")

local Format = {}

-- Languages writing a decimal comma, and the thousands separator each uses.
-- Everything else gets "." and ",".
local NNBSP = "\u{202F}" -- narrow no-break space, the French thousands separator
local COMMA_LANGS = {
    fr = NNBSP, de = ".", es = ".", it = ".", pt = ".", nl = ".", ru = NNBSP,
    pl = NNBSP, cs = NNBSP, sk = NNBSP, uk = NNBSP, sv = NNBSP, nb = NNBSP,
    fi = NNBSP, da = ".", tr = ".", ro = ".", hu = NNBSP, el = ".", ca = ".",
    bg = NNBSP, hr = ".", sl = ".", sr = ".", lt = NNBSP, lv = NNBSP, et = NNBSP,
}

function Format.decimalSep(lang)
    return COMMA_LANGS[lang] and "," or "."
end

function Format.groupSep(lang)
    return COMMA_LANGS[lang] or ","
end

-- Significant digits shown for a result.
Format.DIGITS = 12

local SUPER = {
    ["0"] = "⁰", ["1"] = "¹", ["2"] = "²", ["3"] = "³", ["4"] = "⁴",
    ["5"] = "⁵", ["6"] = "⁶", ["7"] = "⁷", ["8"] = "⁸", ["9"] = "⁹", ["-"] = "⁻",
}

local function group(int, sep)
    local out = int
    while true do
        local repl, k = out:gsub("^(%d+)(%d%d%d)", "%1" .. sep:gsub("%%", "%%%%") .. "%2")
        out = repl
        if k == 0 then break end
    end
    return out
end

-- "1234.50" -> localised, digits grouped by three in the integer part.
-- The string is assumed to be a plain decimal, optionally signed.
function Format.localise(s, lang)
    local sign, int, frac = s:match("^([%-]?)(%d*)%.?(%d*)$")
    if not int then return s end
    local has_point = s:find(".", 1, true) ~= nil
    local out = group(int, Format.groupSep(lang))
    if has_point then out = out .. Format.decimalSep(lang) .. frac end
    return (sign == "-" and "−" or "") .. out
end

local function stripZeros(s)
    if s:find(".", 1, true) then
        s = s:gsub("0+$", ""):gsub("%.$", "")
    end
    return s
end

-- Digits before the point (0 for 0.xxx, whose leading 0 is not significant).
local function intDigits(a)
    if a < 1 then return 0 end
    return #string.format("%.0f", math.floor(a))
end

-- A result: up to 12 significant digits, trailing zeros dropped, and
-- scientific notation ("1,5 × 10¹⁸") outside 1e-6 .. 1e15.
-- `maxdec` (optional) caps the decimals, for percentages.
function Format.number(v, lang, maxdec)
    if v ~= v then return "?" end
    if v == 0 then return "0" end
    local a = math.abs(v)
    if a >= 1e15 or a < 1e-6 and not maxdec then
        local e = math.floor(math.log(a) / math.log(10))
        local m = a / 10 ^ e
        if m >= 9.9999999999995 then m = m / 10; e = e + 1 end
        if m < 1 then m = m * 10; e = e - 1 end
        local ms = stripZeros(string.format("%.10f", m))
        local es = tostring(e):gsub(".", SUPER)
        return (v < 0 and "−" or "") .. Format.localise(ms, lang) .. " × 10" .. es
    end
    local dec = math.max(0, Format.DIGITS - intDigits(a))
    if maxdec then dec = math.min(dec, maxdec) end
    local s = stripZeros(string.format("%." .. dec .. "f", v))
    if s == "-0" then s = "0" end
    return Format.localise(s, lang)
end

-- Money: always two decimals ("1 109,20").
function Format.money(v, lang)
    local s = string.format("%.2f", v)
    if s == "-0.00" then s = "0.00" end
    return Format.localise(s, lang)
end

-- A value pasted into an expression keeps every digit ("%.17g" round-trips
-- a double exactly), so 1/3 reused and times 3 gives 1 again.
function Format.valueToken(v)
    local s = string.format("%.17g", v)
    if s == "-0" then s = "0" end
    return "v:" .. s
end

-- ---------------------------------------------------------------------------
-- Expressions
-- ---------------------------------------------------------------------------

local SHOW = {
    ["+"] = "+", ["-"] = "−", ["*"] = "×", ["/"] = "÷", ["^"] = "^",
    ["("] = "(", [")"] = ")", ["%"] = "%", ["!"] = "!",
    sq = "²", cube = "³", inv = "⁻¹", neg = "−",
    pi = "π", e = "e",
    ["sin("] = "sin(", ["cos("] = "cos(", ["tan("] = "tan(",
    ["log("] = "log(", ["ln("] = "ln(", ["sqrt("] = "√(", ["cbrt("] = "∛(",
}
Format.SHOW = SHOW

local BINARY = { ["+"] = true, ["-"] = true, ["*"] = true, ["/"] = true }

-- Is the "-" at index i a sign rather than a subtraction?
function Format.isUnaryMinus(tokens, i)
    if tokens[i] ~= "-" then return false end
    return not Parser.endsOperand(tokens[i - 1])
end

function Format.token(tok, lang)
    if tok:sub(1, 2) == "v:" then
        local v = tonumber(tok:sub(3)) or 0
        return Format.number(v, lang)
    end
    if Parser.isNumberToken(tok) then
        return Format.localise(tok, lang)
    end
    return SHOW[tok] or tok
end

-- The expression line: "12 + 3,5 × (2 − 1)". Binary + − × ÷ get spaces
-- around them, signs and everything else are packed.
function Format.expression(tokens, lang)
    local out = {}
    for i, tok in ipairs(tokens) do
        local s = Format.token(tok, lang)
        if BINARY[tok] and not Format.isUnaryMinus(tokens, i) then
            s = " " .. s .. " "
        end
        out[#out + 1] = s
    end
    return (table.concat(out):gsub("^ +", ""):gsub(" +$", ""))
end

return Format
