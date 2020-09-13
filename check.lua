
checkers = {}

local function string_rep(s, n, sep)
	if n == 1 then return s end
	if n < 1 then return "" end
	if not sep then sep = "" end

	local res = s
	while n > 1 do
		res = res..sep..s
		n = n - 1
	end
	return res
end

local function mta_type(value)
	local t = type(value)
	if t ~= "userdata" then return t end

	local udt = getUserdataType(value)
	if udt == t then return t end
	if udt ~= "element" then return t..":"..udt end

	return t..":"..udt..":"..getElementType(value)
end

local default_checkers = {
	["userdata:element:gui"] = function(v) return string.match(mta_type(v), "^userdata:element:gui%-") end
}

local type_cuts = {
	["b"] = "boolean",
	["n"] = "number",
	["s"] = "string",
	["t"] = "table",
	["u"] = "userdata",
	["f"] = "function",
	["th"] = "thread"
}

local cache = {}

local function parse(pattern)

	if cache[pattern] then return cache[pattern] end

	local result = pattern
		:gsub("(%a+)", type_cuts)
		:gsub("(%?)(%a+)", "nil|%2")
		:gsub("%?", "any")
		:gsub("!", "notnil")
		:gsub("([^,]+)%[(%d)%]", function(t, n) return string_rep(t, tonumber(n), ",") end)

	result = split(result, ",")
	for i, one in ipairs(result) do
		result[i] = split(one, "|")
	end

	cache[pattern] = result

	return result
end

local function arg_invalid_msg(funcName, argNum, argName, msg)

	msg = msg and string.format(" (%s)", msg) or ""
	return string.format(
		"bad argument #%d '%s' to '%s'%s",
		argNum, argName or "?", funcName or "?", msg
	)
end

local function expected_msg(variants, found)

	for i, v in ipairs(variants) do
		variants[i] = string.gsub(v, ".+:", "")
	end
	variants = table.concat(variants, "\\")
	found = string.gsub(found, ".+:", "")

	local msg = string.format("%s expected, got %s", variants, found)
	return msg
end

function warn(msg, lvl)
	check("s,?n")

	lvl = (lvl or 1) + 1
	local dbInfo = debug.getinfo(lvl, "S")

	if dbInfo and lvl > 1 then
		local src = dbInfo.short_src
		local currentLine = debug.getinfo(lvl, "l").currentLine
		msg = string.format(
			"%s:%s: %s",
			src, currentLine, msg
		)
	end

	return outputDebugString("WARNING: "..msg, 4, 255, 127, 0)
end

local function check_one(variants, value)

	local valueType = mta_type(value)
	local mt = getmetatable(value)
	local valueClass = mt and mt.__type
	
	for i, variant in ipairs(variants) do

		if variant == "any" then return true end
		if variant == "notnil" and value ~= nil then return true end
		if valueClass and valueClass == variant then return true end

		if valueType == variant then return true end
		if string.find(valueType, variant..":", 1, true) == 1 then return true end

		local checker = default_checkers[variant]
		if checker and checker(value) then return true end

		checker = checkers[variant]
		if type(checker) == "function" and checker(value) then return true end
	end

	local msg = expected_msg(variants, valueClass or valueType)
	return false, msg
end

local function check_main(pattern)

	for i, variants in ipairs(parse(pattern)) do

		local argName, value = debug.getlocal(3, i)
		local success, descMsg = check_one(variants, value)
		if not success then

			local funcName = debug.getinfo(3, "n").name
			local msg = arg_invalid_msg(funcName, i, argName, descMsg)
			return false, msg
		end
	end

	return true
end

function check(pattern)
	if type(pattern) ~= "string" then check("string") end

	local success, msg = check_main(pattern)
	if not success then error(msg, 3) end

	return true
end

function scheck(pattern)
	if type(pattern) ~= "string" then check("string") end

	local success, msg = check_main(pattern)
	if not success then return warn(msg, 3) and false end

	return true
end