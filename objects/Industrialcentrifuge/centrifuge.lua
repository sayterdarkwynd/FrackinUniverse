function init(args)
	if self.craftDelay == nil then
		self.craftDelay = 0.25
	end
    entity.setInteractive(true)
 	if itemchance == nil then 
		itemchance = 0.5
	end
	rarestitem = 0.55
	rareitem = 0.65
	uncommonitem = 0.75
	normalitem = 0.85	
	commonitem = 0.95
    contents = world.containerItems(entity.id())
end
 
function deciding()
    contents = world.containerItems(entity.id())
		self.comboutput = contents[17].name
		itemchance = 1
		if contents[17].name == "godlycomb" then
			self.comboutput = "matteritem"
			itemchance = rareitem
		end
		if contents[17].name == "normalcomb" then
			self.comboutput = "waxchunk"
			itemchance = commonitem
		end
		if contents[17].name == "preciouscomb" then
			self.comboutput = "diamond"
			itemchance = rarestitem
		end
		if contents[17].name == "nocturnalcomb" then
			self.comboutput = "waxchunk"
			itemchance = commonitem
		end
		if contents[17].name == "aridcomb" then
			self.comboutput = "goldensand"
			itemchance = commonitem
		end
		if contents[17].name == "redcomb" then
			self.comboutput = "redwaxchunk"
			itemchance = commonitem
		end
		if contents[17].name == "junglecomb" then
			self.comboutput = "goldenleaves"
			itemchance = commonitem
		end
		if contents[17].name == "minercomb" then
			self.comboutput = "coalore"
			itemchance = uncommonitem
		end
		if contents[17].name == "arcticcomb" then
			self.comboutput = "frozenwaxchunk"
			itemchance = normalitem
		end
		if contents[17].name == "mythicalcomb" then
			self.comboutput = "liquidhealing"
			itemchance = rareitem
		end
		if contents[17].name == "radioactivecomb" then
			self.comboutput = "uraniumore"
			itemchance = rareitem
		end
		if contents[17].name == "plutoniumcomb" then
			self.comboutput = "plutoniumore"
			itemchance = rareitem
		end
		if contents[17].name == "solariumcomb" then
			self.comboutput = "solariumore"
			itemchance = rareitem
		end
		if contents[17].name == "suncomb" then
			self.comboutput = "sulphur"
			itemchance = rareitem
		end
		if contents[17].name == "silkcomb" then
			self.comboutput = "beesilk"
			itemchance = uncommonitem
		end
		if contents[17].name == "volcaniccomb" then
			self.comboutput = "liquidlava"
			itemchance = uncommonitem
		end
		if contents[17].name == "forestcomb" then
			self.comboutput = "goldenwood"
			itemchance = commonitem
		end
		if contents[17].name == "morbidcomb" then
			self.comboutput = "ghostlywax"
			itemchance = commonitem
		end
		if contents[17].name == "mooncomb" then
			self.comboutput = "hematite"
			itemchance = commonitem
		end
		if contents[17].name == "flowercomb" then
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
		if contents[17].name == "coppercomb" then
			self.comboutput = "copperore"
			itemchance = rareitem
		end
		if contents[17].name == "ironcomb" then
			self.comboutput = "ironore"
			itemchance = rarestitem
		end
		if contents[17].name == "silvercomb" then
			self.comboutput = "silverore"
			itemchance = rarestitem
		end
		if contents[17].name == "goldcomb" then
			self.comboutput = "goldore"
			itemchance = rarestitem
		end
		if contents[17].name == "durasteelcomb" then
			self.comboutput = "durasteelore"
			itemchance = rarestitem
		end		
		if contents[17].name == "tungstencomb" then
			self.comboutput = "tungstenore"
			itemchance = rarestitem
		end
		if contents[17].name == "titaniumcomb" then
			self.comboutput = "titaniumore"
			itemchance = rarestitem
		end
end
 
function update(dt)
        contents = world.containerItems(entity.id())
        if not contents[17] then
		animator.setAnimationState("cent", "idle") 
		return
        end
	if contents[17] then
        deciding()
		workingCombs()
		honeyCheck()
		animator.setAnimationState("cent", "working")
	else
		animator.setAnimationState("cent", "idle")
	end
end
 
function workingCombs()
	if self.craftDelay > 0 then
		self.craftDelay = self.craftDelay - 1
	elseif self.craftDelay <= 0 then
		self.craftDelay = 0.25
	end
	
	if self.craftDelay <= 1 then
		world.containerConsume(entity.id(), { name= contents[17].name, count = 1, data={}})
		if math.random(100)/100 <= itemchance then
			world.containerAddItems(entity.id(), { name= self.comboutput, count = 1, data={}})
		end
	else
		return
	end
end


function honeyCheck()
    local contents = world.containerItems(entity.id())
	if not contents[17] then
		return nil
	end
	if contents[17] and contents[17].name == "normalcomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "preciouscomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "junglecomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "forestcomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "morbidcomb" then
			honeyType = "redhoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "mooncomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "coppercomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "ironcomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "silvercomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "goldcomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "titaniumcomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "aridcomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "redcomb" then
			honeyType = "redhoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "arcticcomb" then
			honeyType = "snowhoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "solariumcomb" then
			honeyType = "solariumhoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "mythicalcomb" then
			honeyType = "mythicalhoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "flowercomb" then
			honeyType = "floralhoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "minercomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "volcaniccomb" then
			honeyType = "hothoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "godlycomb" then
			honeyType = "mythicalhoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "nocturnalcomb" then
			honeyType = "nocturnalhoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "plutoniumcomb" then
			honeyType = "plutoniumhoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "radioactivecomb" then
			honeyType = "radioactivehoneyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "tungstencomb" then
			honeyType = "honeyjar"
			return honeyType
	end
	if contents[17] and contents[17].name == "durasteelcomb" then
			honeyType = "honeyjar"
			return honeyType
	end
end
 