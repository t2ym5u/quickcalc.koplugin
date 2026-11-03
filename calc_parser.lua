-- calc_parser.lua -- safe evaluator for the calculator's expressions.
--
-- The keypad never builds a string for Lua to run: it builds a list of
-- tokens, and this recursive-descent parser walks that list. Nothing here
-- ever reaches load/loadstring, so whatever is typed can only ever be
-- arithmetic.
--
-- Tokens (strings):
--   "123", "4.5", "0."       a number being typed
--   "v:<number>"             a value pasted in whole (Ans, MR, history)
--   "+" "-" "*" "/" "^"      binary operators ("-" is unary where an
--                            operand is expected)
--   "neg"                    unary minus put in by the ± key
--   "(" ")"
--   "%" "!" "sq" "cube" "inv"   postfix: percent, factorial, x², x³, x⁻¹
--   "sin(" "cos(" "tan(" "log(" "ln(" "sqrt(" "cbrt("   functions, open paren
--                            included
--   "pi" "e"                 constants
--
-- Grammar, loosest first:
--   expr    := term (("+" | "-") term)*
--   term    := unary (("*" | "/" | <implicit>) unary)*
--   unary   := ("-" | "+" | "neg") unary | power
--   power   := postfix ("^" unary)?           right-associative, and -2^2 = -4
--   postfix := primary ("%" | "!" | "sq" | "cube" | "inv")*
--   primary := number | constant | "(" expr ")" | function expr ")"
-- Missing closing parentheses at the end are implied.
--
-- Percent follows the pocket-calculator rule: right after + or -, "a + b%"
-- adds b percent *of a* (200 + 10% = 220); anywhere else b% is b/100
-- (200 × 10% = 20).
--
-- Parser.evaluate(tokens, opts) returns the value, or nil and an error code:
--   "syntax"   -- the expression is incomplete or malformed
--   "div0"     -- division by zero
--   "domain"   -- outside a function's domain (√-1, ln 0, tan 90°, 2.5!)
--   "overflow" -- the result is too large to show

local Parser = {}

-- Anything at or past this magnitude is reported as an overflow, like a
-- pocket calculator does (and 70! is the first factorial to get there).
Parser.MAX = 1e100

local FUNCS = {
    ["sin("] = true, ["cos("] = true, ["tan("] = true,
    ["log("] = true, ["ln("] = true, ["sqrt("] = true, ["cbrt("] = true,
}
Parser.FUNCS = FUNCS

local POSTFIX = { ["%"] = true, ["!"] = true, sq = true, cube = true, inv = true }
Parser.POSTFIX = POSTFIX

local CONSTS = { pi = math.pi, e = math.exp(1) }

local function fail(code)
    error({ calc_error = code }, 0)
end

local function check(v)
    if v ~= v then fail("domain") end
    if v == math.huge or v == -math.huge or math.abs(v) >= Parser.MAX then fail("overflow") end
    return v
end

-- A token that can begin an operand: what makes "2π" or "3(4+1)" an
-- implied multiplication.
local function startsOperand(tok)
    if tok == nil then return false end
    return tok == "(" or tok == "pi" or tok == "e" or FUNCS[tok] ~= nil
        or Parser.isNumberToken(tok)
end

function Parser.isNumberToken(tok)
    return type(tok) == "string" and (tok:sub(1, 2) == "v:" or tok:match("^[%d.]") ~= nil)
end

-- The numeric value of a number token, or nil.
function Parser.numberValue(tok)
    if tok:sub(1, 2) == "v:" then return tonumber(tok:sub(3)) end
    if not tok:match("^%d*%.?%d*$") or tok == "." then return nil end
    return tonumber(tok)
end

-- An operand-ending token: after one, a binary operator is expected.
function Parser.endsOperand(tok)
    if tok == nil then return false end
    return tok == ")" or tok == "pi" or tok == "e" or POSTFIX[tok] ~= nil
        or Parser.isNumberToken(tok)
end

-- Is the angle a whole multiple of `step` degrees? Comparing in degrees
-- keeps sin 180° at exactly 0 instead of 1.2e-16.
local function multipleOf(x, step)
    local r = x % step
    return math.abs(r) < 1e-9 or math.abs(r - step) < 1e-9
end

local function trig(name, x, angle)
    if angle == "deg" then
        if name == "sin" and multipleOf(x, 180) then return 0 end
        if name == "cos" and multipleOf(x - 90, 180) then return 0 end
        if name == "tan" then
            if multipleOf(x, 180) then return 0 end
            if multipleOf(x - 90, 180) then fail("domain") end
        end
        x = x * math.pi / 180
    end
    local v = math[name](x)
    -- Radians: π itself is inexact, so sin π lands at 1.2e-16; call it 0.
    if math.abs(v) < 1e-14 then v = 0 end
    return v
end

local function factorial(n)
    if n < 0 or n ~= math.floor(n) then fail("domain") end
    if n > 170 then fail("overflow") end
    local r = 1.0
    for i = 2, n do r = r * i end
    return r
end

local function power(a, b)
    if a == 0 and b < 0 then fail("div0") end
    if a < 0 and b ~= math.floor(b) then fail("domain") end
    return check(a ^ b)
end

