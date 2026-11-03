local DIR = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local Finance = dofile(DIR .. "finance.lua")

local function cents(v) return math.floor(v * 100 + 0.5) / 100 end

describe("finance", function()
    it("computes VAT both ways", function()
        local ht, vat, ttc = Finance.vat(100, 20, "ht2ttc")
        assert.are.equal(100, ht); assert.are.equal(20, cents(vat)); assert.are.equal(120, cents(ttc))
        ht, vat, ttc = Finance.vat(120, 20, "ttc2ht")
        assert.are.equal(100, cents(ht)); assert.are.equal(20, cents(vat)); assert.are.equal(120, ttc)
        ht, vat, ttc = Finance.vat(10.55, 5.5, "ttc2ht")
        assert.are.equal(10, cents(ht)); assert.are.equal(0.55, cents(vat))
        assert.are.equal("rate", select(2, Finance.vat(10, -100, "ht2ttc")))
    end)

    it("computes a discount", function()
        local final, saving = Finance.discount(80, 25)
        assert.are.equal(60, final); assert.are.equal(20, saving)
    end)

    it("computes a percent change", function()
        assert.are.equal(25, Finance.change(80, 100))
        assert.are.equal(-20, Finance.change(100, 80))
        assert.are.equal(50, Finance.change(-10, -5))
        assert.are.equal("zero", select(2, Finance.change(0, 5)))
        assert.are.equal(20, select(2, Finance.change(80, 100)))
    end)

    it("computes X % of Y", function()
        assert.are.equal(15, Finance.percentOf(15, 100))
        assert.are.equal(30, Finance.percentOf(20, 150))
    end)

    it("splits a bill with a tip", function()
        local tip, total, each = Finance.split(100, 4, 10)
        assert.are.equal(10, cents(tip)); assert.are.equal(110, cents(total)); assert.are.equal(27.5, cents(each))
        assert.are.equal(25, select(3, Finance.split(100, 4, 0)))
        assert.are.equal("people", select(2, Finance.split(100, 0, 10)))
        assert.are.equal("people", select(2, Finance.split(100, 2.5, 10)))
    end)

    it("converts durations to months", function()
        assert.are.equal(240, Finance.months(20, "years"))
        assert.are.equal(30, Finance.months(2.5, "years"))
        assert.are.equal(18, Finance.months(18, "months"))
    end)

    it("matches known loan payments", function()
        -- 200 000 at 3 % over 20 years: 1 109.20 a month (standard tables).
        local pmt, total, interest = Finance.loan(200000, 3, 240)
        assert.are.equal(1109.20, cents(pmt))
        assert.are.equal(266206.85, cents(total))
        assert.are.equal(66206.85, cents(interest))
        -- 100 000 at 5 % over 30 years: 536.82.
        assert.are.equal(536.82, cents(Finance.loan(100000, 5, 360)))
        -- 10 000 at 6 % over 5 years: 193.33.
        assert.are.equal(193.33, cents(Finance.loan(10000, 6, 60)))
        -- 0 %: the amount split evenly.
        pmt, total, interest = Finance.loan(1200, 0, 12)
        assert.are.equal(100, pmt); assert.are.equal(0, interest)
        assert.are.equal("months", select(2, Finance.loan(1000, 3, 0)))
        assert.are.equal("months", select(2, Finance.loan(1000, 3, 1.5)))
    end)

    it("matches known savings values", function()
        -- 10 000 at 5 % compounded monthly for 10 years: 16 470.09.
        local final, deposited, interest = Finance.savings(10000, 5, 120, 0)
        assert.are.equal(16470.09, cents(final))
        assert.are.equal(10000, deposited)
        assert.are.equal(6470.09, cents(interest))
        -- 100 a month at 5 % for 10 years: 15 528.23.
        final, deposited = Finance.savings(0, 5, 120, 100)
        assert.are.equal(15528.23, cents(final))
        assert.are.equal(12000, deposited)
        -- Both together add up.
        assert.are.equal(cents(16470.09 + 15528.23), cents(Finance.savings(10000, 5, 120, 100)))
        -- 0 %: just the deposits.
        assert.are.equal(1600, Finance.savings(400, 0, 12, 100))
    end)
end)
