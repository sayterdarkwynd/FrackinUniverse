function init()
  script.setUpdateDelta(3)
  rescuePosition = mcontroller.position()
  self.randVal = math.random(1,24)
  world.spawnItem("fumadnessresource",entity.position(),self.randVal)
end

function update(dt)
  animator.setFlipped(mcontroller.facingDirection() == -1)
  if status.resourcePercentage("health") < 0.099 then
	--sb.logInfo("Rescuing!")
	mcontroller.setPosition(rescuePosition)
	status.setResourcePercentage("health", 0.100)
  end
end

function uninit()

end



-- Dumps value as a string
--
-- Basic usage: dump(value)
-- e.g. sb.logInfo(dump(_ENV))
--
-- @param value The value to be dumped.
-- @param indent (optional) String used for indenting the dumped value.
-- @param seen (optional) Table of already processed tables which will be
--                        dumped as "{...}" to prevent infinite recursion.
function dump(value, indent, seen)
	if type(value) ~= "table" then
		if type(value) == "string" then
			return string.format('%q', value)
		else
			return tostring(value)
		end
	else
		if type(seen) ~= "table" then
			seen = {}
		elseif seen[value] then
			return "{...}"
		end
		seen[value] = true
		indent = indent or ""
		if next(value) == nil then
			return "{}"
		end
		local str = "{"
		local first = true
		for k,v in pairs(value) do
			if first then
				first = false
			else
				str = str..","
			end
			str = str.."\n"..indent.."  ".."["..dump(k).."] = "..dump(v, indent.."  ")
		end
		str = str.."\n"..indent.."}"
		return str
	end
end