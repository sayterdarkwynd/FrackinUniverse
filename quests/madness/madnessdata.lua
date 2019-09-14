require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  storage.madnessCount = player.currency("fumadnessresource") or 0
  self.timer = 0
  self.player = entity.id()
  self.randEvent = math.random(1,100) --only pick this on init so that effect changes on reloads only
  self.timerDegrade = math.random(1,12)
  self.degradeTotal = 0
  self.bonusTimer = 1
  
  status.removeEphemeralEffect("partytime5")--make sure the annoying sounds dont flood
  status.removeEphemeralEffect("partytime4")
  status.removeEphemeralEffect("partytime3")
  status.removeEphemeralEffect("partytime2")
  
  self.paintTimer = 0
end

function randomEvent()
    storage.currentPrimary = world.entityHandItem(entity.id(), "primary")  --what are we carrying?
    storage.currentSecondary = world.entityHandItem(entity.id(), "alt")  --what are we carrying?
    self.isProtectedRand = math.random(1,100)
    self.isProtectedRandVal = self.isProtectedRand / 100
    self.currentProtection = status.stat("mentalProtection") or 0
    --mentalProtection can make it harder to be affected
    if (status.statPositive("mentalProtection")) and (self.isProtectedRandVal <= status.stat("mentalProtection")) then 
      self.randEvent = self.randEvent - (self.currentProtection * 10) --math.random(10,70)  --it doesnt *remove* the effect, it just moves it further up the list, and potentially off of it.
    end
    
    -- are we currently carrying any really weird stuff? 
    isWeirdStuff()
    
    --set duration of curse
    self.curseDuration = storage.madnessCount / 5  --this value will be adjusted based on effect type
    self.curseDuration_status = self.curseDuration * 2
    self.curseDuration_annoy = self.curseDuration * 1.2
    self.curseDuration_resource = self.curseDuration * 2.2	
    self.curseDuration_stat = self.curseDuration * 2.5
    self.curseDuration_fast = self.curseDuration *0.25
    status.addEphemeralEffect("mad",60)

    if self.randEvent < 0 then  --failsafe
      self.randEvent = 0
    end
    
    if storage.madnessCount > 1500 then
	    if self.randEvent == 44 then 
		status.addEphemeralEffect("eatself",20) -- You just can't stop eating yourself.
		status.addEphemeralEffect("bleeding05",20) -- You just can't stop eating yourself.
	    end  
	    if self.randEvent == 45 then 
		status.addEphemeralEffect("runboost15",self.curseDuration_status) -- run boost!
	    end   
    elseif storage.madnessCount > 1000 then
		if self.randEvent == 40 or self.randEvent == 41 or self.randEvent == 42 then
			local enabledtechs=player.enabledTechs()
			if self.randEvent == 40 and enabledtechs:contains("distortionsphere") then --swap tech
				player.equipTech("distortionsphere")
			end      
			if self.randEvent == 41 and enabledtechs:contains("doublejump") then --swap tech
				player.equipTech("doublejump")
			end   
			if self.randEvent == 42 and enabledtechs:contains("dash") then --swap tech
				player.equipTech("dash")
			end  
		end
 	    if self.randEvent == 43 then
 	      player.consumeCurrency("fuscienceresource", 1) 
 	      player.radioMessage("sanitygain")
	    end      
    elseif storage.madnessCount > 750 then
	    if self.randEvent == 37 and storage.madnessCount > 800 then --if holding a knife, cut yourself
	      if root.itemHasTag(storage.currentPrimary, "dagger") or root.itemHasTag(storage.currentSecondary, "dagger") then
		status.addEphemeralEffect("bleeding05",self.curseDuration_status) -- You just can't stop stabbing yourself
		player.radioMessage("madnessharm")
	      end
	    end   
	    if self.randEvent == 38 and storage.madnessCount > 800 then 
		status.addEphemeralEffect("runboost10",self.curseDuration_status) -- run boost!
		self.timerDegradePenalty = 2
	    end  
	    if self.randEvent == 39 and storage.madnessCount > 900 then 
		status.addEphemeralEffect("rootfu",10) -- unable to move
		player.radioMessage("madnessroot")
	    end       
	    if self.randEvent == 53 then --max food reduction
	      local penaltyValue = math.random(1,100)/100
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "cosmicResistance", amount = status.stat("cosmicResistance")-penaltyValue },
			{stat = "radioactiveResistance", amount = status.stat("radioactiveResistance")-penaltyValue },
			{stat = "shadowResistance", amount = status.stat("shadowResistance")-penaltyValue },
			{stat = "electricResistance", amount = status.stat("electricResistance")-penaltyValue },
			{stat = "poisonResistance", amount = status.stat("poisonResistance")-penaltyValue },
			{stat = "iceResistance", amount = status.stat("iceResistance")-penaltyValue },
			{stat = "fireResistance", amount = status.stat("fireResistance")-penaltyValue }
		  })    
	    end 
    elseif storage.madnessCount > 500 then
	    if self.randEvent == 30 then
	      local penaltyValue = math.random(1,20)
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "protection", amount = status.stat("protection")-penaltyValue }
		  })    
	    end 
	    if self.randEvent == 31 then --increased hunger
		status.addEphemeralEffect("feedpackneg",self.curseDuration_status) --player feels hot
		player.radioMessage("madnessfood")
	    end      
	    if self.randEvent == 32 then 
		status.addEphemeralEffect("runboostdebuff",self.curseDuration_status) -- run boost!
		player.radioMessage("madness2")
	    end      
	    if self.randEvent == 33 then 
		status.addEphemeralEffect("swimboost2",self.curseDuration_status) -- Swim boost2!
	    end 

	    if self.randEvent == 34 then 
	      if player.isLounging() then
		status.addEphemeralEffect("burning",self.curseDuration_status)
		player.radioMessage("combust")
	      end
	    end  
	    if self.randEvent == 35 then 
		status.addEphemeralEffect("fu_nooxygen",self.curseDuration_status) -- You have forgotten how to breathe
	    end  
	     if self.randEvent == 36 then 
		status.addEphemeralEffect("jumpboost25neg",self.curseDuration_status) -- You suddenly suck at jumping
		player.radioMessage("madness2")
	    end         
	    if self.randEvent == 46 then --max food reduction
	      local penaltyValue = math.random(1,100)/100
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "fireResistance", amount = status.stat("fireResistance")-penaltyValue }
		  })    
	    end  
	    if self.randEvent == 47 then --max food reduction
	      local penaltyValue = math.random(1,100)/100
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "iceResistance", amount = status.stat("iceResistance")-penaltyValue }
		  })    
	    end  
	    if self.randEvent == 48 then --max food reduction
	      local penaltyValue = math.random(1,100)/100
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "poisonResistance", amount = status.stat("poisonResistance")-penaltyValue }
		  })    
	    end  
	    if self.randEvent == 49 then --max food reduction
	      local penaltyValue = math.random(1,100)/100
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "electricResistance", amount = status.stat("electricResistance")-penaltyValue }
		  })    
	    end
	    if self.randEvent == 50 then --max food reduction
	      local penaltyValue = math.random(1,100)/100
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "shadowResistance", amount = status.stat("shadowResistance")-penaltyValue }
		  })    
	    end 
	    if self.randEvent == 51 then --max food reduction
	      local penaltyValue = math.random(1,100)/100
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "radioactiveResistance", amount = status.stat("radioactiveResistance")-penaltyValue }
		  })    
	    end 
	    if self.randEvent == 52 then --max food reduction
	      local penaltyValue = math.random(1,100)/100
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "cosmicResistance", amount = status.stat("cosmicResistance")-penaltyValue }
		  })    
	    end 	 
    elseif storage.madnessCount > 200 then
	    if self.randEvent == 11 then 
		status.addEphemeralEffect("nude",self.curseDuration_status)
	    end   
	    if self.randEvent == 12 then 
		status.addEphemeralEffect("staffslow2",self.curseDuration_status)
	    end      
	    if self.randEvent == 13 then 
		status.addEphemeralEffect("toxiccloud",self.curseDuration)
	    end
	    if self.randEvent == 14 then 
		status.addEphemeralEffect("loweredshadow",self.curseDuration_status) --more succeptible to shadow
	    end
	    if self.randEvent == 15 then 
		status.addEphemeralEffect("ffbiomecold0",self.curseDuration_status) --player feels cold
	    end
	    if self.randEvent == 16 then 
		status.addEphemeralEffect("jungleweathernew",self.curseDuration_status) --player feels hot
	    end
	    if self.randEvent == 17 then 
		status.addEphemeralEffect("insanity",self.curseDuration_status) --player feels insane
	    end
	    if self.randEvent == 18 then 
		status.addEphemeralEffect("slow",self.curseDuration_status) --slows the player for a while
		player.radioMessage("madness2")
	    end  
	    if self.randEvent == 19 then 
		status.addEphemeralEffect("runboost5",curseDuration_fast) -- run boost!
	    end     
	    if self.randEvent == 20 then 
		status.addEphemeralEffect("maxhealthboostneg20",self.curseDuration_status) -- lowered health
	    end
	    if self.randEvent == 21 then 
		status.addEphemeralEffect("maxenergyboostneg20",self.curseDuration_status) -- lowered energy
	    end
	    if self.randEvent == 22 then 
		status.addEphemeralEffect("lowgrav_fallspeedup",curseDuration_fast) -- adjusts gravity
	    end
	    if self.randEvent == 23 then 
		status.addEphemeralEffect("slimeleech",self.curseDuration_status) -- slimeleech. ew.
	    end  	    
	    if self.randEvent == 24 then 
		status.addEphemeralEffect("knockbackWeaknessHidden",self.curseDuration_status) -- Knockbacks affect you more
	    end 
	    if self.randEvent == 25 then 
		status.addEphemeralEffect("swimboost1",self.curseDuration_status) -- Swim boost!
	    end  	
	    if self.randEvent == 26 then 
		status.addEphemeralEffect("vulnerability",self.curseDuration_status) --player feels drunk
	    end 	    
	    if self.randEvent == 27 then 
	      local penaltyValue = math.random(6,40)
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "fuCharisma", amount = status.stat("fuCharisma")-penaltyValue }
		  })
	    end  
	    if self.randEvent == 28 then --your hunger total is random
		    if status.isResource("food") then
		       local randHunger = math.random(1,70)+2
		       status.setResource("food",randHunger)
		    end  
		    player.radioMessage("madnessfood")
	    end  
	    if self.randEvent == 29 then --max food reduction
	      local penaltyValue = math.random(1,8)
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "maxFood", amount = status.stat("maxFood")-penaltyValue }
		  })    
	    end  	   
	    
    elseif storage.madnessCount > 150 then
	    if self.randEvent == 6 then 
		status.addEphemeralEffect("partytime2",self.curseDuration_annoy)
	    end 
	    if self.randEvent == 7 then 
		status.addEphemeralEffect("partytime3",self.curseDuration_annoy)
	    end 
	    if self.randEvent == 8 then 
		status.addEphemeralEffect("partytime4",self.curseDuration_annoy)
	    end  
	    if self.randEvent == 9 then 
		status.addEphemeralEffect("partytime5",self.curseDuration_annoy)
	    end 
	    if self.randEvent == 10 then
	      player.addCurrency("fuscienceresource", 1) 
	    end    	  
    elseif storage.madnessCount > 50 then
	    if self.randEvent == 1 then 
		status.addEphemeralEffect("booze",self.curseDuration_status) --player feels drunk
	    end 
	    if self.randEvent == 2 then 
		status.addEphemeralEffect("biomeairless",self.curseDuration_status)
	    end   	    
	    if self.randEvent == 3 then 
		status.addEphemeralEffect("sandstorm",self.curseDuration_status)
	    end  
	    if self.randEvent == 4 then --temporary protection from madness
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "mentalProtection", amount = status.stat("mentalProtection") + 0.5 }
		  })    
	    end 	    
	    if self.randEvent == 5 then 
		if player.hasCountOfItem("plantfibre")  then -- consume a plant fibre, just to confuse and confound
			player.consumeItem("plantfibre", true, false)
			player.radioMessage("madness1")
		end      
	    end    
    end
    

    
    
    
    self.randEvent = math.random(1,100)
