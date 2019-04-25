require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  storage.madnessCount = player.currency("fumadnessresource") or 0
  self.timer = 0
  self.player = entity.id()
  
  self.randEvent = math.random(1,100) --only pick this on init so that effect changes on reloads only
    
end

function randomEvent()
    storage.currentPrimary=world.entityHandItem(entity.id(), "primary")
    storage.currentSecondary = world.entityHandItem(entity.id(), "alt")  

    if self.randEvent == 1 then 
	if player.hasCountOfItem("plantfibre")  then -- consume a plant fibre, just to confuse and confound
		player.consumeItem("plantfibre", true, false)
	end      
    end
    if self.randEvent == 2 then 
    	status.addEphemeralEffect("slow",120) --slows the player for a while
    end
    if self.randEvent == 3 then 
    	status.addEphemeralEffect("loweredshadow",200) --more succeptible to shadow
    end
    if self.randEvent == 4 then 
    	status.addEphemeralEffect("ffbiomecold0",200) --player feels cold
    end
    if self.randEvent == 5 then 
    	status.addEphemeralEffect("jungleheatweather",120) --player feels hot
    end
    if self.randEvent == 6 then 
    	status.addEphemeralEffect("insanity",600) --player feels insane
    end
    if self.randEvent == 7 then 
    	status.addEphemeralEffect("booze",120) --player feels drunk
    end
    if self.randEvent == 8 then 
    	status.addEphemeralEffect("maxhealthboostneg20",120) -- lowered health
    end
    if self.randEvent == 9 then 
    	status.addEphemeralEffect("maxenergyboostneg20",120) -- lowered energy
    end
    if self.randEvent == 10 then 
    	status.addEphemeralEffect("lowgrav_fallspeedup",20) -- adjusts gravity
    end
    if self.randEvent == 11 then 
    	status.addEphemeralEffect("medicalimmunization",200) -- immunization. you just dont CARE about sickness.
    end
    if self.randEvent == 12 then 
    	status.addEphemeralEffect("slimeleech",200) -- slimeleech. ew.
    end    
    if self.randEvent == 13 then 
	status.addEphemeralEffect("rootfu",20) -- unable to move
    end    
    if self.randEvent == 14 then 
	status.addEphemeralEffect("burning",320) -- You feel like you are on fire, even though you arent
    end  	
    if self.randEvent == 15 then 
	status.addEphemeralEffect("eatself",20) -- You just can't stop eating yourself.
	status.addEphemeralEffect("bleeding05",20) -- You just can't stop eating yourself.
    end  	
    if self.randEvent == 16 then 
	status.addEphemeralEffect("fu_nooxygen",320) -- You have forgotten how to breathe
    end  	
    if self.randEvent == 17 then 
	status.addEphemeralEffect("knockbackWeaknessHidden",320) -- Knockbacks affect you more
    end    
    if self.randEvent == 18 then 
	status.addEphemeralEffect("swimboost1",320) -- Swim boost!
    end  	
    if self.randEvent == 19 then 
	status.addEphemeralEffect("swimboost2",320) -- Swim boost2!
    end  	
    if self.randEvent == 20 then 
	status.addEphemeralEffect("runboost5",320) -- run boost!
    end  	 	
    if self.randEvent == 21 then 
	status.addEphemeralEffect("runboost10",320) -- run boost!
    end  
    if self.randEvent == 22 then 
	status.addEphemeralEffect("runboost15",320) -- run boost!
    end  
    if self.randEvent == 23 then 
	status.addEphemeralEffect("runboostdebuff",320) -- run boost!
    end     
    if self.randEvent == 24 then
      player.consumeCurrency("fuscienceresource", 200) -- lose 200 research
    end
    if self.randEvent == 25 then
      player.consumeCurrency("fumadnessresource", 200) -- lose 200 madness
    end   
    if self.randEvent == 26 then
      player.addCurrency("fuscienceresource", 200) -- gain 200 research
    end
    if self.randEvent == 27 then
      player.addCurrency("fumadnessresource", 200) -- gain 200 madness
    end       
    if self.randEvent == 28 then
      player.addCurrency("essence", 200) -- gain 200 essence
    end  
    if self.randEvent == 29 then
      player.consumeCurrency("essence", 200) -- lose 200 essence
    end      
    if self.randEvent == 30 then
      player.consumeCurrency("essence", 200) -- lose 200 essence
    end        
    if self.randEvent == 31 then --if holding a knife, cut yourself
      if root.itemHasTag(storage.currentPrimary, "dagger") or root.itemHasTag(storage.currentSecondary, "dagger") then
        status.addEphemeralEffect("bleeding05",20) -- You just can't stop stabbing yourself
      end
    end
    if self.randEvent == 32 then --increased hunger
    	status.addEphemeralEffect("feedpackneg",600) --player feels hot
    end    
    if self.randEvent == 33 then 
	status.addEphemeralEffect("jumpboost25neg",240) -- You suddenly suck at jumping
    end   
    if self.randEvent == 34 then --your hunger total is random
	    if status.isResource("food")
	       local randHunger = math.random(70)+2
	       status.setResource("food",randHunger)
	    end  
    end
    if self.randEvent == 35 then --swap tech
	player.equipTech("distortionsphere")
    end      
    if self.randEvent == 36 then --swap tech
	player.equipTech("doublejump")
    end   
    if self.randEvent == 37 then --swap tech
	player.equipTech("dash")
    end       
    if self.randEvent == 37 then --swap tech
	player.equipTech("dash")
    end         
