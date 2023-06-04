function update(dt)
	if matchingcounter == nil then
		matchingcounterlist = world.objectQuery({object.position()[1],object.position()[2]-2},1)
		for _,j in ipairs(matchingcounterlist) do
			if world.entityName(j) == "sushibeltcounterleft" then matchingcounter = j end
		end
	end
end

function die()
	if matchingcounter ~= nil then world.breakObject(matchingcounter) end
end
