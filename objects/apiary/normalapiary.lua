local contents
 
function init(args)
		animator.setAnimationState("bees", "off")
        if not self.spawnDelay or not contents then
                self.spawnDelay = 1.00			 -- A global spawn rate multiplier. Higher is slower.
                self.spawnBeeBrake = 200      -- Individual spawn rates
                self.spawnItemBrake = 125	  --
                self.spawnHoneyBrake = 150   --
                self.spawnDroneBrake = 150   --
				self.honeyModifier = 0		-- modifiers for frames, higher means faster production
				self.itemModifier = 0		--
				self.beeModifier = 0		--
				self.droneModifier = 0		--
				self.mutationIncrease = 0   --
                reset()
        end
		

end
 
 
function reset()   ---When bees are not present, this sets a slightly increased timer for when bees are added again.
        self.spawnBeeCooldown = self.spawnBeeBrake * 2
        self.spawnItemCooldown = self.spawnItemBrake * 2
        self.spawnHoneyCooldown = self.spawnHoneyBrake * 2
        self.spawnDroneCooldown = self.spawnDroneBrake * 2
        self.beePower = 0
        contents = world.containerItems(entity.id())
end
 
 function frame()
	contents = world.containerItems(entity.id())
		
		
--- Check the type of frame. Adjust variables-------------		
	if contents[19] then
		if contents[19].name == "basicframe" then
				self.honeyModifier = 15	---A basic reduction to the number of times the apiary has to reduce a cooldown to spawn honey.
				return
		end		                        ---A 600 cooldown, with 30 beepower, is now reduced to a 570 cooldown. 30 beepower = 60 reduced per second, or 9.5 seconds, instead of 10.
		if contents[19].name == "sweetframe" then
				self.honeyModifier = 25
				return
		end
		if contents[19].name == "provenframe" then
				self.itemModifier = 15
				return
		end
		if contents[19].name == "durasteelframe" then
				self.itemModifier = 25
				return
		end
		if contents[19].name == "scentedframe" then
				self.beeModifier = -6000000
				self.honeyModifier = 25
				return
		end
		if contents[19].name == "uraniumframe" then
				self.mutationIncrease = 0.04
				radiatebees = true
				return
		end
		if contents[19].name == "plutoniumframe" then
				self.mutationIncrease = 0.08
				radiatebees = true
				return
		end
		if contents[19].name == "bees_royalframe" then
				self.beeModifier = 60
				return
		end
		if contents[19].name == "feroziumframe" then
				self.droneModifier = 15
				self.beeModifier = 15
				return
		end
		if contents[19].name == "solarframe" then
			whatTimeOfDay = 1
				return
		end
		if contents[19].name == "eclipseframe" then
			whatTimeOfDay = 2
				return
		end
		if contents[19].name == "copperframe" then
			coppercombs = true
				return
		end
		if contents[19].name == "silverframe" then
			silvercombs = true
				return
		end
		if contents[19].name == "goldframe" then
			goldcombs = true
				return
		end
		if contents[19].name == "diamondframe" then
			preciouscombs = true
				return
		end
		if contents[19].name == "ironframe" then
			ironcombs = true
			return
		end
		if contents[19].name == "titaniumframe" then
			titaniumcombs = true
			return
		end
	end
	

end

function equipped(queen,drone)  ---Apiaries function faster with more drones. 64 drones work just over twice as effecient as 1 drone. (well, exactly (13/6) times)
        contents = world.containerItems(entity.id())
        -- -- log("equipped(" .. queen .. "," .. drone .. ")")
        -- does no matter in which slot the queen or the drone is
		local spawnArea = world.entityPosition(entity.id())
		if contents[17] and contents[18] then
        if contents[17].name == queen and contents[18].name == drone then
                -- log("FOUND BY QUEEN")
                self.beePower = math.ceil(math.sqrt(contents[18].count) + 10)  ---Beepower = cooldown reduction rate. At 500ms scriptDelta, and with 20 beePower, it takes 5 seconds to reduce a 200 cooldown to 0.
				return true
        end
        if contents[18].name == queen and contents[17].name == drone then
                -- log("FOUND BY DRONE")
                self.beePower = math.ceil(math.sqrt(contents[17].count) + 10)  ---Queens dont affect beePower. You can only fit 1 anyway.
				return true
				
        end
        return false
	end
