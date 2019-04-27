require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  storage.madnessCount = player.currency("fumadnessresource") or 0
  self.timer = 0
  self.player = entity.id()
  self.randEvent = math.random(1,100) --only pick this on init so that effect changes on reloads only
  self.timerDegrade = math.random(1,12)
  self.degradeTotal = 0
  self.isProtected = config.getParameter("mentalProtection") or 0
end

function randomEvent()

    storage.currentPrimary=world.entityHandItem(entity.id(), "primary")
    storage.currentSecondary = world.entityHandItem(entity.id(), "alt")  
    
	if not isProtected then --player does not have the mentalProtection stat applied
	    if self.randEvent == 1 and storage.madnessCount > 200 then 
		if player.hasCountOfItem("plantfibre")  then -- consume a plant fibre, just to confuse and confound
			player.consumeItem("plantfibre", true, false)
		end      
	    end
	    if self.randEvent == 2 and storage.madnessCount > 200 then 
		status.addEphemeralEffect("slow",120) --slows the player for a while
	    end
	    if self.randEvent == 3 and storage.madnessCount > 200 then 
		status.addEphemeralEffect("loweredshadow",200) --more succeptible to shadow
	    end
	    if self.randEvent == 4 and storage.madnessCount > 200 then 
		status.addEphemeralEffect("ffbiomecold0",200) --player feels cold
	    end
	    if self.randEvent == 5 and storage.madnessCount > 200 then 
		status.addEphemeralEffect("jungleweathernew",120) --player feels hot
	    end
	    if self.randEvent == 6 and storage.madnessCount > 200 then 
		status.addEphemeralEffect("insanity",600) --player feels insane
	    end
	    if self.randEvent == 7 and storage.madnessCount > 200 then 
		status.addEphemeralEffect("booze",120) --player feels drunk
	    end
	    if self.randEvent == 8 and storage.madnessCount > 300 then 
		status.addEphemeralEffect("maxhealthboostneg20",120) -- lowered health
	    end
	    if self.randEvent == 9 and storage.madnessCount > 300 then 
		status.addEphemeralEffect("maxenergyboostneg20",120) -- lowered energy
	    end
	    if self.randEvent == 10 and storage.madnessCount > 350 then 
		status.addEphemeralEffect("lowgrav_fallspeedup",20) -- adjusts gravity
	    end
	    if self.randEvent == 11 and storage.madnessCount > 400 then 
		status.addEphemeralEffect("medicalimmunization",200) -- immunization. you just dont CARE about sickness.
	    end
	    if self.randEvent == 12 and storage.madnessCount > 400 then 
		status.addEphemeralEffect("slimeleech",200) -- slimeleech. ew.
		self.timerDegradePenalty = 4
	    end    
	    if self.randEvent == 13 and storage.madnessCount > 900 then 
		status.addEphemeralEffect("rootfu",10) -- unable to move
	    end    
	    if self.randEvent == 14 and storage.madnessCount > 700 then 
		status.addEphemeralEffect("burning",320) -- You feel like you are on fire, even though you arent
		self.timerDegradePenalty = 4
	    end  	
	    if self.randEvent == 15 and storage.madnessCount > 1500 then 
		status.addEphemeralEffect("eatself",20) -- You just can't stop eating yourself.
		status.addEphemeralEffect("bleeding05",20) -- You just can't stop eating yourself.
		self.timerDegradePenalty = 4
	    end  	
	    if self.randEvent == 16 and storage.madnessCount > 600 then 
		status.addEphemeralEffect("fu_nooxygen",320) -- You have forgotten how to breathe
	    end  	
	    if self.randEvent == 17 and storage.madnessCount > 400 then 
		status.addEphemeralEffect("knockbackWeaknessHidden",320) -- Knockbacks affect you more
	    end    
	    if self.randEvent == 18 and storage.madnessCount > 450 then 
		status.addEphemeralEffect("swimboost1",320) -- Swim boost!
	    end  	
	    if self.randEvent == 19 and storage.madnessCount > 540 then 
		status.addEphemeralEffect("swimboost2",320) -- Swim boost2!
	    end  	
	    if self.randEvent == 20 and storage.madnessCount > 200 then 
		status.addEphemeralEffect("runboost5",320) -- run boost!
		self.timerDegradePenalty = 2
	    end  	 	
	    if self.randEvent == 21 and storage.madnessCount > 800 then 
		status.addEphemeralEffect("runboost10",320) -- run boost!
		self.timerDegradePenalty = 2
	    end  
	    if self.randEvent == 22 and storage.madnessCount > 1500 then 
		status.addEphemeralEffect("runboost15",320) -- run boost!
		self.timerDegradePenalty = 2
	    end  
	    if self.randEvent == 23 and storage.madnessCount > 500 then 
		status.addEphemeralEffect("runboostdebuff",320) -- run boost!
		self.timerDegradePenalty = 3
	    end     
	    if self.randEvent == 24 and storage.madnessCount > 2100 then
	      player.consumeCurrency("fuscienceresource", 200) -- lose 200 research
	      self.timerDegradePenalty = 2
	    end
	    if self.randEvent == 25 and storage.madnessCount > 2100 then
	      player.consumeCurrency("fumadnessresource", 200) -- lose 200 madness
	      self.timerDegradePenalty = 2
	    end   
	    if self.randEvent == 26 and storage.madnessCount > 200 then
	      player.addCurrency("fuscienceresource", 200) -- gain 200 research
	      self.timerDegradePenalty = 2
	    end
	    if self.randEvent == 27 and storage.madnessCount > 400 then
	      player.addCurrency("fumadnessresource", 200) -- gain 200 madness
	      self.timerDegradePenalty = 2
	    end       
	    if self.randEvent == 28 and storage.madnessCount > 1200 then
	      player.addCurrency("essence", 200) -- gain 200 essence
	    end  
	    if self.randEvent == 29 and storage.madnessCount > 1200 then
	      player.consumeCurrency("essence", 200) -- lose 200 essence
	      self.timerDegradePenalty = 2
	    end      
	    if self.randEvent == 30 and storage.madnessCount > 800 then
	      player.addCurrency("essence", 200) -- gain 200 essence
	    end        
	    if self.randEvent == 31 and storage.madnessCount > 800 then --if holding a knife, cut yourself
	      if root.itemHasTag(storage.currentPrimary, "dagger") or root.itemHasTag(storage.currentSecondary, "dagger") then
		status.addEphemeralEffect("bleeding05",20) -- You just can't stop stabbing yourself
	      end
	    end
	    if self.randEvent == 32 and storage.madnessCount > 500 then --increased hunger
		status.addEphemeralEffect("feedpackneg",600) --player feels hot
		self.timerDegradePenalty = 2
	    end    
	    if self.randEvent == 33 and storage.madnessCount > 700 then 
		status.addEphemeralEffect("jumpboost25neg",240) -- You suddenly suck at jumping
	    end   
	    if self.randEvent == 34 and storage.madnessCount > 400 then --your hunger total is random
		    if status.isResource("food") then
		       local randHunger = math.random(1,70)+2
		       status.setResource("food",randHunger)
		    end  
	    end
	    if self.randEvent == 35 and storage.madnessCount > 1200 then --swap tech
		player.equipTech("distortionsphere")
	    end      
	    if self.randEvent == 36 and storage.madnessCount > 1200 then --swap tech
		player.equipTech("doublejump")
	    end   
	    if self.randEvent == 37 and storage.madnessCount > 1200 then --swap tech
		player.equipTech("dash")
	    end      
	    if self.randEvent == 38 and storage.madnessCount > 1500 then --become unarmored by 1d8
	      local penaltyValue = math.random(1,8)
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "protection", amount = status.stat("protection")-penaltyValue }
		  })    
	    end 
	    if self.randEvent == 39 and storage.madnessCount > 200 then --become uncharismatic
	      local penaltyValue = math.random(1,8)
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "fuCharisma", amount = status.stat("fuCharisma")-penaltyValue }
		  })    
	    end       
	    if self.randEvent == 40 and storage.madnessCount > 500 then --max food reduction
	      local penaltyValue = math.random(1,8)
		  status.setPersistentEffects("madnessEffectsMain", {  
			{stat = "maxFood", amount = status.stat("maxFood")-penaltyValue }
		  })    
	    end
	end

   