end

function update(dt)

   storage.madnessCount = player.currency("fumadnessresource")
   self.paintTimer = self.paintTimer - 1
   if self.paintTimer == 0 then
     checkMadnessArt()
   end
   
  -- Core Adjustments Functions
  self.timer = self.timer - 1
  
  --debug
  --sb.logInfo("timer = "..self.timer)
  --sb.logInfo("degrade = "..self.degradeTotal)
  
  if self.timer < 1 then 
  	  if storage.madnessCount > 12000 then
	        storage.madnessCount = 12000
	        self.timer = 10
	        randomEvent()
		self.degradeTotal = 32
		self.timerDegradePenalty = 10   
  	  elseif storage.madnessCount > 10000 then
	        storage.madnessCount = 10000
	        self.timer = 10
	        randomEvent()
		self.degradeTotal = 22
		self.timerDegradePenalty = 10 
  	  elseif storage.madnessCount > 8000 then
		self.timer = 20
		randomEvent() --apply random effect
		self.timerDegradePenalty = 9
		self.degradeTotal = 16
  	  elseif storage.madnessCount > 6000 then
		self.timer = 25
		randomEvent() --apply random effect
		self.timerDegradePenalty = 8
		self.degradeTotal = 6 
  	  elseif storage.madnessCount > 5000 then
		self.timer = 30
		randomEvent() --apply random effect
		self.timerDegradePenalty = 7
		self.degradeTotal = 5
  	  elseif storage.madnessCount > 4000 then
		self.timer = 40
		randomEvent() --apply random effect
		self.timerDegradePenalty = 6
		self.degradeTotal = 4  
  	  elseif storage.madnessCount > 3000 then
		self.timer = 50
		randomEvent() --apply random effect
		self.timerDegradePenalty = 5
		self.degradeTotal = 3
  	  elseif storage.madnessCount > 2000 then
		self.timer = 60
		randomEvent() --apply random effect
		self.timerDegradePenalty = 4
		self.degradeTotal = 2  
  	  elseif storage.madnessCount > 1000 then
		self.timer = 80
		randomEvent() --apply random effect
		self.timerDegradePenalty = 3
		self.degradeTotal = 2 	   
  	  elseif storage.madnessCount > 700 then
		self.timer = 90
		self.degradeTotal = 1
		self.timerDegradePenalty = 2
		randomEvent() --apply random effect    
  	  elseif storage.madnessCount > 500 then
		self.timer = 100
		self.degradeTotal = 1
		self.timerDegradePenalty = 2
		randomEvent() --apply random effect
  	  elseif storage.madnessCount > 400 then
		self.timer = 120
		self.degradeTotal = 1
		self.timerDegradePenalty = 1
		randomEvent() --apply random effect 
  	  elseif storage.madnessCount > 300 then
		self.timer = 150
		self.degradeTotal = 1
		self.timerDegradePenalty = 1
		randomEvent() --apply random effect	
  	  elseif storage.madnessCount > 200 then
		self.timer = 200
		self.degradeTotal = 1
		randomEvent() --apply random effect  
  	  elseif storage.madnessCount > 100 then
		self.timer = 250
		self.degradeTotal = 1
		randomEvent() --apply random effect 
  	  elseif storage.madnessCount > 50 then
		self.timer = 300
		self.degradeTotal = 1
		randomEvent() --apply random effect
	  else
		self.timer = 300
		self.degradeTotal = 1	  
	  end	  
	  
	  
  end
  -- end CORE

 	self.timerDegrade = self.timerDegrade -1
 	--gradually reduce Madness over time
	if (self.timerDegrade <= 0) and (storage.madnessCount >= 50) then --high madness is harder to hold onto, and less farmable, if it always reduces
	    self.timerDegradePenalty = self.timerDegradePenalty or 0
	    player.consumeCurrency("fumadnessresource", self.degradeTotal)
	    self.timerDegrade= 30 - self.timerDegradePenalty        
	end 
 	-- apply bonus loss from anti-madness effects even if not above 500 madness
	self.bonusTimer = self.bonusTimer -1
	if self.bonusTimer <= 0 then
	    self.protectionBonus = status.stat("mentalProtection")/5 + math.random(1,12) -- 1d12 + their Mental Protection / 5
	    --mentalProtection can make it harder to be affected
	    if (status.statPositive("mentalProtection")) then 
	      player.consumeCurrency("fumadnessresource", self.protectionBonus)   
	    end
	    self.bonusTimer = 20
	end	


