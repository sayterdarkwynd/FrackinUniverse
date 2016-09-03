local contents
 
function init(args)
	if self.craftDelay == nil then
		self.craftDelay = 4
	end
	if self.honeyType == nil then
		self.honeyType = "emptyhoneyjar"
	end
end
 
 
 
function honeyCheck()
    local contents = world.containerItems(entity.id())
	self.doHoney = false
	if contents[3].name == "normalcomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "preciouscomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "junglecomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "forestcomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "morbidcomb" then
			self.honeyType = "redhoneyjar"
			self.doHoney = true
	end
	if contents[3].name == "mooncomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "coppercomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "ironcomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "silvercomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "goldcomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "titaniumcomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "aridcomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "redcomb" then
			self.honeyType = "redhoneyjar"
			self.doHoney = true
	end
	if contents[3].name == "arcticcomb" then
			self.honeyType = "snowhoneyjar"
			self.doHoney = true
	end
	if contents[3].name == "solariumcomb" then
			self.honeyType = "solariumhoneyjar"
			self.doHoney = true
	end
	if contents[3].name == "mythicalcomb" then
			self.honeyType = "mythicalhoneyjar"
			self.doHoney = true
	end
	if contents[3].name == "flowercomb" then
			self.honeyType = "floralhoneyjar"
			self.doHoney = true
	end
	if contents[3].name == "minercomb" then
			self.honeyType = "honeyjar"
			self.doHoney = true
	end
	if contents[3].name == "volcaniccomb" then
			self.honeyType = "hothoneyjar"
			self.doHoney = true
	end
	if contents[3].name == "godlycomb" then
			self.honeyType = "mythicalhoneyjar"
			self.doHoney = true
	end
	if contents[3].name == "nocturnalcomb" then
			self.honeyType = "nocturnalhoneyjar"
			self.doHoney = true
	end
	if contents[3].name == "plutoniumcomb" then
			self.honeyType = "plutoniumhoneyjar"
			self.doHoney = true
	end
	if contents[3].name == "radioactivecomb" then
			self.honeyType = "radioactivehoneyjar"
			self.doHoney = true
	end
	return self.honeyType
end
 
function update(dt)
    contents = world.containerItems(entity.id())
        if not contents[2] then
                return
        end
        if not contents[3] then
                return
        end
	if contents[3] and contents[2] then
		workingCombs()
	end
end
 
function workingCombs()
    honeyCheck()
	if self.doHoney == true then
		if self.craftDelay > 0 then
			self.craftDelay = self.craftDelay - 1
		elseif self.craftDelay <= 0 then
			self.craftDelay = 2
		end
	else
		return nil
	end
	if self.doHoney == true then 
	if self.craftDelay == 1 then
		if world.containerConsume(entity.id(), { name= contents[3].name, count = 1, data={}}) == true and
			world.containerConsume(entity.id(), { name= contents[3].name, count = 1, data={}}) == true then
				world.containerAddItems(entity.id(), { name= self.honeyType, count = 1, data={}})
		end
	else
		return
	end
	end
end