end		

function equippedBees(queen,drone)
        if not drone then
                drone = queen
        end
        -- -- log("equippedBees(" .. queen .. "," .. drone .. ")")
        local q = queen .. "queen"
        local d = drone .. "drone"
        if equipped(q,d) then 
			return true 
		end
        local q = drone .. "queen"
        local d = queen .. "drone"
        if equipped(q,d) then 
			return true 
		end
        return false
end

function trySpawnBee(chance,type,amount)        -- tries to spawn bees if we haven't in this round
        type = type .. "bee"   ---Type is normally things "normal" or "bone", as the code inputs them in workingBees() or breedingBees(), this function uses them to spawn bee monsters. "normalbee" for example.
        amount = amount or 1        -- chance is a float value between 0.00 (will never spawn) and 1.00 (will always spawn)
        if self.doBees and math.random(100)/100 <= chance then      ---math.random(100)/100 allows me to set spawns to anything from 0.00 to 1.00, so chance has to be in that range.
                while amount>0 do
                        world.spawnMonster(type, object.toAbsolutePosition({ 2, 3 }), { level = 1 })
                        amount = amount - 1
                end
                self.doBees = false
        end
end
 
function trySpawnMutantBee(chance,type,amount)
        type = type .. "bee"
        amount = amount or 1
        if self.doBees and math.random(100)/100 <= ( chance + self.mutationIncrease ) then
                while amount>0 do
                        world.spawnMonster(type, object.toAbsolutePosition({ 2, 3 }), { level = 1 })
                        amount = amount - 1
                end
                self.doBees = false
        end
end
 

function droneStarter()   ---Spawn more drones in newer apiaries.               -- Drone QTY:  1-40       41-80
	if contents[17] and contents[18] then 										-- Spawn QTY:  +2         +1     (This adds to the function trySpawnDrone: amount)																		
		local beeQuanity = ((contents[17].count + contents[18].count) - 1)      -- I subtracted 1 since the queen inflates the total. Keep in mind either slot could be drones, easiest to add them and then subtract.
		
		if beeQuanity < 81 then 
			droneBonus = math.ceil((81 - beeQuanity) / 40)
			return true
		elseif beeQuanity > 200 then
			droneReduce = true
		else
			droneReduce = false
		end
		return false
	end
end


function trySpawnDrone(chance,type,amount)
		droneBonus = 0
		droneStarter()
        amount = (math.random(2) + droneBonus)
			if self.doDrone and math.random(100)/100 <= chance then
					world.containerAddItems(entity.id(), { name=type .. "drone", count = amount, data={}})
					self.doItems = false
				if droneReduce == true then
					world.containerConsume(entity.id(), {name =type .. "drone", count = math.random(5), data={}})
				end
			end
end


function trySpawnItems(chance,type,amount)
        -- analog to trySpawnBee() for items (like goldensand)
        amount = amount or 1
        if self.doItems and math.random(100)/100 <= chance then
                world.containerAddItems(entity.id(), { name=type, count = amount, data={}})
                self.doItems = false
        end
end


function trySpawnMutantDrone(chance,type,amount)
        amount = amount or 1
				if self.doDrone and math.random(100)/100 <= ( chance + self.mutationIncrease ) then
						world.containerAddItems(entity.id(), { name=type .. "drone", count = amount, data={}})
						self.doItems = false
				end
end
 
