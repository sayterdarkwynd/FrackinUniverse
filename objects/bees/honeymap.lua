function honeyCheck(comb)
	honeyMap = honeyMap or {
		arcticcomb      = "snowhoneyjar",
		aridcomb        = "stronghoneyjar",
		coppercomb      = "honeyjar",
		durasteelcomb   = "shellhoneyjar",
		flowercomb      = "floralhoneyjar",
		forestcomb      = "greenhoneyjar",
		godlycomb       = "mythicalhoneyjar",
		goldcomb        = "speedhoneyjar",
		ironcomb        = "shellhoneyjar",
		junglecomb      = "greenhoneyjar",
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
		silvercomb      = "shellhoneyjar",
		suncomb         = "hothoneyjar",
		solariumcomb    = "solariumhoneyjar",
		titaniumcomb    = "shellhoneyjar",
		tungstencomb    = "shellhoneyjar",
		volcaniccomb    = "hothoneyjar",
		aegisaltcomb    = "shellhoneyjar",
		feroziumcomb    = "shellhoneyjar",
		violiumcomb     = "shellhoneyjar",
		liquidwater     = "liquidwastewater",
		magmacomb       = "hothoneyjar",
		eldercomb       = "elderhoneyjar"
	}

	local item = comb
	if not item then
		item = world.containerItems(entity.id())[self.inputSlot]
		if item then item = item.name end
	end
	return item and honeyMap[item] -- may be nil
end
