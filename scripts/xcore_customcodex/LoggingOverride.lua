-- LoggingOverride
-- Changes lua's stock print and error functions so that they use the sb log, and appends a warn() function for warnings.
--[[
	API:
	
		call 
		local print, warn, error, assertwarn, assert, tostring = CreateLoggingOverride([string prefix = nil]) AFTER init and...
	
			boolean TOSTRING_USES_SB_PRINT = false
				If true, tostring() will call sb.print() instead of Lua's native method.
				
			n.b. You can set the above globals on a per-context basis by locally setting them BEFORE requiring this.
			local TOSTRING_USES_SB_PRINT = true
			require("path/to/LoggingOverride.lua")
			
		
			void print(...)
				Behaves identically to Lua's stock print(), but redirects the output to sb.logInfo. All args are safely converted to strings.
				
			void warn(...)
				Behaves identically to Lua's stock print(), but redirects the output to sb.logWarn. All args are safely converted to strings.
				
			void error(...)
				Behaves identically to Lua's stock print(), but redirects the output to sb.logError. All args are safely converted to strings.
				NOTE: This REMOVES the trace level argument from error, since stack traces are not possible to grab in Starbound.
				This means that error("message", 3) will literally output "message 3" to the starbound.log file.
				
			void assert(bool requirement, string errorMsg = "Assertion failed")
				Checks if the requirement is met (the value is true). If the value is false, it will print errorMsg via sb.logError.
				
			void assertwarn(bool requirement, string errorMsg = "Assertion failed")
				Identical to assert but uses sb.logWarn instead of sb.logError
				
				
		If a prefix was specified, it will be appended before any messages passed into the functions above.
		For instance:
			CreateLoggingOverride("[Joe Mama]")
			print("nice meme")
		
		will output:
			[Info]: [Joe Mama] nice meme
--]]

function CreateLoggingOverride(prefix)
	local prefix = tostring(prefix) or ""
	if prefix ~= nil and prefix ~= "" then
		prefix = prefix .. " "
	end
	TOSTRING_USES_SB_PRINT = (TOSTRING_USES_SB_PRINT == true) -- enforce boolean
	LUA_TOSTRING = tostring

	-- Converts an arbitrary number of args into a string like how print() does.
	local function ArgsToString(...)
		local array = {...}
		local strArray = {}
		
		-- Make sure everything is a string. table.concat does NOT get along with non-string values.
		-- sb.print adds some extra flair and I believe it's a better fit than stock tostring
		for index = 1, #array do
			strArray[index] = sb.print(array[index])
		end
		return table.concat(strArray, " ")
	end


	tostring = function (...)
		if (TOSTRING_USES_SB_PRINT or LUA_TOSTRING == nil) and (sb ~= nil) then
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

	assertwarn = function(requirement, msg)
		if not requirement then
			_ENV.warn(prefix .. (msg or "Assertion failed"))
		end
	end

	assert = function(requirement, msg)
		if not requirement then
			local msg = msg or "Assertion failed"
			_ENV.error(msg)
		end
	end
	
	return print, warn, error, assertwarn, assert, tostring
end