function trySpawnHoney(chance,honeyType,amount)
		if not self.doHoney then return nil end  --if the apiary isn't spawning honey, do nothing
		amount = amount or 1  --- if not specified, just spawn 1 honeycomb.
		local flowerIds = world.objectQuery(entity.position(), 25, {name="beeflower", order="nearest"})  --find all flowers within range
 
		if (math.random(100) / (100 + ( #flowerIds * 3 )) ) <= chance then   --- The more flowers in range, the more likely honey is to spawn. Honey still spawns 1 at a time, at the same interval
			world.containerAddItems(entity.id(), { name=honeyType .. "comb", count = amount, data={}})
			self.doHoney = false
		end
end


function expellQueens(type)   ---Checks how many queens are in the apiary, either under the first or second bee slot, and removes all but 1. The rest will be dropped on the ground. Only functions when the apiary is working.
        contents = world.containerItems(entity.id())
		local queenLocate = type .. "queen"  ---Input the used bee type, and create a string such as "normal" .. "queen" = "normalqueen"
		
		if contents[17].name == queenLocate then	---is queen in slot17? (Top bee slot)
			if contents[17].count > 1 then			---how many queens, exactly?
				local queenname = contents[17].name		---sets the variable queenname to be use for queen removal
				local queenremoval = (contents[17].count - 1) ---How many queens are we removing?
				world.containerConsume(entity.id(), {name = queenname, count = queenremoval, data={}})  ---PEACE OUT, YA QUEENS
				world.spawnItem(queenname, object.toAbsolutePosition({ 1, 2 }), queenremoval)			--- Oh, hi. Why are you on the ground? SHE THREW YOU OUT? THAT BITCH!
			end
		elseif contents[18].name == queenLocate then  --is queen in slot18? (Bottom bee slot), here we go again....
			if contents[18].count > 1 then
				local queenname = contents[18].name
				local queenremoval = (contents[18].count - 1)
				world.containerConsume(entity.id(), {name = queenname, count = queenremoval, data={}})
				world.spawnItem(queenname, object.toAbsolutePosition({ 1, 2 }), queenremoval)
			end
		end
end


function spawnHoneyDronesBees(type)  ---condenses the functions that every breeding bee uses, to save space.
    trySpawnHoney(0.60, type)
    trySpawnBee(  0.40, type)			---Some randomization is added by the 0.35 chance of spawn.
    trySpawnDrone(0.40, type)
	expellQueens(type)  -- bitches this be MY house. (Kicks all queens but 1 out of the apiary)
end


function beeSting()
	-- sb.logInfo("Apiary: Aggressive bees trying to sting")
	if math.random(5) == 1 then
	-- sb.logInfo("Apiary: STING!")
	world.spawnProjectile("stingstatusprojectile", entity.position(), entity.id())
	end
end


function flowerCheck()
	local flowerObject1 = world.objectQuery(entity.position(), 80, {name="giantflower1"})
	local flowerObject2 = world.objectQuery(entity.position(), 80, {name="giantflower2"})
	local flowerObject3 = world.objectQuery(entity.position(), 80, {name="giantflower3"})
	local flowerObject4 = world.objectQuery(entity.position(), 80, {name="giantflower4"})
	local flowerObject5 = world.objectQuery(entity.position(), 80, {name="springbush1"})
	local flowerObject6 = world.objectQuery(entity.position(), 80, {name="springbush2"})
	local flowerObject7 = world.objectQuery(entity.position(), 80, {name="springbush3"})
	local flowerObject8 = world.objectQuery(entity.position(), 80, {name="springbush4"})
	local flowerObject9 = world.objectQuery(entity.position(), 80, {name="springbush5"})
	local flowerObject10 = world.objectQuery(entity.position(), 80, {name="springbush6"})
	local flowerRed = world.objectQuery(entity.position(), 80, {name="flowerred"})
	local flowerYellow = world.objectQuery(entity.position(), 80, {name="floweryellow"})
	local flowerBlue = world.objectQuery(entity.position(), 80, {name="flowerblue"})
	local flowerBlack = world.objectQuery(entity.position(), 80, {name="flowerblack"})
	local flowerBrown = world.objectQuery(entity.position(), 80, {name="flowerbrown"})
	local flowerGreen = world.objectQuery(entity.position(), 80, {name="flowergreen"})	
	local flowerGrey = world.objectQuery(entity.position(), 80, {name="flowergrey"})
	local flowerOrange = world.objectQuery(entity.position(), 80, {name="flowerorange"})
	local flowerOrchid = world.objectQuery(entity.position(), 80, {name="flowerorchid"})	
	local flowerOrchid2 = world.objectQuery(entity.position(), 80, {name="flowerorchid2"})
	local flowerOrchid3 = world.objectQuery(entity.position(), 80, {name="flowerorchid3"})
	local flowerPink = world.objectQuery(entity.position(), 80, {name="flowerpink"})	
	local flowerPurple = world.objectQuery(entity.position(), 80, {name="flowerpurple"})
	local flowerWhite = world.objectQuery(entity.position(), 80, {name="flowerwhite"})
	local flowerSpring = world.objectQuery(entity.position(), 80, {name="flowerspring"})
	local FFenergiflower = world.objectQuery(entity.position(), 80, {name="energiflowerseed"})   ----Frackin Flora/Universe 'Flowers'
	local FFfloralytplant = world.objectQuery(entity.position(), 80, {name="floralytplantseed"})
	local FFgoldenglow = world.objectQuery(entity.position(), 80, {name="goldenglowseed"})	
	local FFhaleflower = world.objectQuery(entity.position(), 80, {name="haleflowerseed"})	
	local FFita = world.objectQuery(entity.position(), 80, {name="itaseed"})
	local FFniss = world.objectQuery(entity.position(), 80, {name="nissseed"})
	local FFwubstem = world.objectQuery(entity.position(), 80, {name="wubstemseed"})
	local FFmiraclegrassseed = world.objectQuery(entity.position(), 80, {name="miraclegrassseed"}) 
	local FFvanusflowerseed = world.objectQuery(entity.position(), 80, {name="vanusflowerseed"}) 
	local FFbeeflower = world.objectQuery(entity.position(), 80, {name="beeflower"})
	
	local noFlowersYet = self.beePower 			---- Check the initial "beePower" before flowers...
	if flowerObject1 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerObject1) / 2)
	end
	if flowerObject2 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerObject2) / 2)
	end
	if flowerObject3 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerObject3) / 2)
	end	
	if flowerObject4 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerObject4) / 2)
	end	
	if flowerObject5 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerObject5) / 2)
	end	
	if flowerObject6 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerObject6) / 2)
	end	
	if flowerObject7 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerObject7) / 2)
	end	
	if flowerObject8 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerObject8) / 2)
	end	
	if flowerObject9 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerObject9) / 2)
	end
	if flowerObject10 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerObject10) / 2)
	end	
	if flowerRed ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerRed) / 2)
	end
	if flowerYellow ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerYellow) / 2)
	end
	if flowerBlue ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerBlue) / 2)
	end
	if flowerSpring ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end
	
	
	---FrackinUniverse---
	if flowerBlack ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end	
	if flowerBrown ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end	
	if flowerGreen ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end	
	if flowerGrey ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end
	if flowerOrange ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end	
	if flowerOrchid ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end
	if flowerOrchid2 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end
	if flowerOrchid3 ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end
	if flowerPink ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end
	if flowerPurple ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end
	if flowerWhite ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#flowerSpring) / 2)
	end	
	if FFenergiflower ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#FFenergiflower) / 2)
	end
	if FFfloralytplant ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#FFfloralytplant) / 2)
	end
	if FFgoldenglow ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#FFgoldenglow) / 2)
	end
	if FFhaleflower ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#FFhaleflower) / 2)
	end
	if FFita ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#FFita) / 2)
	end
	if FFniss ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#FFniss) / 2)
	end
	if FFwubstem ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#FFwubstem) / 2)
	end
	if FFmiraclegrassseed ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#FFmiraclegrassseed) / 2)
	end
	if FFvanusflowerseed ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#FFvanusflowerseed) / 2)
	end	
	if FFbeeflower ~= nil then	
		self.beePower = self.beePower + math.ceil(math.sqrt(#FFbeeflower) / 2)
	end
	
	if self.beePower == noFlowersYet then
		self.beePower = -1				--- If there are no flowers for the bees... they can't do anything.
		animator.setAnimationState("bees", "off")
		elseif self.beePower >= 60 then
		self.beePower = 60
	end
end


function deciding()
        if self.beePower == -1 then   ---if the apiary doesn't have bees, then stop.
                return
        end
		
        -- counting down and looking for events like spawning a bee, an item or honey
        -- also applies the effects if something has to spawn (increasing cooldown, slowing things down)
        if self.spawnBeeCooldown <= 0 then
                self.spawnBeeBrake = self.spawnBeeBrake * 2    	---each time a bee is spawned, the next bee takes longer, unless the world reloads. (Reduce Lag)
                self.doBees = true
                self.spawnBeeCooldown = ( self.spawnBeeBrake * self.spawnDelay ) - self.honeyModifier   ----these self.xModifiers reduce the cooldown by a static amount, only increased by frames.
        else
                self.doBees = false
                self.spawnBeeCooldown = self.spawnBeeCooldown - math.ceil( self.beePower )      ---beepower sets how much the cool down reduces each tick.
        end
		
        if self.spawnDroneCooldown <= 0 then
                self.spawnDroneBrake = self.spawnDroneBrake + 10
                self.doDrone = true
                self.spawnDroneCooldown = ( self.spawnDelay * self.spawnDroneBrake ) - self.droneModifier
        else
                self.doDrone = false
                self.spawnDroneCooldown = self.spawnDroneCooldown - math.ceil( self.beePower )
        end
 
        if self.spawnItemCooldown <= 0 then
                self.spawnItemBrake = self.spawnItemBrake + 10
                self.doItems = true
                self.spawnItemCooldown = ( self.spawnDelay * self.spawnItemBrake ) - self.itemModifier
        else
                self.doItems = false
                self.spawnItemCooldown = self.spawnItemCooldown - self.beePower
        end
		
        if self.spawnHoneyCooldown <= 0 then
                self.spawnHoneyBrake = self.spawnHoneyBrake + 10
                self.doHoney = true
                self.spawnHoneyCooldown = ( self.spawnDelay * self.spawnHoneyBrake ) - self.honeyModifier
        else
                self.doHoney = false
                self.spawnHoneyCooldown = self.spawnHoneyCooldown - self.beePower
        end
end

function miteInfection()   ---Random mite infection.
---see if the container has room for more mites
	local vmiteFitCheck = 	world.containerItemsCanFit(entity.id(), { name= "vmite", count = 1, data={}})
---see if the container is infected with mites
	local vmiteInfectedCheck = 	world.containerConsume(entity.id(), { name= "vmite", count = 1, data={}})
	

	
		---initial infection. with a 500ms polling rate, this runs at once per 60 minutes per apiary, an infection should happen.
		---The previous comment doesn't actually make sense. It's not your imagination. -renbear
		if math.random(1000) < 6 then
			if vmiteFitCheck == true then
				world.containerAddItems(entity.id(), { name="vmite", count = 64, data={}})
			end
		end

		if contents[19] and contents[19].name == "amite" then  		---Infection stops spreading if the frame is the anti-mite frame.
			world.containerConsume(entity.id(), { name= "vmite", count = 10, data={}})
			world.containerConsume(entity.id(), { name= "vmite", count = 5, data={}})
			world.containerConsume(entity.id(), { name= "vmite", count = 2, data={}})
			world.containerConsume(entity.id(), { name= "vmite", count = 1, data={}})
		elseif vmiteInfectedCheck == true then 
			world.containerAddItems(entity.id(), { name="vmite", count = 31, data={}})
			world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
			world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
			world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
			world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
			world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
			world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
			self.beePower = -1
			animator.setAnimationState("bees", "off")
			return
		end	
end

function daytimeCheck()
		if world.timeOfDay() < 0.50 then
			whatTimeOfDay = 1
			else
			whatTimeOfDay = 2
		end
		if contents[19] then
			if contents[19].name == "solarframe" then       ---temp fix
				whatTimeOfDay = 1
			end
			if contents[19].name == "eclipseframe" then
				whatTimeOfDay = 2
			end
		end
		if whatTimeOfDay == 2 then
			if beeNocturnalDiurnal == "diurnal" then
				animator.setAnimationState("bees", "off")
			end
			if beeNocturnalDiurnal == "nocturnal" then
				animator.setAnimationState("bees", "on")
			end
		end
		if whatTimeOfDay == 1 then
			if beeNocturnalDiurnal == "nocturnal" then
				animator.setAnimationState("bees", "off")
			end
			if beeNocturnalDiurnal == "diurnal" then
				animator.setAnimationState("bees", "on")
			end
		end
end

function amendBeeName()
	local removeDrone1 = string.gsub(contents[17].name, "drone", "")  	 ----remove "drone" from the item name and set a variable
	bee1Type = string.gsub(removeDrone1, "queen", "")				 ----remove "queen" from the item name and set a variable
	---one time for each slot. (Queen and Drone)
	local removeDrone2 = string.gsub(contents[18].name, "drone", "")
	bee2Type = string.gsub(removeDrone2, "queen", "")		
end

function update(dt)
	contents = world.containerItems(entity.id())
	daytimeCheck()
	flowerCheck()
	frame()   ---Checks to see if a frame in installed. Must take place after daytimeCheck for eclipse frames.
		
        if not contents[17] or not contents[18] then
                -- removing bees will reset the timers
                if self.beePower ~= 0 then
                        reset()
						frame()
                else
				animator.setAnimationState("bees", "off")
                end
                return
        end
		
    deciding()
		
        if not self.doBees and not self.doItems and not self.doHoney and not self.doDrone then
                -- no need to search for the bees if there is nothing to do with them
                self.beePower = 0  --sets beePower to 0 to prevent storing an old value.
                if self.beePower ~= 0 then
                    return
                end
        end
		
	miteInfection()		--- Try to spawn mites.
		
        if not workingBees() then   
		-- If bees aren't a match, check to see if the bee types are meant for breeding.
                breedingBees()
        end
end
 
function workingBees()
	if whatTimeOfDay == 1 then
			if equippedBees("normal") then					--NORMAL
                spawnHoneyDronesBees("normal")
				beeNocturnalDiurnal = "diurnal"					
                return true -- no need to check for other bees
			end
			if equippedBees("arid") then					--ARID
                spawnHoneyDronesBees("arid")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("miner") then					--BORING
                spawnHoneyDronesBees("miner")
				beeNocturnalDiurnal = "diurnal"	
				if coppercombs == true then
					trySpawnHoney(1, "copper")
				end
				if silvercombs == true then
					trySpawnHoney(1, "silver")
				end
				if goldcombs == true then
					trySpawnHoney(1, "gold")
				end
				if preciouscombs == true then
					trySpawnHoney(1, "precious")
				end
				if ironcombs == true then
					trySpawnHoney(1, "iron")
				end
				if titaniumcombs == true then
					trySpawnHoney(1, "titanium")
				end
				if radiatebees == true then
					trySpawnMutantBee(  0.16, "radioactive")
					trySpawnMutantDrone(0.12, "radioactive")
				end
				return true
			end
			if equippedBees("exceptional") then					--EXCEPTIONAL
			    trySpawnHoney(0.80, "normal")
				trySpawnBee(  0.40, "exceptional")
				trySpawnDrone(0.40, "exceptional")
                trySpawnItems(0.40, "fu_liquidhoney")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("flower") then					--FLOWER
                spawnHoneyDronesBees("flower")
                trySpawnItems(0.25, "beeflower")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("forest") then					--FOREST
                spawnHoneyDronesBees("forest")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("jungle") then					--JUNGLE
                spawnHoneyDronesBees("jungle")
                trySpawnItems(0.70, "plantfibre")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("mythical") then					--MYTHICAL
                spawnHoneyDronesBees("mythical")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("plutonium") then					--PLUTONIUM
                spawnHoneyDronesBees("plutonium")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("radioactive") then					--RADIOACTIVE
                spawnHoneyDronesBees("radioactive")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("red") then					--RED
                spawnHoneyDronesBees("red")
                trySpawnItems(0.20, "redwaxchunk")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("aggressive") then					--AGGRESSIVE
			    trySpawnHoney(0.80, "red")
				trySpawnBee(  0.40, "aggressive")
				trySpawnDrone(0.40, "aggressive")
				trySpawnItems(0.10, "alienmeat")
				expellQueens("aggressive")
				beeNocturnalDiurnal = "diurnal"	
				beeSting()
                return true
			end
			if equippedBees("metal") then					--METAL (FrackinUniverse addition)
			    trySpawnHoney(0.80, "red")
				trySpawnBee(  0.33, "metal")
				trySpawnDrone(0.33, "metal")
				trySpawnItems(0.33, "tungstenore")
				expellQueens("metal")
				beeNocturnalDiurnal = "diurnal"	
				beeSting()
                return true
			end			
			if equippedBees("morbid") then					--Morbid
                spawnHoneyDronesBees("morbid")
				trySpawnItems(0.60, "ghostlywax")
				beeNocturnalDiurnal = "diurnal"	
				beeSting()
                return true
			end
			if equippedBees("hunter") then					--HUNTER
			    trySpawnHoney(0.50, "silk")
				trySpawnBee(  0.40, "hunter")
				trySpawnDrone(0.40, "hunter")
				beeNocturnalDiurnal = "diurnal"	
				expellQueens("hunter")
                return true
			end

			if equippedBees("solarium") then					--SOLARIUM
                spawnHoneyDronesBees("solarium")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("adaptive") then					--Adaptive
			    trySpawnHoney(0.80, "normal")
				trySpawnBee(  0.40, "adaptive")
				beeNocturnalDiurnal = "diurnal"	
				trySpawnDrone(0.40, "adaptive")
				expellQueens("adaptive")
                return true
			end

			if equippedBees("hardy") then					--HARDY
			    trySpawnHoney(0.80, "normal")
				trySpawnBee(  0.40, "hardy")
				trySpawnDrone(0.40, "hardy")		
				beeNocturnalDiurnal = "diurnal"	
				expellQueens("hardy")
                return true
			end
			if equippedBees("godly") then					--GODLY
                spawnHoneyDronesBees("godly")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("volcanic") then					--VOLCANIC
                spawnHoneyDronesBees("volcanic")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			
			if equippedBees("sun") then					--SUN
                spawnHoneyDronesBees("sun")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("arctic") then					--arctic
                spawnHoneyDronesBees("arctic")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
			if equippedBees("arid") then					--DESERT BEE DONT GIVE A $#@% BOUT CLIMATE
                spawnHoneyDronesBees("arid")
                trySpawnItems(0.30, "goldensand")
				beeNocturnalDiurnal = "diurnal"	
                return true
			end
	end
		
--- In case temp gets added back to Starbound. (Everything Bees)-----------------------------------------------------------------
		-- ... huh? -renbear
----- Nocturnal Bees ------
	if whatTimeOfDay == 2 then	
			if equippedBees("moon") then					--MOON
                spawnHoneyDronesBees("moon")
				beeNocturnalDiurnal = "nocturnal"
                return true
			end
			if equippedBees("nocturnal") then					--NOCTURNAL
                spawnHoneyDronesBees("nocturnal")
				beeNocturnalDiurnal = "nocturnal"
                return true
			end
	end
	return false -- we do not have found a match yet, returning false so we can run breedingBees() in main()
end
 
function breedingBees()
	beeComboList = {["normalforest"] = "hardy",	["forestnormal"] = "hardy",
					["arcticvolcanic"] = "adaptive",	["volcanicarctic"] = "adaptive",
					["hardyadaptive"] = "exceptional",	["adaptivehardy"] = "exceptional",
					["aridadaptive"] = "miner",	["adaptivearid"] = "miner",
					["jungleadaptive"] = "hunter",	["adaptivejungle"] = "hunter",
					["hunterred"] = "aggressive",	["redhunter"] = "aggressive",
					["aggressivenocturnal"] = "morbid",	["nocturnalaggressive"] = "morbid",
					["radioactivehardy"] = "plutonium",	["hardyradioactive"] = "plutonium",
					["plutoniumexceptional"] = "solarium",	["exceptionalplutonium"] = "solarium",
					["forestjungle"] = "flower",	["jungleforest"] = "flower",
					["flowernormal"] = "red",	["normalflower"] = "red",
					["flowerhardy"] = "red",	["hardyflower"] = "red",
					["flowerexceptional"] = "mythical",	["exceptionalflower"] = "mythical",
					["minernocturnal"] = "moon",	["nocturnalminer"] = "moon",
					["moonsolarium"] = "sun",	["solariummoon"] = "sun",
					["sunmythical"] = "godly",	["mythicalsun"] = "godly",
					["metalsun"] = "mythical",
				}
	
	amendBeeName()   ----removes queen and drone from the item names. equippedBees() also does this, but this function is a simple version.
	local speciesFinder = (bee1Type .. bee2Type)
	if whatTimeOfDay == 1 then
		if beeComboList[speciesFinder] ~= nil then   ---If we still have a result...
			animator.setAnimationState("bees", "on")
			trySpawnHoney(0.2, "normal") 
			trySpawnMutantBee(  0.25, beeComboList[speciesFinder])  
			trySpawnMutantDrone(0.20, beeComboList[speciesFinder]) 
			expellQueens(bee1Type) 
			expellQueens(bee2Type)	
			beeNocturnalDiurnal = "diurnal"
			return true
		end
	end
	beeNocturnalDiurnal = "unknown"	
	animator.setAnimationState("bees", "off")
    self.beePower = -1
	return false
end	