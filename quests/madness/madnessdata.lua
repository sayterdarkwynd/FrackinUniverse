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
end

function randomEvent()
    storage.currentPrimary = world.entityHandItem(entity.id(), "primary")  --what are we carrying?
    storage.currentSecondary = world.entityHandItem(entity.id(), "alt")  --what are we carrying?
    self.isProtectedRand = math.random(1,100)
    self.isProtectedRandVal = self.isProtectedRand / 100
  
    --mentalProtection can make it harder to be affected
    if (status.statPositive("mentalProtection")) and (self.isProtectedRandVal <= status.stat("mentalProtection")) then 
      self.randEvent = self.randEvent + math.random(10,70)  --it doesnt *remove* the effect, it just moves it further up the list, and potentially off of it.
    end
    
    -- are we currently carrying any really weird stuff? 
    isWeirdStuff()

    
    if self.randEvent == 1 and storage.madnessCount > 200 then 
	if player.hasCountOfItem("plantfibre")  then -- consume a plant fibre, just to confuse and confound
		player.consumeItem("plantfibre", true, false)
		player.radioMessage("madness1")
	end      
    end
    if self.randEvent == 2 and storage.madnessCount > 200 then 
	status.addEphemeralEffect("slow",120) --slows the player for a while
	player.radioMessage("madness2")
    end
    if self.randEvent == 3 and storage.madnessCount > 200 then 
	status.addEphemeralEffect("loweredshadow",300) --more succeptible to shadow
    end
    if self.randEvent == 4 and storage.madnessCount > 200 then 
	status.addEphemeralEffect("ffbiomecold0",200) --player feels cold
    end
    if self.randEvent == 5 and storage.madnessCount > 200 then 
	status.addEphemeralEffect("jungleweathernew",220) --player feels hot
    end
    if self.randEvent == 6 and storage.madnessCount > 200 then 
	status.addEphemeralEffect("insanity",600) --player feels insane
    end
    if self.randEvent == 7 and storage.madnessCount > 200 then 
	status.addEphemeralEffect("booze",220) --player feels drunk
    end
    if self.randEvent == 8 and storage.madnessCount > 300 then 
	status.addEphemeralEffect("maxhealthboostneg20",220) -- lowered health
    end
    if self.randEvent == 9 and storage.madnessCount > 300 then 
	status.addEphemeralEffect("maxenergyboostneg20",220) -- lowered energy
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
	player.radioMessage("madnessroot")
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
	player.radioMessage("madness2")
	self.timerDegradePenalty = 3
    end     
    if self.randEvent == 24 and storage.madnessCount > 1100 then
      player.consumeCurrency("fuscienceresource", 1) 
      player.radioMessage("sanitygain")
      self.timerDegradePenalty = 2
    end
    if self.randEvent == 25 and storage.madnessCount > 2100 then
      player.consumeCurrency("fumadnessresource", 1) 
      player.radioMessage("sanitygain")
      self.timerDegradePenalty = 2
    end   
    if self.randEvent == 26 and storage.madnessCount > 200 then
      player.addCurrency("fuscienceresource", 1) 
      self.timerDegradePenalty = 2
    end
    if self.randEvent == 27 and storage.madnessCount > 400 then
      player.addCurrency("fuscienceresource", 2) 
      self.timerDegradePenalty = 2
    end       
    if self.randEvent == 28 and storage.madnessCount > 1200 then
      player.addCurrency("essence", 1) 
    end  
    if self.randEvent == 29 and storage.madnessCount > 1200 then
      player.consumeCurrency("essence", 1) 
      self.timerDegradePenalty = 2
    end      
    if self.randEvent == 30 and storage.madnessCount > 800 then
      player.addCurrency("essence", 2)
    end        
    if self.randEvent == 31 and storage.madnessCount > 800 then --if holding a knife, cut yourself
      if root.itemHasTag(storage.currentPrimary, "dagger") or root.itemHasTag(storage.currentSecondary, "dagger") then
	status.addEphemeralEffect("bleeding05",20) -- You just can't stop stabbing yourself
	player.radioMessage("madnessharm")
      end
    end
    if self.randEvent == 32 and storage.madnessCount > 500 then --increased hunger
	status.addEphemeralEffect("feedpackneg",600) --player feels hot
	player.radioMessage("madnessfood")
	self.timerDegradePenalty = 2
    end    
    if self.randEvent == 33 and storage.madnessCount > 700 then 
	status.addEphemeralEffect("jumpboost25neg",240) -- You suddenly suck at jumping
	player.radioMessage("madness2")
    end   
    if self.randEvent == 34 and storage.madnessCount > 400 then --your hunger total is random
	    if status.isResource("food") then
	       local randHunger = math.random(1,70)+2
	       status.setResource("food",randHunger)
	    end  
	    player.radioMessage("madnessfood")
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
    if self.randEvent == 38 and storage.madnessCount > 1500 then --become unarmored by 1d20
      local penaltyValue = math.random(1,20)
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
    if self.randEvent == 41 and storage.madnessCount > 600 then --swap tech
      if player.isLounging() then
        status.addEphemeralEffect("burning",20)
        player.radioMessage("combust")
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
		self.degradeTotal = 1
		randomEvent() --apply random effect
	  end  
	  if storage.madnessCount > 100 then
		self.timer = 250
		self.degradeTotal = 1
		randomEvent() --apply random effect
	  end
	  if storage.madnessCount > 200 then
		self.timer = 200
		self.degradeTotal = 1
		randomEvent() --apply random effect
	  end  
	  if storage.madnessCount > 300 then
		self.timer = 150
		self.degradeTotal = 1
		randomEvent() --apply random effect	
	  end
	  if storage.madnessCount > 400 then
		self.timer = 120
		self.degradeTotal = 1
		randomEvent() --apply random effect
	  end  
	  if storage.madnessCount > 500 then
		self.timer = 100
		self.degradeTotal = 1
		randomEvent() --apply random effect
	  end
	  if storage.madnessCount > 700 then
		self.timer = 90
		self.degradeTotal = 1
		randomEvent() --apply random effect
	  end  
	  if storage.madnessCount > 1000 then
		self.timer = 80
		randomEvent() --apply random effect
		self.timerDegradePenalty = 1
		self.degradeTotal = 1
	  end  	  
	  if storage.madnessCount > 1500 then
		self.timer = 70
		randomEvent() --apply random effect
		self.timerDegradePenalty = 2
		self.degradeTotal = 1
	  end  
	  if storage.madnessCount > 2000 then
		self.timer = 60
		randomEvent() --apply random effect
		self.timerDegradePenalty = 3
		self.degradeTotal = 2
	  end    
	  if storage.madnessCount > 2500 then
		self.timer = 50
		randomEvent() --apply random effect
		self.timerDegradePenalty = 4
		self.degradeTotal = 3
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
		self.degradeTotal = 6
	  end
	  if storage.madnessCount > 15000 then
	        storage.madnessCount = 15000
	        self.timer = 10
	        randomEvent()
		self.degradeTotal = 32
		self.timerDegradePenalty = 6
	  end	  
  end
  -- end CORE

 	self.timerDegrade = self.timerDegrade -1
	if self.timerDegrade <= 0 then
	--gradually reduce Madness over time
	    if storage.madnessCount then   --high madness is harder to hold onto, and less farmable, if it always reduces
			    self.timerDegradePenalty = self.timerDegradePenalty or 0
			    player.consumeCurrency("fumadnessresource", self.degradeTotal)
			    self.timerDegrade= 7 - self.timerDegradePenalty        
	    end	
	end 
	
 -- apply bonus loss from anti-madness effects
	self.bonusTimer = self.bonusTimer -1
	if self.bonusTimer <= 0 then
	    self.protectionBonus = status.stat("mentalProtection")/5 + math.random(1,20) -- 1d20 + their Mental Protection / 5
	    --mentalProtection can make it harder to be affected
	    if (status.statPositive("mentalProtection")) then 
	      player.consumeCurrency("fumadnessresource", self.protectionBonus)   
	    end
	    self.bonusTimer = 5
	end
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