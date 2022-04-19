require "/scripts/slimepersonglobalfunctions.lua"
function init()
  getSkinColorOnce=0
  script.setUpdateDelta(1)
end

function update(dt)
	if getSkinColorOnce == 0 then
		if not (world.entityType(entity.id())) then return end
		local myRace = world.entitySpecies(entity.id())
		getSkinColorOnce=1
		if myRace ~= "slimeperson" then
			animator.setLightColor("xelglow", {85,0,255})
		else
			local pass,result = pcall(world.entityPortrait,entity.id(),"full")
			if not pass then
				animator.setLightColor("xelglow", {85,0,255})
				return
			end
			local i = 1
			while i < 12 do
					if string.find(sb.printJson(result[i].image), "head") ~= nil then
						local bodyColor = sb.printJson(result[i].image)
						bodyColor = bodyColor:sub(2,-2)
						local splited = bodyColor:split("?")
						animator.setGlobalTag("skinColor", "?" .. splited[2])
						local startIndex = string.find(splited[2], "478844=")
						--sb.logInfo("%s", splited[2]:sub(startIndex + 7,startIndex + 12))
						local hexcode = "#" .. splited[2]:sub(startIndex + 7,startIndex + 12)
						hexcode = hex2rgb(hexcode)
						local rgbValues = hexcode:split(",")
						--sb.logInfo("%s",rgbValues[1] ..",".. rgbValues[2]..","..rgbValues[3])
						animator.setLightColor("xelglow", {rgbValues[1],rgbValues[2],rgbValues[3]})
						i = 13
					end
				i = i + 1
			end
		end
		script.setUpdateDelta(0)
	end
end

function uninit()
   getSkinColorOnce=0
end
