local FR_old_init = init
--local FR_old_update = update

function init(...)
	if FR_old_init then FR_old_init(...) end
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

--[[
function update(...)
	if FR_old_update then FR_old_update(...) end
end
]]