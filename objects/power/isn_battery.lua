require '/scripts/fupower.lua'
require '/scripts/util.lua'

local batteryUpdateThrottleBase=0.33

function init()
	power.init()
	power.setPower(0)
	power.setMaxEnergy(config.getParameter('isn_batteryCapacity'))
	if config.getParameter('isnStoredPower') then
		power.setStoredEnergy(config.getParameter('isnStoredPower'))
		object.setConfigParameter('isnStoredPower', nil)
	end
end

function update(dt)
	batteryUpdate(dt)
	power.update(dt)
end

function die()
	if power.getStoredEnergy() > 0 then
		local charge = power.getStoredEnergy() / power.getMaxEnergy() * 100
		local iConf = root.itemConfig(object.name())
		local newObject = { isnStoredPower = power.getStoredEnergy() }

		if iConf and iConf.config then
			-- set the border colour according to the charge level (red → yellow → green)
			if iConf.config.inventoryIcon then
				local colour

				if charge <	25 then colour = 'FF0000'
				elseif charge <	50 then colour = 'FF8000'
				elseif charge <	75 then colour = 'FFFF00'
				elseif charge < 100 then colour = '80FF00'
				else colour = '00FF00'
				end
				newObject.inventoryIcon = iConf.config.inventoryIcon .. '?border=1;' .. colour .. '?fade=' .. colour .. 'FF;0.1'
			end
			newObject.description = isn_makeBatteryDescription(iConf.config.description or '', charge,true)
		end

		world.spawnItem(object.name(), entity.position(), 1, newObject)
	else
		world.spawnItem(object.name(), entity.position())
	end
end

function isn_makeBatteryDescription(desc, charge, onDeath)
	if desc == nil then
		desc = root.itemConfig(object.name())
		desc = desc and desc.config and desc.config.description or ''
	end
	charge = charge or power.getStoredEnergy() / power.getMaxEnergy() * 100

	--[[-- bat flattery
	if charge == 0 then return desc end]]

	-- round down to multiple of 0.5 (special case if < 0.5)
	if charge < 0.5 then
		charge = '< 0.5'
	else
		charge = math.floor (charge * 2) / 2
	end

	-- append charge state to default description; ensure that it's on a line of its own
	local str=string_split(desc,"^truncate;")
	if str[1] then str=str[1] else str="" end
	str=str..((onDeath and " ^red;Scan for Info^reset;") or "\n^blue;Input 1^reset;: On/Off Switch\n^red;Output 1^reset;: Partial Power, ^red;Output 2^reset;: Full Power")
	str = str .. (desc ~= '' and "\n" or '') .. "Power Stored: ^yellow;"..util.round(power.getStoredEnergy(),1).."^reset;/^green;"..util.round(power.getMaxEnergy(),1).."^reset;J (^yellow;" .. charge .. '^reset;%)'
	return str
end

function string_split(str, pat)
	 local t = {}	-- NOTE: use {n = 0} in Lua-5.0
	 local fpat = "(.-)" .. pat
	 local last_end = 1
	 local s, e, cap = str:find(fpat, 1)
	 while s do
		if s ~= 1 or cap ~= "" then
			 table.insert(t, cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	 end
	 if last_end <= #str then
			cap = str:sub(last_end)
			table.insert(t, cap)
	 end
	 return t
end

local oldPowerRemove=power.remove
function power.remove(...)
	--local on=not object.isInputNodeConnected(0) or object.getInputNodeLevel(0)
	oldPowerRemove(...)
	batteryUpdate()
end

function batteryUpdate(dt)
	batteryUpdateThrottle=math.max(0,(batteryUpdateThrottle or batteryUpdateThrottleBase)-(dt or 0))
	local on=(not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
	power.setPower(on and power.getStoredEnergy() or 0)
	if batteryUpdateThrottle <= 0 then
		local throttleMult=(math.sqrt(#(world.objectQuery(entity.position(),16,{callScript="isFuBattery"}))))
		object.setConfigParameter('description', isn_makeBatteryDescription())
		local oldAnim
		if self.oldPowerStored then
			oldAnim=((self.oldPowerStored) == 0 and 'd' or tostring(math.floor(math.min((self.oldPowerStored) / power.getMaxEnergy(),1.0) * 10),10))
		end
		local newAnim=(power.getStoredEnergy() == 0 and 'd' or tostring(math.floor(math.min(power.getStoredEnergy() / power.getMaxEnergy(),1.0) * 10),10))
		if oldAnim~=newAnim then
			animator.setAnimationState("meter",newAnim)
		end
		self.oldPowerStored=power.getStoredEnergy()
		batteryUpdateThrottle=batteryUpdateThrottleBase*throttleMult
		--object.setOutputNodeLevel(0,self.oldPowerStored>0)
		object.setOutputNodeLevel(0,self.oldPowerStored>=power.getMaxEnergy()*0.01)
		object.setOutputNodeLevel(1,power.getStoredEnergy() >= power.getMaxEnergy())
	end
end

function isFuBattery()
	return true
end
