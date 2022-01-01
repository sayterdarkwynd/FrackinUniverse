-- LoggingOverride
-- Changes lua's stock print and error functions so that they use the sb log, and appends a warn() function for warnings.
--[[
	API:

		call
		local print, warn, error, assertwarn, assert, tostring = CreateLoggingOverride([string prefix = nil], [bool tostringUsesSBPrint = false]) AFTER init and...

			void print(...)
				Behaves identically to Lua's stock print(), but redirects the output to sb.logInfo. All args are safely converted to strings.

			void warn(...)
				Behaves identically to Lua's stock print(), but redirects the output to sb.logWarn. All args are safely converted to strings.

			void error(...)
				Behaves identically to Lua's stock print(), but redirects the output to sb.logError. All args are safely converted to strings.
				NOTE: This REMOVES the trace level argument from error, since stack traces are not possible to grab in Starbound.
				This means that error("message", 3) will literally output "message 3" to the starbound.log file.

			boolean assert(bool requirement, string errorMsg = "Assertion failed")
				Checks if the requirement is met (the value is true). If the value is false, it will print errorMsg via sb.logError.
				Returns `requirement`. Since errors do not stop execution, you need to inline this behavior: if not assert(cnd, err) then return end

			boolean assertwarn(bool requirement, string errorMsg = "Assertion failed")
				Identical to assert but uses sb.logWarn instead of sb.logError


		If a prefix was specified, it will be appended before any messages passed into the functions above.
		For instance:
			CreateLoggingOverride("[Joe Mama]")
			print("nice meme")

		will output:
			[Info]: [Joe Mama] nice meme
--]]
-- Set up the necessary prerequisite data
if LUA_TOSTRING == nil then
	LUA_TOSTRING = tostring
end

-- Converts an arbitrary number of args into a string like how print() does.
local function ArgsToString(...)
	local array = {...}
	local strArray = {}

	-- Make sure everything is a string. table.concat does NOT get along with non-string values.
	-- sb.print adds some extra flair and I believe it's a better fit than stock tostring, so I'll use that if I can.
	for index = 1, #array do
		if sb then
			objAsText = sb.print(array[index])
		else
			objAsText = LUA_TOSTRING(array[index])
		end
		strArray[index] = objAsText
	end
	return table.concat(strArray, " ")
end

function CreateLoggingOverride(prefix, tostringPointsToSBPrint)
	prefix = tostring(prefix) or ""
	if prefix ~= nil and prefix ~= "" then
		prefix = prefix .. " "
	end

	-- luacheck: ignore 121
	tostring = function (...)
		if (tostringPointsToSBPrint or LUA_TOSTRING == nil) and (sb ~= nil) then
			return sb.print(...)
		else
			return LUA_TOSTRING(...)
		end
	end

	print = function (...)
		if sb == nil then return end
		sb.logInfo(prefix .. ArgsToString(...))
	end

	warn = function (...)
		if sb == nil then return end
		sb.logWarn(prefix .. ArgsToString(...))
	end

	error = function (...)
		if sb == nil then return end
		sb.logError(prefix .. ArgsToString(...))
	end


	-- n.b. when using assert you need to inline it if you want it to stop execution.
	-- if not assert(cnd, errMsg) then return end
	assertwarn = function(requirement, msg)
		if not requirement then
			-- Yes, the _ENV is necessary here.
			-- Without this, having different logging overrides in different scripts can cause them go get mixed up because it references the wrong function (namely, the one defined here rather than the current script's override)
			_ENV.warn(prefix .. (msg or "Assertion failed!"))
		end
		return requirement
	end

	assert = function(requirement, msg)
		if not requirement then
			local msg = msg or "Assertion failed!"
			_ENV.error(msg)
		end
		return requirement
	end

	return print, warn, error, assertwarn, assert, tostring
end
