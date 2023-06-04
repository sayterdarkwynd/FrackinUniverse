function init()
	for _,tech in pairs(player.availableTechs()) do
		if tech == "doublejump" then
			--sb.logInfo("unlocking rocketboots")
			player.makeTechAvailable("furocketboots")
			break
		end
	end
	old()
end
