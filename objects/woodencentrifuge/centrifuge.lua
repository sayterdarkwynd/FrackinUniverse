local contents
 
function init(args)
	if self.craftDelay == nil then
		self.craftDelay = 2
	end
 	if itemchance == nil then 
		itemchance = 0.5
	end
	rarestitem = 0.35
	rareitem = 0.40
	uncommonitem = 0.50
	normalitem = 0.60	
	commonitem = 0.70
end
 
function deciding()
    contents = world.containerItems(entity.id())
		self.comboutput = contents[5].name
		itemchance = 1
		if contents[5].name == "godlycomb" then
			self.comboutput = "matteritem"
			itemchance = rareitem
		end
		if contents[5].name == "normalcomb" then
			self.comboutput = "waxchunk"
			itemchance = commonitem
		end
		if contents[5].name == "preciouscomb" then
			self.comboutput = "diamond"
			itemchance = rarestitem
		end
		if contents[5].name == "nocturnalcomb" then
			self.comboutput = "waxchunk"
			itemchance = commonitem
		end
		if contents[5].name == "aridcomb" then
			self.comboutput = "goldensand"
			itemchance = commonitem
		end
		if contents[5].name == "redcomb" then
			self.comboutput = "redwaxchunk"
			itemchance = commonitem
		end
		if contents[5].name == "junglecomb" then
			self.comboutput = "goldenleaves"
			itemchance = commonitem
		end
		if contents[5].name == "minercomb" then
			self.comboutput = "coalore"
			itemchance = uncommonitem
		end
		if contents[5].name == "arcticcomb" then
			self.comboutput = "frozenwaxchunk"
			itemchance = normalitem
		end
		if contents[5].name == "mythicalcomb" then
			self.comboutput = "liquidhealing"
			itemchance = rareitem
		end
		if contents[5].name == "radioactivecomb" then
			self.comboutput = "uraniumore"
			itemchance = rareitem
		end
		if contents[5].name == "plutoniumcomb" then
			self.comboutput = "plutoniumore"
			itemchance = rareitem
		end
		if contents[5].name == "solariumcomb" then
			self.comboutput = "solariumore"
			itemchance = rareitem
		end
		if contents[5].name == "suncomb" then
			self.comboutput = "sulphur"
			itemchance = rareitem
		end
		if contents[5].name == "silkcomb" then
			self.comboutput = "beesilk"
			itemchance = uncommonitem
		end
		if contents[5].name == "volcaniccomb" then
			self.comboutput = "liquidlava"
			itemchance = uncommonitem
		end
		if contents[5].name == "forestcomb" then
			self.comboutput = "goldenwood"
			itemchance = commonitem
		end
		if contents[5].name == "morbidcomb" then
			self.comboutput = "ghostlywax"
			itemchance = commonitem
		end
		if contents[5].name == "mooncomb" then
			self.comboutput = "hematite"
			itemchance = commonitem
		end
		if contents[5].name == "flowercomb" then
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
		if contents[5].name == "coppercomb" then
			self.comboutput = "copperore"
			itemchance = rareitem
		end
		if contents[5].name == "ironcomb" then
			self.comboutput = "ironore"
			itemchance = rarestitem
		end
		if contents[5].name == "silvercomb" then
			self.comboutput = "silverore"
			itemchance = rarestitem
		end
		if contents[5].name == "goldcomb" then
			self.comboutput = "goldore"
			itemchance = rarestitem
		end
		if contents[5].name == "titaniumcomb" then
			self.comboutput = "titaniumore"
			itemchance = rarestitem
		end
		if contents[5].name == "tungstencomb" then
			self.comboutput = "tungstenore"
			itemchance = rarestitem
		end
		if contents[5].name == "durasteelcomb" then
			self.comboutput = "durasteelore"
			itemchance = rarestitem
		end		
end
 
function update(dt)
        contents = world.containerItems(entity.id())
        if not contents[5] then
				entity.setAnimationState("centrifuge", "idle")
                return
        end
	if contents[5] then
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
		world.containerConsume(entity.id(), { name= contents[5].name, count = 1, data={}})
		if math.random(100)/100 <= itemchance then
			world.containerAddItems(entity.id(), { name= self.comboutput, count = 1, data={}})
		end
	else
		return
	end
end