end

function update(dt)
  storage.madnessCount = player.currency("fumadnessresource")

  -- Core Adjustments Functions
  self.timer = self.timer - 1
  if self.timer < 1 then 
  randomEvent() --apply random effect
	  if storage.madnessCount > 50 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 300
	  end  
	  if storage.madnessCount > 100 then
		player.consumeCurrency("fuscienceresource", 1)
		player.consumeCurrency("fumadnessresource", 1)
		self.timer = 250
	  end
	  if storage.madnessCount > 200 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 200
	  end  
	  if storage.madnessCount > 300 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 150
	  end
	  if storage.madnessCount > 400 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 120
	  end  
	  if storage.madnessCount > 500 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 100
	  end
	  if storage.madnessCount > 700 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 90
	  end  
	  if storage.madnessCount > 900 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 80
	  end  
	  if storage.madnessCount > 1500 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 70
	  end  
	  if storage.madnessCount > 2000 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 60
	  end    
	  if storage.madnessCount > 2500 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 50
	  end
	  if storage.madnessCount > 3000 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 40
	  end  
	  if storage.madnessCount > 3500 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 30
	  end  
	  if storage.madnessCount > 3999 then
		player.consumeCurrency("fuscienceresource", 1)
		self.timer = 20
	  end
  end
  -- end CORE
  
end

function uninit()
	status.clearEphemeralEffect("loweredshadow")  
	status.clearEphemeralEffect("slow") 
	status.clearEphemeralEffect("ffbiomecold0") 
	status.clearEphemeralEffect("jungleheatweather") 
	status.clearEphemeralEffect("insanity")
	status.clearEphemeralEffect("booze")
	status.clearEphemeralEffect("maxhealthboostneg20")
	status.clearEphemeralEffect("maxenergyboostneg20")
	status.clearEphemeralEffect("lowgrav_fallspeedup")
	status.clearEphemeralEffect("medicalimmunization")
	status.clearEphemeralEffect("slimeleech")
	status.clearEphemeralEffect("rootfu")
	status.clearEphemeralEffect("burning")
	status.clearEphemeralEffect("eatself")
	status.clearEphemeralEffect("fu_nooxygen")
	status.clearEphemeralEffect("knockbackWeaknessHidden")
	status.clearEphemeralEffect("swimboost1")
	status.clearEphemeralEffect("swimboost2")
	status.clearEphemeralEffect("runboost5")
	status.clearEphemeralEffect("runboost10")
	status.clearEphemeralEffect("runboost15")
	status.clearEphemeralEffect("runboostdebuff")
	status.clearEphemeralEffect("feedpackneg")
end
