function init(virtual)
	if virtual then return end

	self.initialCraftDelay = config.getParameter("craftDelay")
	self.itemChances = config.getParameter("itemChances")
	self.inputSlot = config.getParameter("inputSlot")

	self.craftDelay = self.craftDelay or self.initialCraftDelay

	object.setInteractive(true)
end

function deciding(item)
	itemMap = itemMap or {
		-- item chances are between 0 and 1, and for any given comb type, the sum of the chances must not exceed 1
		arcticcomb      = { frozenwaxchunk = self.itemChances.normal },
		aridcomb        = { goldensand     = self.itemChances.common },
		coppercomb      = { copperore      = self.itemChances.rare },
		durasteelcomb   = { durasteelore   = self.itemChances.rarest },
		forestcomb      = { goldenwood     = self.itemChances.common },
		flowercomb      = { petalred       = self.itemChances.common / 3,
		                    petalyellow    = self.itemChances.common / 3,
		                    petalblue      = self.itemChances.common / 3 },
		godlycomb       = { matteritem     = self.itemChances.rare },
		goldcomb        = { goldore        = self.itemChances.rarest },
		ironcomb        = { ironore        = self.itemChances.rarest },
		junglecomb      = { goldenleaves   = self.itemChances.common },
		minercomb       = { coalore        = self.itemChances.uncommon },
		mooncomb        = { hematite       = self.itemChances.common },
		morbidcomb      = { ghostlywax     = self.itemChances.common },
		mythicalcomb    = { liquidhealing  = self.itemChances.rare },
		nocturnalcomb   = { waxchunk       = self.itemChances.common },
		normalcomb      = { waxchunk       = self.itemChances.common },
		plutoniumcomb   = { plutoniumore   = self.itemChances.rare },
		preciouscomb    = { diamond        = self.itemChances.rarest },
		radioactivecomb = { uraniumore     = self.itemChances.rare },
		redcomb         = { redwaxchunk    = self.itemChances.common },
		silkcomb        = { beesilk        = self.itemChances.uncommon },
		silvercomb      = { silverore      = self.itemChances.rarest },
		solariumcomb    = { solariumore    = self.itemChances.rare },
		suncomb         = { sulphur        = self.itemChances.rare },
		titaniumcomb    = { titaniumore    = self.itemChances.rarest },
		tungstencomb    = { tungstenore    = self.itemChances.rarest },
		volcaniccomb    = { liquidlava     = self.itemChances.uncommon }
	}
	return itemMap[item.name] -- may be nil
end

function update(dt)
	local input = world.containerItems(entity.id())[self.inputSlot]

	if input then
		local output = deciding(input)
		if output then
			workingCombs(input, output)
			animator.setAnimationState("centrifuge", "working")
		else
			animator.setAnimationState("centrifuge", "idle")
		end
	else
		animator.setAnimationState("centrifuge", "idle")
	end
end

function workingCombs(input, output)
	self.craftDelay = self.craftDelay - 1

	if self.craftDelay <= 0 then
		self.craftDelay = self.initialCraftDelay
		world.containerConsume(entity.id(), { name = input.name, count = 1, data={}})
		local rnd = math.random()

		for item, chance in pairs(output) do
			if rnd <= chance then
				local throw = world.containerAddItems(entity.id(), { name = item, count = 1, data={}})
				if throw then world.spawnItem(throw, entity.position()) end -- hope that the player or an NPC which collects items is around
				break
			end
			rnd = rnd - chance
		end
	end
end