end

function checkMadnessArt()
    if player.hasItem("demiurgepainting") then
	player.addCurrency("fumadnessresource", 2) 
	player.giveItem("fumadnessresource")
    end    
    if player.hasItem("dreamspainting") then
	player.addCurrency("fumadnessresource", 2) 
    end    
    if player.hasItem("fleshpainting") then
	player.addCurrency("fumadnessresource", 2) 
    end           
    if player.hasItem("homepainting") then
	player.addCurrency("fumadnessresource", 2) 
    end           
    if player.hasItem("hordepainting") then
	player.addCurrency("fumadnessresource", 2) 
    end           
    if player.hasItem("nightmarepainting") then
	player.addCurrency("fumadnessresource", 2) 
    end           
    if player.hasItem("theexpansepainting") then
	player.addCurrency("fumadnessresource", 2) 
    end    
    if player.hasItem("thefishpainting") then
	player.addCurrency("fumadnessresource", 2) 
    end         
    if player.hasItem("thehuntpainting") then
	player.addCurrency("fumadnessresource", 5) 
    end         
    if player.hasItem("thepalancepainting") then
	player.addCurrency("fumadnessresource", 2) 
    end         
    if player.hasItem("theroompainting") then
	player.addCurrency("fumadnessresource", 2) 
    end         
    if player.hasItem("thingsinthedarkpainting") then
	player.addCurrency("fumadnessresource", 2) 
    end         
    if player.hasItem("elderhugepainting") then
	player.addCurrency("fumadnessresource", 5) 
    end         
    if player.hasItem("elderpainting1") then
	player.addCurrency("fumadnessresource", 2) 
    end         
    if player.hasItem("elderpainting2") then
	player.addCurrency("fumadnessresource", 2) 
    end  
    if player.hasItem("elderpainting3") then
	player.addCurrency("fumadnessresource", 2) 
    end           
    if player.hasItem("elderpainting4") then
	player.addCurrency("fumadnessresource", 2) 
    end           
    if player.hasItem("elderpainting5") then
	player.addCurrency("fumadnessresource", 2) 
    end           
    if player.hasItem("elderpainting6") then
	player.addCurrency("fumadnessresource", 2) 
    end    
    if player.hasItem("elderpainting7") then
	player.addCurrency("fumadnessresource", 2) 
    end                   
    if player.hasItem("elderpainting8") then
	player.addCurrency("fumadnessresource", 2) 
    end            
    if player.hasItem("elderpainting9") then
	player.addCurrency("fumadnessresource", 2) 
    end           
    if player.hasItem("elderpainting10") then
	player.addCurrency("fumadnessresource", 2) 
    end       
    if player.hasItem("elderpainting11") then
	player.addCurrency("fumadnessresource", 2) 
    end
    
    self.paintTimer = 20
end

function isWeirdStuff()
    if player.hasItem("faceskin") then
	player.addCurrency("fumadnessresource", 2) 
    end
    if player.hasItem("greghead") then
	player.addCurrency("fumadnessresource", 2) 
    end
    if player.hasItem("gregnog") then
	player.addCurrency("fumadnessresource", 2) 
    end    
    if player.hasItem("babyheadonastick") then
	player.addCurrency("fumadnessresource", 2) 
    end
    if player.hasItem("greghead") then
	player.addCurrency("fumadnessresource", 2) 
    end    
    if player.hasItem("meatpickle") then
	player.addCurrency("fumadnessresource", 2) 
    end
end

function uninit()
	status.clearPersistentEffects("madnessEffectsMain")
end