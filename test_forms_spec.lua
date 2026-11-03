local DIR = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local Forms = dofile(DIR .. "forms.lua")

local function typed(keys, integer)
    local t = ""
    for k in keys:gmatch("%S+") do t = Forms.edit(t, k, integer) end
    return t
end

describe("forms", function()
    it("types numbers on the keypad", function()
        assert.are.equal("12.5", typed("1 2 . 5"))
        assert.are.equal("0.5", typed(". 5"))
        assert.are.equal("7", typed("0 7"))
        assert.are.equal("1.5", typed("1 . . 5"))
        assert.are.equal("12", typed("1 2 3 back"))
        assert.are.equal("", typed("1 2 C"))
        assert.are.equal("-3", typed("3 neg"))
        assert.are.equal("3", typed("3 neg neg"))
        assert.are.equal("25", typed("2 . 5", true))
        assert.are.equal("123456789012", typed("1 2 3 4 5 6 7 8 9 0 1 2 3 4"))
    end)

    it("parses field text", function()
        assert.is_nil(Forms.parse(""))
        assert.is_nil(Forms.parse("-"))
        assert.are.equal(0.5, Forms.parse("0."  .. "5"))
        assert.are.equal(12, Forms.parse("12."))
        assert.are.equal(-3, Forms.parse("-3"))
    end)

    it("starts every form from its defaults", function()
        local st = Forms.newState("vat")
        assert.are.equal("20", st.values.rate)
        assert.are.equal("", st.values.amount)
        assert.are.equal("ht2ttc", st.opts.dir)
        assert.are.equal("years", Forms.newState("loan").opts.unit)
        assert.are.equal("2", Forms.newState("split").values.people)
    end)

    it("restores saved state and drops garbage", function()
        local st = Forms.loadState("vat", { values = { amount = "50", rate = "os.exit()" },
                                            opts = { dir = "ttc2ht" }, active = 2 })
        assert.are.equal("50", st.values.amount)
        assert.are.equal("20", st.values.rate)
        assert.are.equal("ttc2ht", st.opts.dir)
        assert.are.equal(2, st.active)
        assert.are.equal(1, Forms.loadState("vat", { active = 9 }).active)
        assert.are.equal("", Forms.loadState("vat", "junk").values.amount)
    end)

    it("labels a field by the form's options", function()
        local f = Forms.FORMS.vat.fields[1]
        assert.are.equal("Amount excl. VAT", Forms.fieldLabel(f, { dir = "ht2ttc" }))
        assert.are.equal("Amount incl. VAT", Forms.fieldLabel(f, { dir = "ttc2ht" }))
    end)

    it("leaves results empty until the fields are filled", function()
        local rows, err = Forms.compute("vat", Forms.newState("vat"))
        assert.is_nil(err)
        assert.are.equal(3, #rows)
        assert.is_nil(rows[1].value)
        assert.are.equal("Excl. VAT", rows[1].label)
    end)

    it("computes every form", function()
        local function run(id, values, opts)
            local st = Forms.newState(id)
            for k, v in pairs(values) do st.values[k] = v end
            for k, v in pairs(opts or {}) do st.opts[k] = v end
            local rows, err = Forms.compute(id, st)
            local out = {}
            for i, r in ipairs(rows) do out[i] = r.value and math.floor(r.value * 100 + 0.5) / 100 end
            return out, err
        end
        local r = run("vat", { amount = "100" })
        assert.are.same({ 100, 20, 120 }, r)
        r = run("vat", { amount = "110", rate = "10" }, { dir = "ttc2ht" })
        assert.are.same({ 100, 10, 110 }, r)
        assert.are.same({ 60, 20 }, (run("discount", { price = "80", pct = "25" })))
        assert.are.same({ 25, 20 }, (run("change", { from = "80", to = "100" })))
        assert.are.same({ 30, 180, 120 }, (run("pctof", { x = "20", y = "150" })))
        assert.are.same({ 10, 110, 27.5 }, (run("split", { total = "100", people = "4", tip = "10" })))
        assert.are.same({ 1109.2, 266206.85, 66206.85 },
            (run("loan", { amount = "200000", rate = "3", duration = "20" })))
        assert.are.same({ 1109.2, 266206.85, 66206.85 },
            (run("loan", { amount = "200000", rate = "3", duration = "240" }, { unit = "months" })))
        assert.are.same({ 15528.23, 12000, 3528.23 },
            (run("savings", { rate = "5", duration = "10", deposit = "100" })))
        assert.are.same({ 16470.09, 10000, 6470.09 },
            (run("savings", { initial = "10000", rate = "5", duration = "10" })))
    end)

    it("reports input that can't give a result", function()
        local st = Forms.newState("change")
        st.values.from, st.values.to = "0", "5"
        assert.are.equal("zero", select(2, Forms.compute("change", st)))
        st = Forms.newState("split")
        st.values.total, st.values.people = "50", "0"
        assert.are.equal("people", select(2, Forms.compute("split", st)))
        st = Forms.newState("loan")
        st.values.amount, st.values.rate, st.values.duration = "1000", "3", "1.3"
        assert.are.equal("months", select(2, Forms.compute("loan", st)))
    end)

    it("lists each form once in the modes", function()
        local seen = {}
        for _i, m in ipairs(Forms.MODES) do
            for _j, s in ipairs(m.subs) do
                assert.is_nil(seen[s]); seen[s] = true
                assert.is_table(Forms.FORMS[s])
            end
        end
    end)
end)
