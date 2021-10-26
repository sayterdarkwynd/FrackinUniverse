require "/scripts/util.lua"
require "/scripts/epoch.lua"
require "/scripts/vec2.lua"
require "/scripts/effectUtil.lua"
require "/scripts/fuPersistentEffectRecorder.lua"

function init()
	-- passive research gain
	self.threatBonus=0
	self.madnessResearchBonus = 0
	self.researchBonus = 0

	self.researchCount = player.currency("fuscienceresource")
	self.protheonCount = player.currency("fuprecursorresource")/10
	if self.protheonCount > 10 then -- protheon bonus never surpasses 100 in calculations (+10, as we use protheonCount / 10)
		self.protheonCount = 10
	end
	self.madnessCount = player.currency("fumadnessresource")
	self.geneCount = player.currency("fugeneticmaterial")

	self.baseVal = config.getParameter("baseValue") or 1
	self.timerCounter = 0
	self.environmentTimer = 0

	self.timer = 10.0 -- was zero, instant event on plopping in. giving players a short grace period. some of us teleport around a LOT.
	local buffer=status.activeUniqueStatusEffectSummary()
	for _,v in pairs(buffer) do
		if buffer[1]=="mad" then
			status.removeEphemeralEffect("mad")
			status.addEphemeralEffect("mad",self.timer)
			break
		end
	end
	self.player = entity.id()
	math.randomseed(util.seedTime())
	self.randEvent = math.random(1,100)
	self.timerDegrade = math.random(1,12)
	self.degradeTotal = 0
	self.bonusTimer = 1

    storage.crazycarrycooldown=math.max(storage.crazycarrycooldown or 0,10.0)

  
	--make sure the annoying sounds dont flood
	status.removeEphemeralEffect("partytime5madness")
	status.removeEphemeralEffect("partytime5")
	status.removeEphemeralEffect("partytime4madness")
	status.removeEphemeralEffect("partytime4")
	status.removeEphemeralEffect("partytime3")
	status.removeEphemeralEffect("partytime2")

	self.paintTimer = 0

	self.playerId = entity.id()
	self.maxMadnessValue = 15000--also defined in the relevant currency config
	self.madnessPercent = math.min(self.madnessCount / self.maxMadnessValue,1.0)

	self.barName = "madnessBar"
	self.barColor = {250,0,250,125}
	self.timerReloadBar = 0
	self.timerRemoveAmmoBar = 0

	local elementalTypes=root.assetJson("/damage/elementaltypes.config")
	local buffer={}


	--storage.armorSetData=storage.armorSetData or {}--moved into a separate setup
	fuPersistentEffectRecorder.init()

	for element,data in pairs(elementalTypes) do
		if data.resistanceStat then
			buffer[data.resistanceStat]=true
		end
	end
	self.resistList={}
	for stat,_ in pairs(buffer) do
		table.insert(self.resistList,stat)
	end
	status.setPersistentEffects("madnessAFKPenalty",{})

	checkInitGap()
end

function indexOf(t,v1)
	local index=0
	local counter=0
	for _,v2 in pairs(t) do
		counter=counter+1
		if v1==v2 then
			index=counter
			break
		end
	end
	return index
end

function forceInts(inTable)
	if type(inTable)~="table" then return end
	local buffer={}
	for k,v in pairs(inTable) do
		buffer[k]=tonumber(v)
	end
	return buffer
end

