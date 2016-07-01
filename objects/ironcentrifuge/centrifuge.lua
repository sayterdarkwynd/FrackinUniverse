local contents
 
function init(args)
	if self.craftDelay == nil then
		self.craftDelay = 2
	end
 	if itemchance == nil then 
		itemchance = 1
	end
	rarestitem = 0.40
	rareitem = 0.45
	uncommonitem = 0.70
	normalitem = 0.80	
	commonitem = 0.90
end
 
 
 
function deciding()
    contents = world.containerItems(entity.id())
		self.comboutput = contents[10].name
		itemchance = 1
		if contents[10].name == "godlycomb" then
			self.comboutput = "matteritem"
			itemchance = rareitem
		end
		if contents[10].name == "normalcomb" then
			self.comboutput = "waxchunk"
			itemchance = commonitem
		end
		if contents[10].name == "preciouscomb" then
			self.comboutput = "diamond"
			itemchance = rarestitem
		end
		if contents[10].name == "nocturnalcomb" then
			self.comboutput = "waxchunk"
			itemchance = commonitem
		end
		if contents[10].name == "aridcomb" then
			self.comboutput = "goldensand"
			itemchance = commonitem
		end
		if contents[10].name == "redcomb" then
			self.comboutput = "redwaxchunk"
			itemchance = commonitem
		end
		if contents[10].name == "junglecomb" then
			self.comboutput = "goldenleaves"
			itemchance = commonitem
		end
		if contents[10].name == "minercomb" then
			self.comboutput = "coalore"
			itemchance = uncommonitem
		end
		if contents[10].name == "arcticcomb" then
			self.comboutput = "frozenwaxchunk"
			itemchance = normalitem
		end
		if contents[10].name == "mythicalcomb" then
			self.comboutput = "liquidhealing"
			itemchance = rareitem
		end
		if contents[10].name == "radioactivecomb" then
			self.comboutput = "uraniumore"
			itemchance = rareitem
		end
		if contents[10].name == "plutoniumcomb" then
			self.comboutput = "plutoniumore"
			itemchance = rareitem
		end
		if contents[10].name == "solariumcomb" then
			self.comboutput = "solariumore"
			itemchance = rareitem
		end
		if contents[10].name == "suncomb" then
			self.comboutput = "sulphur"
			itemchance = rareitem
		end
		if contents[10].name == "silkcomb" then
			self.comboutput = "beesilk"
			itemchance = uncommonitem
		end
		if contents[10].name == "volcaniccomb" then
			self.comboutput = "liquidlava"
			itemchance = uncommonitem
		end
		if contents[10].name == "forestcomb" then
			self.comboutput = "goldenwood"
			itemchance = commonitem
		end
		if contents[10].name == "morbidcomb" then
			self.comboutput = "ghostlywax"
			itemchance = commonitem
		end
		if contents[10].name == "mooncomb" then
			self.comboutput = "hematite"
			itemchance = commonitem
		end
		if contents[10].name == "flowercomb" then
			if math.random(3) == 1 then
				self.comboutput = "petalred"
				itemchance = commonitem
			end
			if math.random(3) == 2 then
				self.comboutput = "petalyellow"
				itemchance = commonitem
			end
			if math.random(3) == 3 then
				self.comboutput = "petalblue"
				itemchance = commonitem
			end
		end
		if contents[10].name == "coppercomb" then
			self.comboutput = "copperore"
			itemchance = rareitem
		end
		if contents[10].name == "ironcomb" then
			self.comboutput = "ironore"
			itemchance = rarestitem
		end
		if contents[10].name == "silvercomb" then
			self.comboutput = "silverore"
			itemchance = rarestitem
		end
		if contents[10].name == "goldcomb" then
			self.comboutput = "goldore"
			itemchance = rarestitem
		end
		if contents[10].name == "titaniumcomb" then
			self.comboutput = "titaniumore"
			itemchance = rarestitem
		end
		if contents[10].name == "tungstencomb" then
			self.comboutput = "tungstenore"
			itemchance = rarestitem
		end		
		if contents[10].name == "durasteelcomb" then
			self.comboutput = "durasteelore"
			itemchance = rarestitem
		end
end
 
function update(dt)
        contents = world.containerItems(entity.id())
        if not contents[10] then
				entity.setAnimationState("centrifuge", "idle")
                return
        end
	if contents[10] then
        deciding()
		workingCombs()
		entity.setAnimationState("centrifuge", "working")
	end
end
 
function workingCombs()
	if self.craftDelay > 0 then
		self.craftDelay = self.craftDelay - 1
	elseif self.craftDelay <= 0 then
		self.craftDelay = 2
	end
	
	if self.craftDelay == 1 then
		world.containerConsume(entity.id(), { name= contents[10].name, count = 1, data={}})
		if math.random(100)/100 <= itemchance then
			world.containerAddItems(entity.id(), { name= self.comboutput, count = 1, data={}})
		end
	else
		return
	end
end