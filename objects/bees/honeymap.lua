function honeyCheck(comb)
	honeyMap = honeyMap or {
		arcticcomb      = "snowhoneyjar",
		aridcomb        = "honeyjar",
		coppercomb      = "honeyjar",
		durasteelcomb   = "honeyjar",
		flowercomb      = "floralhoneyjar",
		forestcomb      = "honeyjar",
		godlycomb       = "mythicalhoneyjar",
		goldcomb        = "honeyjar",
		ironcomb        = "honeyjar",
		junglecomb      = "honeyjar",
		minercomb       = "honeyjar",
		mooncomb        = "honeyjar",
		morbidcomb      = "redhoneyjar",
		mythicalcomb    = "mythicalhoneyjar",
		nocturnalcomb   = "nocturnalhoneyjar",
		normalcomb      = "honeyjar",
		plutoniumcomb   = "plutoniumhoneyjar",
		preciouscomb    = "honeyjar",
		radioactivecomb = "radioactivehoneyjar",
		redcomb         = "redhoneyjar",
		silvercomb      = "honeyjar",
--		suncomb         = "hothoneyjar",
		solariumcomb    = "solariumhoneyjar",
		titaniumcomb    = "honeyjar",
		tungstencomb    = "honeyjar",
		volcaniccomb    = "hothoneyjar",
		aegisaltcomb    = "honeyjar",
		feroziumcomb    = "honeyjar",
		violiumcomb     = "honeyjar",
		liquidwater     = "liquidwastewater",
		magmacomb       = "hothoneyjar"
	}

	local item = comb
	if not item then
		item = world.containerItems(entity.id())[self.inputSlot]
		if item then item = item.name end
	end
	return item and honeyMap[item] -- may be nil
end