function streakCheck(val)
	val=tonumber(val)
	if not storage.streakTable then
		storage.streakTable={}
		table.insert(storage.streakTable,val)
		return false
	end
	storage.streakTable=forceInts(storage.streakTable)
	if val <= 0 then
		return false
	end

	--I wish I could use a better method
	local index=indexOf(storage.streakTable,val)

	if index>0 then
		return true
	else
		table.insert(storage.streakTable,val)
		while (#storage.streakTable)>5 do
			table.remove(storage.streakTable,1)
		end
		return false
	end
end

function randomEvent()
	if not self.madnessCount then init() end
	status.setPersistentEffects("madnessEffectsMain",{})--reset persistent effects the next time one pops up.
	self.currentPrimary = world.entityHandItem(entity.id(), "primary") --what are we carrying in the right hand?
	self.currentSecondary = world.entityHandItem(entity.id(), "alt") --what are we carrying in the left hand?

	self.isProtectedRandVal =(math.random(1,100)) / 100
	self.currentProtection = status.stat("mentalProtection")
	self.currentProtectionAbs=math.abs(self.currentProtection)

	local didRng=false
	local worldIsEphemeral=world.getProperty("ephemeral")
	local isPositiveEffect=math.random()>=0.75 --using a global roll for many effects, some (multires) are still separate

	while (not didRng) or streakCheck(math.max(0,self.randEvent)) do
		self.randEvent=math.random(1,100)
		--mentalProtection can make it harder to be affected
		if (self.currentProtectionAbs>0.0) and (self.isProtectedRandVal <= self.currentProtectionAbs) then
			self.randEvent = math.max(0,self.randEvent - util.round(self.currentProtection * 10)) --math.random(10,70) --it doesnt *remove* the effect, it just moves it further up (or down) the list, and potentially off of it.
		end
		didRng=true
	end

	-- are we currently carrying any really weird stuff?
	local carryWeird=isWeirdStuff(self.timer)

	--set duration of curse
	self.curseDuration = math.min(self.timer,self.madnessCount / 5)--this value will be adjusted based on effect type. Clamping this because it's too much otherwise. --highest duration (285.71) is reached at 1428.57. duration at max madness: 150.
	--at 15k madness, that's 15000/5, or 1000 seconds. 16.6~ mins.
	--with 0 madness resistance, self.timer will be 150. What this results in is a steady growth, followed by a petering off curve as effect frequency increases.
	--Effects will be more frequent, and more potent overall, as madness increases. This implements a bit of a ceiling on how bad it can get.
	--graph for overall data: https://www.desmos.com/calculator/jl2nvqulrb --y=\min(\max(\max(10,(300.0-(x/100))),10),x/5), ignoring resistance
	self.curseDuration_status = self.curseDuration * 2 --caps at 571.42. at max madness: 300
	self.curseDuration_annoy = self.curseDuration * 1.2 --caps at 342.5. at max madness: 180
	self.curseDuration_resource = self.curseDuration * 2.2 --caps at 628.57. at max madness: 330
	self.curseDuration_stat = self.curseDuration * 2.5 --caps at 714.28. at max madness: 375
	self.curseDuration_fast = self.curseDuration * 0.25 --caps at 71.42. at max madness: 37.5
	status.removeEphemeralEffect("mad")
	status.addEphemeralEffect("mad",self.timer)

	--[[if self.randEvent < 0 then --failsafe
		self.randEvent = 0
	end]]
	if self.madnessCount > 1500 then
		if self.randEvent == 44 then
			status.addEphemeralEffect("eatself",self.curseDuration_fast/2) -- You just can't stop eating yourself.
			status.addEphemeralEffect("healingimmunitydummy",self.curseDuration_fast/2) -- healing won't work on you
			if status.isResource("food") then
				status.addEphemeralEffect("convert_food-health_100_1-10_lethal",self.curseDuration_fast/2) -- So hungry...
				status.addEphemeralEffect("feedpackneg",self.curseDuration_fast/2)-- hunger isn't abating so fast.
			else
				status.addEphemeralEffect("heal_neg20",self.curseDuration_fast/2) -- It gnaws at you.
			end
		elseif self.randEvent == 45 then
			status.addEphemeralEffect("runboost15",self.curseDuration_status) -- run boost!
		elseif self.randEvent == 46 then
			player.radioMessage("madnesscat") -- completely harmless, purely to confuse
		end
	end
	if self.madnessCount > 1000 then
		if (self.randEvent >= 40) and (self.randEvent <= 42) then
			if (not isPositiveEffect) and (not worldIsEphemeral) then
				local enabledtechs=player.enabledTechs()
				if (self.randEvent == 40 and contains(enabledtechs,"distortionsphere")) then --swap sphere tech
					player.equipTech("distortionsphere")
				elseif self.randEvent == 41 and contains(enabledtechs,"doublejump") then --swap jump tech
					player.equipTech("doublejump")
				elseif self.randEvent == 42 and contains(enabledtechs,"dash") then --swap dash tech
					player.equipTech("dash")
				end
			else
				if self.randEvent == 40 then
					status.setPersistentEffects("madnessEffectsMain", {{stat = "mentalProtection", amount = 0.5 }}) --temporary protection from madness
					self.timerDegradePenalty = 2
				elseif self.randEvent == 41 then
					status.addEphemeralEffect("bouncy",self.curseDuration_status) -- boing.
					self.timerDegradePenalty = 2
				elseif self.randEvent == 42 then
					status.addEphemeralEffect("runboost10",self.curseDuration_status) -- run boost!
					self.timerDegradePenalty = 2
				end
			end
		elseif self.randEvent == 43 then
			if isPositiveEffect then
				status.setPersistentEffects("madnessEffectsMain", {{stat = "researchBonus", amount = 1 }})
				player.radioMessage("sanitygainboost")
			else
				player.consumeCurrency("fuscienceresource", 1)
				player.radioMessage("sanitygain")
			end
		end
	end
	if self.madnessCount > 750 then
		if self.randEvent == 37 and self.madnessCount > 800 then
			if (self.currentPrimary and root.itemHasTag(self.currentPrimary, "dagger")) or (self.currentSecondary and root.itemHasTag(self.currentSecondary, "dagger")) then --if holding a knife, cut yourself
				if (not isPositiveEffect) then
					status.addEphemeralEffect("bleeding05",self.curseDuration_status) -- You just can't stop stabbing yourself
					player.radioMessage("madnessharm")
				else
					status.addEphemeralEffect("regeneration5madness",self.curseDuration_status*0.5) -- You stab yourself, and now you're healing
					player.radioMessage("madnessharminvert")
				end
			else
				self.timerDegradePenalty = 10
			end
		elseif self.randEvent == 38 and self.madnessCount > 800 then
			status.addEphemeralEffect("runboost10",self.curseDuration_status) -- run boost!
			self.timerDegradePenalty = 2
		elseif self.randEvent == 39 and self.madnessCount > 900 then
			status.addEphemeralEffect("rootfu",10*((isPositiveEffect and 0.25) or 1.0)) -- unable to move
			player.radioMessage("madnessroot")
		elseif self.randEvent == 53 then
			--local penaltyValue = math.random(1,100)/100 --while we could make it apply this to all of them, it's better to apply it randomly to all of them!
			local buffer={}
			for _,stat in pairs(self.resistList) do
				table.insert(buffer,{stat=stat,amount=((math.random()>0.75 and 1) or (-1))*(math.random(1,20)/100.0)}) --still, needed to reduce the maximum range to reasonable levels. also added a chance for a bonus
			end
			status.setPersistentEffects("madnessEffectsMain", buffer)
			--same problem as the 'pick random resist' debuff.
		end
	end
	if self.madnessCount > 500 then
		if self.randEvent == 30 then
			if not isPositiveEffect then
				status.addEphemeralEffect("percentarmorboostneg"..tostring(math.random(1,5)),self.curseDuration_status)--randomly get a penalty multiplier of 0.9 to 0.5 for defense
			else
				local eList={"","10","15","30"}
				status.addEphemeralEffect("percentarmorboost"..eList[math.random(1,#eList)],self.curseDuration_status) --armor up!
			end
		elseif self.randEvent == 31 then
			if isPositiveEffect then
				status.addEphemeralEffect("wellfed")
			else
				status.addEphemeralEffect("feedpackneg",self.curseDuration_status) --more hunger
				status.removeEphemeralEffect("wellfed")
			end
			player.radioMessage("madnessfood")
		elseif self.randEvent == 32 then
			status.addEphemeralEffect("runboostdebuff",self.curseDuration_status) -- run boost!
			player.radioMessage("madness2")
		elseif self.randEvent == 33 then
			status.addEphemeralEffect("swimboost2",self.curseDuration_status) -- Swim boost2!
		elseif self.randEvent == 34 then
			if player.isLounging() then
				if not isPositiveEffect then
					status.addEphemeralEffect("burning",self.curseDuration_status)--your ass is on fire.
					player.radioMessage("madnesscombust")
				end
			else
				if isPositiveEffect and player.hasCountOfItem("molotov") then
					player.consumeItem("molotov", true, false)
					effectUtil.effectAllEnemiesInRange("burning",16,self.curseDuration_fast*0.1) -- their ass is on fire.
					player.radioMessage("madnesscombustinvert")
				end
			end
		elseif self.randEvent == 35 then
			if not isPositiveEffect then
				status.addEphemeralEffect("fu_nooxygen",self.curseDuration_status) -- You have forgotten how to breathe
			else
				status.addEphemeralEffect("airimmunity",self.curseDuration_status*0.5) -- somehow can breathe anywhere
			end
		elseif self.randEvent == 36 then
			status.addEphemeralEffect("jumpboost25neg",self.curseDuration_status) -- You suddenly suck at jumping
			player.radioMessage("madness2")
		elseif (self.randEvent >= 46 and self.randEvent <= 52) then
			status.setPersistentEffects("madnessEffectsMain", {{stat = self.resistList[math.random(1,#self.resistList)], amount = ((math.random()>0.75 and 1) or (-1))*math.random(1,20)/100.0}}) -- pick one from all available resistances, and reduce it by 1-X%
		end
	end
	if self.madnessCount > 200 then
		if self.randEvent == 11 then
			status.addEphemeralEffect("nude",self.curseDuration_status) --harmless, but silly. YOU ARE NAKEY!
		elseif self.randEvent == 12 then
			status.addEphemeralEffect("madnessslow1",self.curseDuration_status) -- old one (staffslow2) was too strong and easily cheated.
			player.radioMessage("madness2")
		elseif self.randEvent == 13 then
			status.addEphemeralEffect("toxiccloudmadness",self.curseDuration_status) -- swapped for a madness specific variant.
			status.addEphemeralEffect("madnessslow2",self.curseDuration_status)
			player.radioMessage("madnessbeans")
		elseif self.randEvent == 14 then
			status.addEphemeralEffect("loweredshadow",self.curseDuration_status) --more susceptible to shadow
		elseif self.randEvent == 15 then
			status.addEphemeralEffect("ffbiomecold0",self.curseDuration_status) --player feels cold
		elseif self.randEvent == 16 then
			status.addEphemeralEffect("jungleweathernew",self.curseDuration_status) --player feels hot
		elseif self.randEvent == 17 then
			status.addEphemeralEffect("insanity",self.curseDuration_status) --player feels insane
		elseif self.randEvent == 18 then
			status.addEphemeralEffect("madnessslow2",self.curseDuration_status) --slows the player for a while
			player.radioMessage("madness2")
		elseif self.randEvent == 19 then
			status.addEphemeralEffect("runboost5",curseDuration_fast) -- run boost 5!
		elseif self.randEvent == 20 then
			if not isPositiveEffect then
				status.addEphemeralEffect("maxhealthboostneg20",self.curseDuration_status) -- lowered health
			else
				status.addEphemeralEffect("maxhealthboost5",self.curseDuration_status) -- increases health
			end
		elseif self.randEvent == 21 then
			if not isPositiveEffect then
				status.addEphemeralEffect("maxenergyboostneg20",self.curseDuration_status) -- lowered energy
			else
				status.addEphemeralEffect("maxenergyboost3",self.curseDuration_status) -- increases energy
			end
		elseif self.randEvent == 22 then
			status.addEphemeralEffect("lowgrav_fallspeedup",curseDuration_fast) -- adjusts gravity
		elseif self.randEvent == 23 then
			status.addEphemeralEffect("slimeleech",self.curseDuration_status) -- slimeleech. ew.
		elseif self.randEvent == 24 then
			status.addEphemeralEffect("knockbackWeaknessHidden",self.curseDuration_status) -- Knockbacks affect you more
		elseif self.randEvent == 25 then
			status.addEphemeralEffect("swimboost1",self.curseDuration_status) -- Swim boost 1!
		elseif self.randEvent == 26 then
			if not isPositiveEffect then
				status.addEphemeralEffect("vulnerability",self.curseDuration_fast*((worldIsEphemeral and 0.5) or 1.0)) --vulnerability multiplies all resists and defense by 0.01, biiiig ouch. severely reducing the max duration of this.
				player.radioMessage("madnessvuln")
			else
				local dur=self.curseDuration_fast*((worldIsEphemeral and 0.5) or 1.0)*0.5
				status.addEphemeralEffect("cultistshieldAlwaysVisible",dur) --invuln
				player.radioMessage("madnessinvuln")
			end
		elseif self.randEvent == 27 then
			local val=(math.random(6,40)/100.0)
			if isPositiveEffect then
				val=1+val --random charisma buff.
			else
				val=1-val --random charisma penalty.
			end
			status.setPersistentEffects("madnessEffectsMain", {{stat = "fuCharisma", baseMultiplier = val}})
		elseif self.randEvent == 28 then
			if status.isResource("food") then
				status.removeEphemeralEffect("wellfed")
				status.setResource("food",math.random(1.0,status.stat("maxFood"))) --your current hunger is randomized
				if status.resourcePercentage("food") >= 1.0 then
					if math.random()>=0.5 then
						status.addEphemeralEffect("wellfed")
					end
				end
				player.radioMessage("madnessfood")
			else
				status.setResource("energy",math.random(1.0,status.stat("maxEnergy")))
				player.radioMessage("madnessenergy")
			end
		elseif self.randEvent == 29 then --max food reduction
			if status.isResource("food") then
				status.setPersistentEffects("madnessEffectsMain", {{stat = "maxFood", amount = -1*math.random(1,8)}})
			else
				status.addEphemeralEffect("toxiccloudmadness",self.curseDuration_status)
				status.addEphemeralEffect("madnessslow2",self.curseDuration_status)
				player.radioMessage("madnessbeans")
			end
		end
	end
	if self.madnessCount > 150 then
		if self.randEvent == 6 then
			status.addEphemeralEffect("partytime2",self.curseDuration_annoy) -- party
		elseif self.randEvent == 7 then
			status.addEphemeralEffect("partytime3",self.curseDuration_annoy) -- party
		elseif self.randEvent == 8 then
			status.addEphemeralEffect("partytime4",self.curseDuration_annoy) -- party
		elseif self.randEvent == 9 then
			status.addEphemeralEffect("partytime5",self.curseDuration_annoy) -- party
		elseif self.randEvent == 10 then
			player.addCurrency("fuscienceresource", 1)
		end
	end
	if self.madnessCount > 50 then
		if self.randEvent == 1 then
			status.addEphemeralEffect("booze",self.curseDuration_status * ((isPositiveEffect and 0.01) or 1.0)) --player feels drunk
		elseif self.randEvent == 2 then
			status.addEphemeralEffect("biomeairless",self.curseDuration_status)--annoying harmless warning
		elseif self.randEvent == 3 then
			status.addEphemeralEffect("sandstorm",self.curseDuration_status)--you farted sand
		elseif self.randEvent == 4 then
			status.setPersistentEffects("madnessEffectsMain", {{stat = "mentalProtection", amount = 0.5 }}) --temporary protection from madness
		elseif self.randEvent == 5 then
			if player.hasCountOfItem("plantfibre") then -- consume a plant fibre, just to confuse and confound
				player.consumeItem("plantfibre", true, false)
				player.radioMessage("madness1")
			end
		end
	end
end

function afkFlags()
	--[[local removingflags={30,60,120}
	for _,v in pairs(removingflags) do
		status.setStatusProperty("fu_afk_"..v.."s",nil)
	end]]

	local flags={120,240,360,720}
	for _,v in pairs(flags) do
		local isAfk=self.afkTimer and (self.afkTimer >= v)
		status.setStatusProperty("fu_afk_"..v.."s",isAfk)
	end
end

-- note that this function is reused across multiple scripts. update it here, then copypaste as needed, if modifications are made
function afkLevel()
	return ((status.statusProperty("fu_afk_720s") and 4) or (status.statusProperty("fu_afk_360s") and 3) or (status.statusProperty("fu_afk_240s") and 2) or (status.statusProperty("fu_afk_120s") and 1) or 0)
end

function update(dt)
	storage.crazycarrycooldown=math.max(0,(storage.crazycarrycooldown or 0) - dt)
	fuPersistentEffectRecorder.update(dt)
	--anti-afk concept: check vs a set of 8 points, referring to the 8 'cardinal' directions. If a person moves far enough past one of the last recorded point, the afk timer is reset.
	--if the player doesn't move enough, a timer will increment. once that timer gets over a certain point, the player is flagged as afk via status property, which is global and thus we only need this code running in one place.
	--afk timer and recorded points are reset when the script resets.
	if not self.pointBox or not self.afkCheckTimer then
		local pos=entity.position()
		if pos then
			self.pointBox={topLeft=pos,topRight=pos,bottomLeft=pos,bottomRight=pos,left=pos,right=pos,top=pos,bottom=pos}
			self.pointDirection={topLeft={-1,1},topRight={1,1},bottomLeft={-1,-1},bottomRight={1,-1},left={-1,0},right={1,0},top={0,1},bottom={0,-1}}
			self.afkCheckTimer=0.0
			self.afkTimer=0
		end
		afkFlags()
	elseif self.afkCheckTimer >= 1.0 then
		local wPos=entity.position()
		local isAfk=true
		for direction,v in pairs(self.pointDirection) do
			if world.magnitude(self.pointBox[direction],wPos) > 1.0 then
				local bufferPoint={self.pointBox[direction][1],self.pointBox[direction][2]}
				local distance=world.distance(wPos,bufferPoint)
				if (distance[1]*v[1] >= math.abs(v[1])) and (distance[2]*v[2] >= math.abs(v[2])) then
					isAfk=false
					self.pointBox[direction]=wPos
				end
			end
		end
		if isAfk then self.afkTimer=self.afkTimer+self.afkCheckTimer else self.afkTimer=0.0 end
		self.afkCheckTimer=0.0
		afkFlags()
		local afkLvl=afkLevel()
		local afkPenaltyValue=math.max(-1.0,((afkPenaltyValue and (afkLvl > 0) and (afkPenaltyValue - (afkLvl*0.001)))) or 0.0)
		status.setPersistentEffects("madnessAFKPenalty",{{stat="mentalProtection",amount=afkPenaltyValue}})
	else
		self.afkCheckTimer=self.afkCheckTimer+dt
	end
	local afkLvl=afkLevel()

	--passive research gain
	if status.statusProperty("fu_creationDate") then
		self.threatBonus=0
		self.madnessResearchBonus = 0
		self.researchBonus = 0

		if (world.threatLevel() > 1) then --if we are on a biome above tier 1, then we do things
			if (self.environmentTimer > 300) then -- has at least 5 minutes elapsed? If so, begin applying exploration bonus
				self.threatBonus = util.clamp(world.threatLevel() / 1.5,1,6) -- base calculation: threat / 1.5, then make sure its never less than 1 or greater than 6
			end
			if afkLvl<=3 then --if active, increment up to 600 (10 mins)
				self.environmentTimer = math.min(600.0,self.environmentTimer + (dt/(afkLvl+1)))
			else --if inactive, decrement at afklvl/6 rate, down to 0. at afklvl 4,current max and where this fires, that's 2/3, so it decreases by 2/3 of a second every second; it would take 15 minutes to fully decay.
				self.environmentTimer = math.max(0.0,self.environmentTimer - (dt*(afkLevel/6)))
			end
		end
		-- how crazy are we?
		if player.currency("fumadnessresource") then
			self.madnessResearchBonus = player.currency("fumadnessresource") / 4777 --3.14
			if self.madnessResearchBonus < 1 then
				self.madnessResearchBonus = 0
			end
		end
        
        --time based research increases
        -- every 30 minutes we increment it by +1. So long as the player is active, this bonus applies. Going AFK pauses it
        checkPassiveTimerBonus()
	    
		self.researchBonus = storage.timedResearchBonus + self.threatBonus + self.madnessResearchBonus

		self.bonus = self.researchBonus + (self.protheonCount) --status.stat("researchBonus") + self.researchBonus
		if self.timerCounter >= (1+afkLvl) then
			if afkLvl <= 3 then
				player.addCurrency("fuscienceresource",1 + self.bonus)
				if (math.random(1,20) + status.stat("researchBonus")) >= 18 then  -- only apply the bonus research from stat X amount of the time based on a d20 roll higher than 18. Bonus influences this.
					player.addCurrency("fuscienceresource",status.stat("researchBonus"))
				end
			end
			self.timerCounter = 0
		else
			self.timerCounter = self.timerCounter + dt
		end
	end

	-- we control the ammo bar removal from here for now, since its innocuous enough to work without interfering with update() on the player
	-- there are better places to put it, but this at least keeps it contained
	if (self.timerRemoveAmmoBar >=6) then
		world.sendEntityMessage(entity.id(),"removeBar","ammoBar")	--clear ammo bar
		self.timerRemoveAmmoBar = 0
	else
		self.timerRemoveAmmoBar = math.min(self.timerRemoveAmmoBar + dt,6.0)
	end

	self.madnessCount = player.currency("fumadnessresource")
	self.researchCount = player.currency("fuscienceresource")

	-- timing refresh for sculptures, painting effects
	self.paintTimer = math.max(0,self.paintTimer - dt)
	if self.paintTimer <= 0 then
		checkMadnessArt()
	end

	-- Core Adjustment Function
	self.timer = math.max(self.timer - dt,0.0)
	if self.timer <= 0.0 then
		if self.madnessCount > 50 then
			self.degradeTotal = self.madnessCount / 300 + (self.protheonCount)
			self.timerDegradePenalty = math.max(0.0,self.madnessCount / 500)
			self.timer = math.max(math.max(10,300.0 - (self.madnessCount/100)) + (status.stat("mentalProtection") * 100),10) --implementing a hard floor on how low the timer can go.
			randomEvent() --apply random effect
		else
			self.timer = 300.0
			self.degradeTotal = 1
		end
	end
	self.timerDegrade = math.max(self.timerDegrade - dt,0.0) - (self.protheonCount * 4)
	self.freudBonus = math.max(status.stat("freudBonus"),-0.8) -- divide by zero is bad. as this approaches -1, the timer approaches infinity. -0.5 turns the timer into 80s instead of 40s. cappin it at -0.8, which is 400s or 10x
	--gradually reduce Madness over time
	if (self.timerDegrade <= 0) then --no more limit to when it can degrade
		self.timerDegradePenalty = self.timerDegradePenalty or 0.0
		player.consumeCurrency("fumadnessresource", self.degradeTotal)
		self.timerDegrade= (60.0 - self.timerDegradePenalty) / (1.0+self.freudBonus) - (self.protheonCount)
		--displayBar()
	end
	-- apply bonus loss from anti-madness effects even if not above X madness
	self.bonusTimer = math.max(self.bonusTimer - dt,0)
	if self.bonusTimer <= 0.0 then
		self.protectionBonus = status.stat("mentalProtection")* 20 + math.random(1,12)
		if (status.statPositive("mentalProtection")) then
			player.consumeCurrency("fumadnessresource", self.protectionBonus)
		end
		self.bonusTimer = 40.0 / (1.0 + self.freudBonus)
		--displayBar()
	end
end

----------------------------------------------------------------------------------
-- passive research gain based on Play Time
function checkPassiveTimerBonus()
	-- set timer
	storage.activeTime=(storage.activeTime or 0)+1
	--sb.logInfo("storage.activeTime c %s %s",storage.activeTime,storage.lastTime)
	local afkLvl=afkLevel() -- if we arent AFK, apply the bonus
	if afkLvl <= 2 then
	    passiveRadioMessage()
	    applyPassiveBonus()
	else
		storage.timedResearchBonus = 0  -- reset bonus if AFK
    end	
end

function checkInitGap()
	--sb.logInfo("storage.activeTime a %s %s",storage.activeTime,storage.lastTime)
	local currentTime=os.time()
	storage.lastTime=storage.lastTime or currentTime
	local gap=math.abs(currentTime-storage.lastTime)
	--sb.logInfo("storage.activeTime b %s %s",storage.activeTime,storage.lastTime)
	storage.activeTime=((not (gap > 60.0)) and storage.activeTime) or 0
end

function applyPassiveBonus()	
	if storage.activeTime > 10800 then
		storage.timedResearchBonus = 3	
	elseif storage.activeTime > 7200 then
		storage.timedResearchBonus = 2
	elseif storage.activeTime > 3600 then
		storage.timedResearchBonus = 1
	else
		storage.timedResearchBonus = 0 -- reset bonus if timer is less than 30 minutes
	end
end

function passiveRadioMessage()
    if storage.activeTime == 3600 then player.radioMessage("researchBonus1") end
    if storage.activeTime == 7200 then player.radioMessage("researchBonus2") end
    if storage.activeTime == 10800 then player.radioMessage("researchBonus3") end	
end
----------------------------------------------


--display madness bar
function displayBar()
	if (self.madnessCount >= 50) then
		world.sendEntityMessage(self.playerId,"setBar","madnessBar",self.madnessPercent,self.barColor)
	else
		world.sendEntityMessage(self.playerId,"removeBar","madnessBar")
	end
end

function checkMadnessArt()
	local hasPainting=false
	local greatMadnessArt={"thehuntpainting","demiurgepainting","elderhugepainting"}
	local afkLvl=afkLevel()
	for _,art in pairs(greatMadnessArt) do
		if player.hasItem(art) then
			if afkLvl<=3 then
				player.addCurrency("fumadnessresource",5-afkLvl)
			end
			hasPainting=true
			break
		end
	end

	local madnessArt={"dreamspainting","fleshpainting","homepainting","hordepainting","nightmarepainting","theexpansepainting","thefishpainting","thepalancepainting","theroompainting","thingsinthedarkpainting","elderpainting1","elderpainting2","elderpainting3","elderpainting4","elderpainting5","elderpainting6","elderpainting7","elderpainting8","elderpainting9","elderpainting10","elderpainting11"}
	for _,art in pairs(madnessArt) do
		if player.hasItem(art) then
			if afkLvl<=3 then
				player.addCurrency("fumadnessresource",2-math.min(1,afkLvl))
			end
			hasPainting=true
			break
		end
	end

	self.paintTimer = 20.0 + (status.stat("mentalProtection") * 25)
	if hasPainting then
		checkCrazyCarry()
		status.addEphemeralEffect("madnesspaintingindicator",self.paintTimer)
	end
end

function isWeirdStuff(duration)
	local afkLvl=afkLevel()
	local weirdStuff={"faceskin","greghead","greggnog","babyheadonastick","meatpickle"}
	local hasArt=false
	for _,art in pairs(weirdStuff) do
		if player.hasItem(art) then
			if afkLvl<=3 then
				player.addCurrency("fumadnessresource", 2-math.min(1,afkLvl))
			end
			checkCrazyCarry()
			status.addEphemeralEffect("madnessfoodindicator",duration)
			hasArt=true
			break
		end
	end
	return hasArt
end

function checkCrazyCarry()
	if storage.crazycarrycooldown <= 0 then
		local epochBuffer=epoch.currentToTable()
		if epochBuffer.day~=storage.crazycarryday then
			storage.crazycarryday=epochBuffer.day
			player.radioMessage("crazycarry")
		end
		storage.crazycarrycooldown=300.0
	end
end

function uninit()
	status.setPersistentEffects("madnessEffectsMain",{})
	status.setPersistentEffects("madnessAFKPenalty",{})
	world.sendEntityMessage(self.playerId,"removeBar","madnessBar")
	storage.timedResearchBonus = 0
	storage.lastTime=os.time()
end