local function applyFunc(f, x, angle)
    if f == "sin(" then return trig("sin", x, angle) end
    if f == "cos(" then return trig("cos", x, angle) end
    if f == "tan(" then return check(trig("tan", x, angle)) end
    if f == "sqrt(" then
        if x < 0 then fail("domain") end
        return math.sqrt(x)
    end
    if f == "cbrt(" then
        local r = math.abs(x) ^ (1 / 3)
        -- Snap 27 -> 3 rather than 3.0000000000000004.
        local n = math.floor(r + 0.5)
        if n * n * n == math.abs(x) then r = n end
        return x < 0 and -r or r
    end
    if f == "log(" then
        if x <= 0 then fail("domain") end
        local r = math.log(x) / math.log(10)
        local n = math.floor(r + 0.5)
        if 10 ^ n == x then r = n end
        return r
    end
    if f == "ln(" then
        if x <= 0 then fail("domain") end
        return math.log(x)
    end
    fail("syntax")
end

-- Sum or difference, with the round-off of 0.3 - 0.1 - 0.2 cleaned to 0.
local function addSub(a, b, op)
    local r = op == "+" and a + b or a - b
    if r ~= 0 and math.abs(r) < 1e-12 * math.max(math.abs(a), math.abs(b)) then r = 0 end
    return check(r)
end

function Parser.evaluate(tokens, opts)
    opts = opts or {}
    local angle = opts.angle or "deg"
    local pos = 1
    local n = #tokens

    local function peek() return tokens[pos] end
    local function take() pos = pos + 1; return tokens[pos - 1] end

    local expr

    local function primary()
        local tok = take()
        if tok == nil then fail("syntax") end
        if Parser.isNumberToken(tok) then
            local v = Parser.numberValue(tok)
            if not v then fail("syntax") end
            return check(v + 0.0)
        end
        if CONSTS[tok] then return CONSTS[tok] end
        if tok == "(" or FUNCS[tok] then
            local v = expr()
            if peek() == ")" then
                take()
            elseif peek() ~= nil then
                fail("syntax")
            end
            if FUNCS[tok] then return check(applyFunc(tok, v, angle)) end
            return v
        end
        fail("syntax")
    end

    -- Returns value, is_percent (the operand ended in a bare %).
    local function postfix()
        local v = primary()
        local pct = false
        while POSTFIX[peek() or ""] do
            local op = take()
            pct = false
            if op == "%" then
                v = v / 100
                pct = true
            elseif op == "!" then
                v = factorial(v)
            elseif op == "sq" then
                v = check(v * v)
            elseif op == "cube" then
                v = check(v * v * v)
            elseif op == "inv" then
                if v == 0 then fail("div0") end
                v = check(1 / v)
            end
        end
        return v, pct
    end

    local unary

    local function pow()
        local v, pct = postfix()
        if peek() == "^" then
            take()
            local e = unary()
            return power(v, e), false
        end
        return v, pct
    end

    unary = function()
        local tok = peek()
        if tok == "-" or tok == "neg" then
            take()
            local v = unary()
            return -v, false
        elseif tok == "+" then
            take()
            return (unary()), false
        end
        return pow()
    end

    local function term()
        local v, pct = unary()
        while true do
            local tok = peek()
            if tok == "*" or tok == "/" then
                take()
                local r = unary()
                if tok == "*" then
                    v = check(v * r)
                else
                    if r == 0 then fail("div0") end
                    v = check(v / r)
                end
                pct = false
            elseif startsOperand(tok) then
                local r = unary()
                v = check(v * r)
                pct = false
            else
                break
            end
        end
        return v, pct
    end

    expr = function()
        local v = term()
        while true do
            local tok = peek()
            if tok ~= "+" and tok ~= "-" then break end
            take()
            local r, pct = term()
            if pct then r = v * r end
            v = addSub(v, r, tok)
        end
        return v
    end

    if n == 0 then return nil, "syntax" end
    local ok, res = pcall(function()
        local v = expr()
        if pos <= n then fail("syntax") end
        return check(v)
    end)
    if ok then
        if res == 0 then res = 0 end -- no "-0"
        return res
    end
    if type(res) == "table" and res.calc_error then return nil, res.calc_error end
    error(res, 0)
end

-- ---------------------------------------------------------------------------
-- tokenize: a plain-text front end, for the specs and anything else that
-- wants to write "2+3*4" rather than a token list. ASCII only:
--   + - * / ^ ( ) % ! digits . pi e sin( cos( tan( log( ln( sqrt( cbrt(
-- ---------------------------------------------------------------------------

function Parser.tokenize(s)
    local out = {}
    local i = 1
    while i <= #s do
        local c = s:sub(i, i)
        if c:match("%s") then
            i = i + 1
        elseif c:match("[%d.]") then
            local num = s:match("^[%d.]+", i)
            out[#out + 1] = num
            i = i + #num
        elseif c:match("%a") then
            local word = s:match("^%a+", i)
            if s:sub(i + #word, i + #word) == "(" and FUNCS[word .. "("] then
                out[#out + 1] = word .. "("
                i = i + #word + 1
            elseif CONSTS[word] then
                out[#out + 1] = word
                i = i + #word
            else
                return nil
            end
        elseif c:match("[%+%-%*/%^%(%)%%!]") then
            out[#out + 1] = c
            i = i + 1
        else
            return nil
        end
    end
    return out
end

return Parser
