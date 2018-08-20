require "/stats/effects/fu_weathereffects/fuWeatherLib.lua"

function update(dt)
	if not world.breathable(entity.position()) then
		warningTimer=(warningTimer or script.updateDt()*2)-dt
		if warningTimer<=0 then
			warningTimer=fuWeatherLib.warn("biomeairlesswarning","biomeairless") and 1 or math.huge
		end
	end
end
