-- finance.lua -- the formulas behind the Percentages, Bill split and Loan
-- & savings modes. Pure Lua; rates are in percent (20 means 20 %).
-- Functions return nil plus an error code when a result can't be computed:
--   "zero"    -- a value that must not be zero is (the base of a % change)
--   "people"  -- the number of people is not a whole number >= 1
--   "months"  -- the duration is not a whole number of months >= 1
--   "rate"    -- a rate below -100 %

local Finance = {}

-- VAT. dir = "ht2ttc": amount is before tax; "ttc2ht": amount includes tax.
-- Returns excl, vat, incl.
function Finance.vat(amount, rate, dir)
    if rate <= -100 then return nil, "rate" end
    local excl, incl
    if dir == "ttc2ht" then
        incl = amount
        excl = amount / (1 + rate / 100)
    else
        excl = amount
        incl = amount * (1 + rate / 100)
    end
    return excl, incl - excl, incl
end

-- Returns final price, saving.
function Finance.discount(price, pct)
    local saving = price * pct / 100
    return price - saving, saving
end

-- % change from a to b. Returns percent, difference.
function Finance.change(a, b)
    if a == 0 then return nil, "zero" end
    return (b - a) / math.abs(a) * 100, b - a
end

-- x % of y.
function Finance.percentOf(x, y)
    return x * y / 100
end

-- Returns tip, total with tip, per person.
function Finance.split(total, people, tip_pct)
    if people < 1 or people ~= math.floor(people) then return nil, "people" end
    local tip = total * (tip_pct or 0) / 100
    local with_tip = total + tip
    return tip, with_tip, with_tip / people
end

-- Duration in months from a value and its unit ("years" or "months").
function Finance.months(duration, unit)
    local m = unit == "months" and duration or duration * 12
    -- 2.5 years is 30 months; 1.3 years is not a whole number of payments.
    if math.abs(m - math.floor(m + 0.5)) < 1e-9 then m = math.floor(m + 0.5) end
    return m
end

-- Fixed-rate loan, repaid monthly (French "mensualités constantes").
-- Returns monthly payment, total repaid, total interest.
function Finance.loan(principal, annual_rate, months)
    if months < 1 or months ~= math.floor(months) then return nil, "months" end
    if annual_rate <= -100 then return nil, "rate" end
    local r = annual_rate / 100 / 12
    local pmt
    if r == 0 then
        pmt = principal / months
    else
        pmt = principal * r / (1 - (1 + r) ^ -months)
    end
    local total = pmt * months
    return pmt, total, total - principal
end

-- Savings with interest compounded monthly at annual_rate / 12, and an
-- optional deposit at the end of every month.
-- Returns final balance, total deposited (initial included), interest earned.
function Finance.savings(initial, annual_rate, months, deposit)
    if months < 1 or months ~= math.floor(months) then return nil, "months" end
    if annual_rate <= -100 then return nil, "rate" end
    deposit = deposit or 0
    local r = annual_rate / 100 / 12
    local g = (1 + r) ^ months
    local final
    if r == 0 then
        final = initial + deposit * months
    else
        final = initial * g + deposit * (g - 1) / r
    end
    local deposited = initial + deposit * months
    return final, deposited, final - deposited
end

return Finance
