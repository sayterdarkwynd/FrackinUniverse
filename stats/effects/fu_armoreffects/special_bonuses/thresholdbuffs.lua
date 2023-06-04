function init()
	script.setUpdateDelta(10)
	buffList=config.getParameter("buffs",{})
	effectHandler=effect.addStatModifierGroup({})
end

function update(dt)
	local buffer={}
	for _,data in pairs(buffList) do
		local comparator
		if data.comparatorType=="stat" and data.comparator then
			comparator=status.stat(data.comparator)
		elseif data.comparatorType=="resource" and data.comparator and status.isResource(data.comparator) then
			if data.comparatorIsPercent then
				comparator=status.resourcePercentage(data.comparator)
			else
				comparator=status.resource(data.comparator)
			end
		end
		local pass=false
		if data.comparisonDirection == "eq" then --equal to
			if data.comparisonValue == comparator then
				pass=true
			end
		elseif data.comparisonDirection == "leq" then --less than or equal to
			if data.comparisonValue >= comparator then
				pass=true
			end
		elseif data.comparisonDirection == "geq" then --greater than or equal to
			if data.comparisonValue <= comparator then
				pass=true
			end
		elseif data.comparisonDirection == "gtr" then --greater than
			if data.comparisonValue < comparator then
				pass=true
			end
		elseif data.comparisonDirection == "lss" then --less than
			if data.comparisonValue > comparator then
				pass=true
			end
		elseif data.comparisonDirection == "neq" then --not equal to
			if data.comparisonValue ~= comparator then
				pass=true
			end
		end
		if pass then
			if data.buffType=="status" then
				if type(data.buff)=="string" then
					status.addEphemeralEffect(data.buff,data.buffDuration)
				elseif type(data.buff)=="table" then
					for _,v in pairs(data.buff) do
						status.addEphemeralEffect(v,data.buffDuration)
					end
				end
			elseif data.buffType=="stat" then
				if type(data.buff) == "table" then
					for _,buff in pairs(data.buff) do
						if type(data.buff)=="table" then
							table.insert(buffer,v)
						else
							sb.logWarn("thresholdbuffs.lua: buff type 'stat' used but buff subtable (%s) for %s is a string. Must be table.",buff,data.buff)
						end
					end
				else
					sb.logWarn("thresholdbuffs.lua: buff type 'stat' used but buff is a string. Must be table.")
				end
			end
		end
	end
	effect.setStatModifierGroup(effectHandler,buffer)
end

function uninit()
	effect.removeStatModifierGroup(effectHandler)
end