end

function update(dt)
  storage.madnessCount = player.currency("fumadnessresource")
  
  -- Core Adjustments Functions
  self.timer = self.timer - 1
  if self.timer < 1 then 
  
	  if storage.madnessCount > 50 then
		self.timer = 300
		randomEvent() --apply random effect
	  end  
	  if storage.madnessCount > 100 then
		self.timer = 250
		randomEvent() --apply random effect
	  end
	  if storage.madnessCount > 200 then
		self.timer = 200
		randomEvent() --apply random effect
	  end  
	  if storage.madnessCount > 300 then
		self.timer = 150
		randomEvent() --apply random effect	
	  end
	  if storage.madnessCount > 400 then
		self.timer = 120
		randomEvent() --apply random effect
	  end  
	  if storage.madnessCount > 500 then
		self.timer = 100
		randomEvent() --apply random effect
	  end
	  if storage.madnessCount > 700 then
		self.timer = 90
		randomEvent() --apply random effect
	  end  
	  if storage.madnessCount > 900 then
		self.timer = 80
		randomEvent() --apply random effect
		self.timerDegradePenalty = 1
		self.degradeTotal = 2
	  end  
	  if storage.madnessCount > 1000 then
		self.timer = 75
		randomEvent() --apply random effect
		self.timerDegradePenalty = 2
		self.degradeTotal = 2
	  end  	  
	  if storage.madnessCount > 1500 then
		self.timer = 70
		randomEvent() --apply random effect
		self.timerDegradePenalty = 3
		self.degradeTotal = 3
	  end  
	  if storage.madnessCount > 2000 then
		self.timer = 60
		randomEvent() --apply random effect
		self.timerDegradePenalty = 4
		self.degradeTotal = 3
	  end    
	  if storage.madnessCount > 2500 then
		self.timer = 50
		randomEvent() --apply random effect
		self.timerDegradePenalty = 4
		self.degradeTotal = 4
	  end
	  if storage.madnessCount > 3000 then
		self.timer = 40
		randomEvent() --apply random effect
		self.timerDegradePenalty = 5
		self.degradeTotal = 4
	  end  
	  if storage.madnessCount > 3500 then
		self.timer = 30
		randomEvent() --apply random effect
		self.timerDegradePenalty = 5
		self.degradeTotal = 5
	  end  
	  if storage.madnessCount > 4999 then
		self.timer = 20
		randomEvent() --apply random effect
		self.timerDegradePenalty = 6
		self.degradeTotal = 5
	  end
	  if storage.madnessCount > 15000 then
		self.degradeTotal = 25
		self.timerDegradePenalty = 6
	  end	  
  end
  -- end CORE
  
    --gradually reduce Madness over time
    self.timerDegrade = self.timerDegrade -1
	if self.timerDegrade < 0 then -- make sure its never negative
		self.timerDegrade = 0
	end
	
	if self.timerDegrade == 0 then
	    if storage.madnessCount > 1000 then   --high madness is hard to keep consistent
		    self.timerDegradePenalty = self.timerDegradePenalty or 0
		    player.consumeCurrency("fumadnessresource", self.degradeTotal)
		    self.timerDegrade= 7 - self.timerDegradePenalty    
	    end
	end  
end

function uninit()
	status.clearPersistentEffects("madnessEffectsMain")
end