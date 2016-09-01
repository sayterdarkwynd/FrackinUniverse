function honeyCheck()
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
		volcaniccomb    = "hothoneyjar"
	}

	local item = world.containerItems(entity.id())[self.inputSlot]
	return item and honeyMap[item.name] -- may be nil
end
