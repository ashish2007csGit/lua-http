describe("http.headers module", function()
	local headers = require "http.headers"
	it("__tostring works", function()
		local h = headers.new()
		assert.same("http.headers{", tostring(h):match("^.-%{"))
	end)
	it("multiple values can be added for same key", function()
		local h = headers.new()
		h:append("a", "a", false)
		h:append("a", "b", false)
		h:append("foo", "bar", true)
		h:append("a", "c", false)
		h:append("a", "a", true)
		local iter, state = h:each()
		assert.same({"a", "a", false}, {iter(state)})
		assert.same({"a", "b", false}, {iter(state)})
		assert.same({"foo", "bar", true}, {iter(state)})
		assert.same({"a", "c", false}, {iter(state)})
		assert.same({"a", "a", true}, {iter(state)})
	end)
	it("entries are kept in order", function()
		local h = headers.new()
		h:append("a", "a", false)
		h:append("b", "b", true)
		h:append("c", "c", false)
		h:append("d", "d", true)
		h:append("d", "d", true) -- twice
		h:append("e", "e", false)
		local iter, state = h:each()
		assert.same({"a", "a", false}, {iter(state)})
		assert.same({"b", "b", true}, {iter(state)})
		assert.same({"c", "c", false}, {iter(state)})
		assert.same({"d", "d", true}, {iter(state)})
		assert.same({"d", "d", true}, {iter(state)})
		assert.same({"e", "e", false}, {iter(state)})
	end)
	it(":clone works", function()
		local h = headers.new()
		h:append("a", "a", false)
		h:append("b", "b", true)
		h:append("c", "c", false)
		local j = h:clone()
		assert.same(h, j)
	end)
	it(":has works", function()
		local h = headers.new()
		assert.same(h:has("a"), false)
		h:append("a", "a")
		assert.same(h:has("a"), true)
		assert.same(h:has("b"), false)
	end)
	it(":delete works", function()
		local h = headers.new()
		assert.falsy(h:delete("a"))
		h:append("a", "a")
		assert.truthy(h:has("a"))
		assert.truthy(h:delete("a"))
		assert.falsy(h:has("a"))
		assert.falsy(h:delete("a"))
	end)
	it(":get_comma_separated works", function()
		local h = headers.new()
		assert.same(nil, h:get_comma_separated("a"))
		h:append("a", "a")
		h:append("a", "b")
		h:append("a", "c")
		assert.same("a,b,c", h:get_comma_separated("a"))
	end)
	it(":modifyi works", function()
		local h = headers.new()
		h:append("key", "val")
		assert.same("val", h:get("key"))
		h:modifyi(1, "val")
		assert.same("val", h:get("key"))
		h:modifyi(1, "val2")
		assert.same("val2", h:get("key"))
		assert.has.errors(function() h:modifyi(2, "anything") end)
	end)
	it(":upsert works", function()
		local h = headers.new()
		h:append("a", "a", false)
		h:append("b", "b", true)
		h:append("c", "c", false)
		assert.same(3, h:len())
		h:upsert("b", "foo", false)
		assert.same(3, h:len())
		assert.same("foo", h:get("b"))
		h:upsert("d", "d", false)
		assert.same(4, h:len())
		local iter, state = h:each()
		assert.same({"a", "a", false}, {iter(state)})
		assert.same({"b", "foo", false}, {iter(state)})
		assert.same({"c", "c", false}, {iter(state)})
		assert.same({"d", "d", false}, {iter(state)})
	end)
	it(":upsert fails on multi-valued field", function()
		local h = headers.new()
		h:append("a", "a")
		h:append("a", "b")
		assert.has.errors(function() h:upsert("a", "something else") end)
	end)
	it("never_index defaults to sensible boolean", function()
		local h = headers.new()
		h:append("content-type", "application/json")
		h:append("authorization", "supersecret")
		assert.same({"content-type", "application/json", false}, {h:geti(1)})
		assert.same({"authorization", "supersecret", true}, {h:geti(2)})
		h:upsert("authorization", "different secret")
		assert.same({"authorization", "different secret", true}, {h:geti(2)})
	end)
	it(":sort works", function()
		-- should sort first by field name (':' first), then value, then never_index
		local h = headers.new()
		h:append("z", "1")
		h:append("b", "3")
		h:append("z", "2")
		h:append(":special", "!")
		h:append("a", "5")
		h:append("z", "6", true)
		for _=1, 2 do -- do twice to ensure consistency
			h:sort()
			assert.same({":special", "!", false}, {h:geti(1)})
			assert.same({"a", "5", false}, {h:geti(2)})
			assert.same({"b", "3", false}, {h:geti(3)})
			assert.same({"z", "1", false}, {h:geti(4)})
			assert.same({"z", "2", false}, {h:geti(5)})
			assert.same({"z", "6", true }, {h:geti(6)})
		end
	end)
end)
