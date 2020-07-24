local FR_old_init = init

function init()
	FR_old_init()
	local species = player.species()
	local _,speciesConfig = pcall( function () return root.assetJson(string.format("/species/%s.raceeffect", species)) end )
	if speciesConfig and speciesConfig.tech then
		for _,tech in pairs(speciesConfig.tech) do
			local playerTechs = player.availableTechs()
			player.makeTechAvailable(tech)
			if #(player.availableTechs()) > #playerTechs then -- check to see if this added a tech (if not, we have it already)
				player.enableTech(tech)
				player.equipTech(tech)
			end
		end
	end
end
