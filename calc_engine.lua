-- calc_engine.lua -- what each calculator key does to the expression.
--
-- Pure Lua: the screen hands key ids to Engine:press() and redraws from the
-- engine's fields. Key ids:
--   "0".."9" "."                digits and the decimal point
--   "+" "-" "*" "/" "^"         operators
--   "(" ")"
--   "%" "!" "sq" "cube" "inv"   postfix (percent, n!, x², x³, 1/x)
--   "sin(" "cos(" "tan(" "log(" "ln(" "sqrt(" "cbrt("
--   "pi" "e" "exp" "pow10"      constants, eˣ and 10ˣ
--   "neg"                       ± (sign of the number being typed)
--   "C" "CE" "back" "="
--   "ans" "MC" "MR" "M+" "M-" "angle"
--
-- State (all serialisable):
--   tokens     the expression (see calc_parser.lua)
--   evaluated  true right after "=": the tokens are the finished expression
--              and `result` its value; the next key starts from there
--   result     last value computed by "=" (Ans)
--   error      error code of the last "=" (cleared by the next key)
--   memory     M register, or nil when empty
--   history    newest first: { tokens = {...}, value = n }, at most 20
--   angle      "deg" or "rad"

local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local Parser = lrequire("calc_parser")
local Format = lrequire("calc_format")

local Engine = {}
Engine.__index = Engine

Engine.HISTORY_MAX = 20
Engine.MAX_DIGITS  = 15

local function copy(t)
    local out = {}
    for i, v in ipairs(t or {}) do out[i] = v end
    return out
end

