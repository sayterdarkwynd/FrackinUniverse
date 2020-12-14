require "/scripts/kheAA/transferUtil.lua"
require '/scripts/fupower.lua'
require '/scripts/util.lua'

function init()
	self = config.getParameter("duplicator")
	power.init()
	self.craftTime = config.getParameter("craftTime")
	storage.timer = storage.timer or self.craftTime -- making this, storage.crafting, etc. persistent so that on server terminus, nothing is lost.
	storage.timer2 = storage.timer2 or 1.0
	math.randomseed(util.seedTime())
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end

	local fuelSlot = world.containerItemAt(entity.id(),1)
	fuelSlot = fuelSlot and fuelSlot.name or ""

	local inputSlot = world.containerItemAt(entity.id(),0)
	inputSlot = inputSlot and inputSlot.name or ""

	if not self.fuel then self.fuel={} end

	if not self.fuel[fuelSlot] then
		local pass,fuelValue=pcall(root.itemConfig,fuelSlot)
		if pass and fuelValue and fuelValue.config and fuelValue.config.fuelAmount then
			fuelValue=fuelValue.config.fuelAmount
		else
			fuelValue=0
		end
		self.fuel[fuelSlot]=fuelValue
	end

	if not storage.crafting then--no point doing further comparisons unless we actually need them.
		storage.timer2=(storage.timer2 and storage.timer2 - dt) or 1.0
		if storage.timer2 > 0 then
			return
		end
		if wireCheck() then -- logic wires on? neutronium and antineutronium in?
			if self.fuel[fuelSlot] > 0 then -- fueled?
				if power.getTotalEnergy() >= config.getParameter('isn_requiredPower') then

					if contains(self.inputs,inputSlot) then
						local pass,itemOre = pcall(root.itemConfig,inputSlot)

						if pass and itemOre then
							local outputCount=1
							itemValue = itemOre.parameters.price or itemOre.config.price
							local fuelCost=itemValue/self.fuel[fuelSlot]

							if fuelCost>1 then
								local leftovers=fuelCost-math.floor(fuelCost)
								fuelCost=math.ceil(fuelCost)
								leftovers=math.random()<leftovers
								if leftovers then outputCount=outputCount+1 end
							elseif fuelCost < 1 then
								--massive fuel item. assuming fuel value of 8000 (hyddrogen core) and item price 840 (densinium bar), resulting in: 0.105
								outputCount=1.0/fuelCost
								--flipped, it becomes 9.52380952
								local leftovers=outputCount%1
								-- ~0.52
								leftovers=math.random()<leftovers
								-- ~52% chance for one more
								if leftovers then outputCount=outputCount+1 end
								fuelCost=1

							end
							if world.containerConsumeAt(entity.id(),1,fuelCost) then
								animator.setAnimationState("base", "on")
								storage.fuelTaken={}
								storage.fuelTaken.name=fuelSlot
								storage.fuelTaken.count=fuelCost
								storage.timer = self.craftTime
								storage.output = inputSlot
								storage.outputCount = outputCount
								storage.crafting = true
							end
						end
					end
				end
			end
		end
		storage.timer2=1.0
	end

	if storage.timer <= 0 then
		if storage.crafting then

			if wireCheck() and power.consume(config.getParameter('isn_requiredPower')) then -- added option for a hard abort that won't eat materials
				--local slots = getOutSlotsFor(storage.output)
				storage.output = world.containerPutItemsAt(entity.id(), {name=storage.output,count=storage.outputCount}, 4)

				if storage.output then
					storage.output=world.containerPutItemsAt(entity.id(), storage.output, 0)
				end

				if storage.output then
					world.spawnItem(storage.output, entity.position())
					storage.output=nil
				end

				storage.fuelTaken=nil
				storage.crafting = false
			else
				--if we can't get power, we just chuck the fuel back into the hopper (or on the ground). and stop animating.
				animator.setAnimationState("base", "off")
				storage.fuelTaken = world.containerPutItemsAt(entity.id(), storage.fuelTaken, 1)
				if storage.fuelTaken then
					world.spawnItem(storage.fuelTaken, entity.position())
					storage.fuelTaken=nil
				end
				--stop crafting. nil values.
				storage.output=nil
				storage.crafting=false
			end
		else
			animator.setAnimationState("base", "off")
		end
	end

	storage.timer = storage.timer - dt
	if not storage.crafting and storage.timer <= 0 then
		storage.timer = 0
	end

	power.update(dt)
end

function die()
	if storage.fuelTaken then
		world.spawnItem(storage.fuelTaken, entity.position())
		storage.fuelTaken=nil
	end
end

function wireCheck()
	--since we're only really using them here these neutronium parts got added here. can easily be moved out if needed.
	local neutronium = world.containerItemAt(entity.id(),2)
	neutronium=neutronium and (neutronium.name=="neutronium")

	local antineutronium = world.containerItemAt(entity.id(),3)
	antineutronium=antineutronium and (antineutronium.name=="antineutronium")

	return (neutronium and antineutronium) and (object.inputNodeCount() < 1 or not object.isInputNodeConnected(0) or object.getInputNodeLevel(0))
end