function Engine.new(saved)
    saved = type(saved) == "table" and saved or {}
    local self = setmetatable({}, Engine)
    self.tokens    = copy(saved.tokens)
    self.evaluated = saved.evaluated and true or false
    self.result    = tonumber(saved.result)
    self.memory    = tonumber(saved.memory)
    self.angle     = saved.angle == "rad" and "rad" or "deg"
    self.error     = nil
    self.history   = {}
    for _i, h in ipairs(saved.history or {}) do
        if type(h) == "table" and tonumber(h.value) and #self.history < Engine.HISTORY_MAX then
            self.history[#self.history + 1] = { tokens = copy(h.tokens), value = tonumber(h.value) }
        end
    end
    -- A finished expression without its value can't be shown as one.
    if self.evaluated and not self.result then self.evaluated = false end
    return self
end

function Engine:serialize()
    local hist = {}
    for i, h in ipairs(self.history) do hist[i] = { tokens = copy(h.tokens), value = h.value } end
    return {
        tokens    = copy(self.tokens),
        evaluated = self.evaluated,
        result    = self.result,
        memory    = self.memory,
        angle     = self.angle,
        history   = hist,
    }
end

-- ---------------------------------------------------------------------------
-- Token helpers
-- ---------------------------------------------------------------------------

function Engine:last()
    return self.tokens[#self.tokens]
end

local function isTyped(tok)
    -- A number still being typed (as opposed to a pasted "v:" value).
    return tok ~= nil and tok:match("^[%d.]") ~= nil
end

function Engine:openParens()
    local depth = 0
    for _i, tok in ipairs(self.tokens) do
        if tok == "(" or Parser.FUNCS[tok] then
            depth = depth + 1
        elseif tok == ")" then
            depth = depth - 1
        end
    end
    return depth
end

function Engine:push(tok)
    self.tokens[#self.tokens + 1] = tok
end

-- Before a new operand: after a finished one, an explicit × goes in (2π is
-- read as 2×π anyway, but "5 10^(" would not say what it means).
function Engine:beforeOperand(explicit)
    if Parser.endsOperand(self:last()) then
        if explicit then self:push("*") end
        return true
    end
    return false
end

-- Start over from the last result, for an operator typed right after "=".
function Engine:continueFromResult()
    self.tokens = { Format.valueToken(self.result) }
    self.evaluated = false
end

function Engine:resetIfEvaluated()
    if self.evaluated then
        self.tokens = {}
        self.evaluated = false
    end
end

function Engine:insertValue(v)
    if v == nil then return end
    self:resetIfEvaluated()
    self:beforeOperand(true)
    self:push(Format.valueToken(v))
end

-- ---------------------------------------------------------------------------
-- Keys
-- ---------------------------------------------------------------------------

function Engine:digit(d)
    self:resetIfEvaluated()
    local last = self:last()
    if isTyped(last) then
        local digits = #last:gsub("%.", "")
        if d == "." then
            if last:find(".", 1, true) then return end
            self.tokens[#self.tokens] = last .. "."
        else
            if digits >= Engine.MAX_DIGITS then return end
            if last == "0" then
                self.tokens[#self.tokens] = d
            else
                self.tokens[#self.tokens] = last .. d
            end
        end
        return
    end
    self:beforeOperand(true)
    self:push(d == "." and "0." or d)
end

local BINARY = { ["+"] = true, ["-"] = true, ["*"] = true, ["/"] = true, ["^"] = true }

function Engine:operator(op)
    if self.evaluated then self:continueFromResult() end
    local last = self:last()
    if last == nil then
        if op == "-" then self:push("-") return end
        -- "× 3" on an empty line means "0 × 3".
        self:push("0")
        self:push(op)
        return
    end
    if BINARY[last] then
        if Format.isUnaryMinus(self.tokens, #self.tokens) then
            -- That "-" is a sign: another operator replaces it (and then
            -- whatever operator came before it).
            if op == "-" then return end
            table.remove(self.tokens)
            return self:operator(op)
        end
        if op == "-" and (last == "*" or last == "/" or last == "^") then
            -- 2 × −3, 2 ^ −1: a sign after an operator.
            self:push("-")
            return
        end
        self.tokens[#self.tokens] = op
        return
    end
    if last == "(" or Parser.FUNCS[last] or last == "neg" then
        if op == "-" and last ~= "neg" then self:push("-") end
        return
    end
    self:push(op)
end

function Engine:postfix(op)
    if self.evaluated then self:continueFromResult() end
    if Parser.endsOperand(self:last()) then
        -- A second % on the same operand would mean "per ten thousand": no.
        if op == "%" and self:last() == "%" then return end
        self:push(op)
    end
end

function Engine:func(f)
    if self.evaluated then
        -- √ right after "=" applies to the result: √(Ans).
        local v = self.result
        self.tokens = { f, Format.valueToken(v), ")" }
        self.evaluated = false
        return
    end
    self:beforeOperand(true)
    self:push(f)
end

function Engine:constant(c)
    self:resetIfEvaluated()
    self:beforeOperand(true)
    self:push(c)
end

function Engine:openParen()
    self:resetIfEvaluated()
    self:beforeOperand(true)
    self:push("(")
end

function Engine:closeParen()
    if self.evaluated then return end
    if self:openParens() > 0 and Parser.endsOperand(self:last()) then
        self:push(")")
    end
end

-- ± : flips the sign of the number being typed (or of the result).
function Engine:negate()
    if self.evaluated then
        self.tokens = { Format.valueToken(-self.result) }
        self.evaluated = false
        return
    end
    local n = #self.tokens
    local last = self.tokens[n]
    if last == nil then
        self:push("neg")
        return
    end
    if last == "neg" then
        table.remove(self.tokens)
        return
    end
    if last:sub(1, 2) == "v:" then
        local v = tonumber(last:sub(3)) or 0
        self.tokens[n] = Format.valueToken(-v)
        return
    end
    if isTyped(last) then
        if self.tokens[n - 1] == "neg" then
            table.remove(self.tokens, n - 1)
        else
            table.insert(self.tokens, n, "neg")
        end
        return
    end
    if not Parser.endsOperand(last) then
        self:push("neg")
    end
end

function Engine:backspace()
    if self.evaluated then
        -- The finished expression comes back for editing.
        self.evaluated = false
    end
    local last = self:last()
    if last == nil then return end
    if isTyped(last) and #last > 1 then
        local s = last:sub(1, -2)
        self.tokens[#self.tokens] = s
        return
    end
    table.remove(self.tokens)
end

function Engine:clearEntry()
    if self.evaluated then
        self:clearAll()
        return
    end
    local last = self:last()
    if last and Parser.isNumberToken(last) then
        table.remove(self.tokens)
        if self:last() == "neg" then table.remove(self.tokens) end
    end
end

function Engine:clearAll()
    self.tokens = {}
    self.evaluated = false
end

-- The tokens with their missing ")" added, as "=" will evaluate them.
function Engine:closedTokens()
    local t = copy(self.tokens)
    for _i = 1, self:openParens() do t[#t + 1] = ")" end
    return t
end

-- Value of the expression as typed so far, or nil (incomplete, error, or
-- nothing worth previewing: a bare number).
function Engine:preview()
    if self.evaluated or #self.tokens == 0 then return nil end
    if #self.tokens == 1 and Parser.isNumberToken(self.tokens[1]) then return nil end
    local v = Parser.evaluate(self:closedTokens(), { angle = self.angle })
    return v
end

function Engine:evaluate()
    if self.evaluated or #self.tokens == 0 then return end
    local t = self:closedTokens()
    local v, err = Parser.evaluate(t, { angle = self.angle })
    if not v then
        self.error = err
        return
    end
    self.tokens = t
    self.result = v
    self.evaluated = true
    -- A bare number typed then "=" is not worth a history line.
    if not (#t == 1 and Parser.isNumberToken(t[1])) then
        table.insert(self.history, 1, { tokens = copy(t), value = v })
        while #self.history > Engine.HISTORY_MAX do table.remove(self.history) end
    end
    return v
end

-- The value M+ / M− act on: the expression's value (it is evaluated, like
-- "="), or the last result.
function Engine:currentValue()
    if self.evaluated then return self.result end
    if #self.tokens == 0 then return self.result or 0 end
    return self:evaluate()
end

function Engine:memoryAdd(sign)
    local v = self:currentValue()
    if v == nil then return end
    local m = (self.memory or 0) + sign * v
    if m ~= m or math.abs(m) >= Parser.MAX then
        self.error = "overflow"
        return
    end
    self.memory = m
end

function Engine:clearHistory()
    self.history = {}
end

-- Reuse a history line: its value goes into the expression.
function Engine:useHistory(i)
    local h = self.history[i]
    if h then self:insertValue(h.value) end
end

local DIGITS = {}
for d = 0, 9 do DIGITS[tostring(d)] = true end
DIGITS["."] = true

function Engine:press(key)
    self.error = nil
    if DIGITS[key] then return self:digit(key) end
    if BINARY[key] then return self:operator(key) end
    if Parser.POSTFIX[key] then return self:postfix(key) end
    if Parser.FUNCS[key] then return self:func(key) end
    if key == "pi" or key == "e" then return self:constant(key) end
    if key == "exp" then
        self:constant("e")
        self:push("^")
        self:push("(")
        return
    end
    if key == "pow10" then
        self:resetIfEvaluated()
        self:beforeOperand(true)
        self:push("v:10")
        self:push("^")
        self:push("(")
        return
    end
    if key == "(" then return self:openParen() end
    if key == ")" then return self:closeParen() end
    if key == "neg" then return self:negate() end
    if key == "back" then return self:backspace() end
    if key == "CE" then return self:clearEntry() end
    if key == "C" then return self:clearAll() end
    if key == "=" then return self:evaluate() end
    if key == "ans" then return self:insertValue(self.result) end
    if key == "MC" then self.memory = nil return end
    if key == "MR" then return self:insertValue(self.memory) end
    if key == "M+" then return self:memoryAdd(1) end
    if key == "M-" then return self:memoryAdd(-1) end
    if key == "angle" then
        self.angle = self.angle == "deg" and "rad" or "deg"
        return
    end
end

return Engine
