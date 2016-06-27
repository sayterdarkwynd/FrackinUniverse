require("/scripts/vec2.lua")
local fuoldInit = init
local fuoldUpdate = update
local fuoldUninit = uninit

function init()
  fuoldInit()
  self.lastYPosition = 0
  self.lastYVelocity = 0
  self.fallDistance = 0
  local bounds = mcontroller.boundBox() --Mcontroller for apex movement
end

function update(dt)
  fuoldUpdate(dt)
  
	--Human
	if world.entitySpecies(entity.id()) == "human" then
		status.addEphemeralEffect("racehuman",math.huge)
	end
	
	--Avian
	if world.entitySpecies(entity.id()) == "avian" then
		status.addEphemeralEffect("raceavian",math.huge)
		status.addEphemeralEffect("lowgravavian",math.huge)
	end

	--Apex
	if world.entitySpecies(entity.id()) == "apex" then
	       status.addEphemeralEffect("raceapex",math.huge)
	end
	
	--Floran
	if world.entitySpecies(entity.id()) == "floran" then
		status.addEphemeralEffect("racefloran",math.huge)
		status.addEphemeralEffect("maxenergyboostfloran",math.huge)
		status.addEphemeralEffect("lightregenfloran",math.huge)
		
	end
	
	--Hylotl
	if world.entitySpecies(entity.id()) == "hylotl" then
		status.addEphemeralEffect("racehylotl",math.huge)
		status.addEphemeralEffect("swimboosthylotl",math.huge)
	end
	
	--Glitch
	if world.entitySpecies(entity.id()) == "glitch" then
		status.addEphemeralEffect("raceglitch",math.huge)
	end
	
	--Novakid
	if world.entitySpecies(entity.id()) == "novakid" then
		status.addEphemeralEffect("racenovakid",math.huge)
		status.addEphemeralEffect("novakidglow",math.huge)
	end


	--avali
	if world.entitySpecies(entity.id()) == "avali" then
		status.addEphemeralEffect("raceavali",math.huge)
	end
	
	--avikan
	if world.entitySpecies(entity.id()) == "avikan" then
		status.addEphemeralEffect("raceavikan",math.huge)
	end
	
	--peglaci
	if world.entitySpecies(entity.id()) == "peglaci" then
		status.addEphemeralEffect("racepeglaci",math.huge)
	end
	--felins
	if world.entitySpecies(entity.id()) == "felins" then
		status.addEphemeralEffect("racefelins",math.huge)
	end	
	--Orcana
	if world.entitySpecies(entity.id()) == "orcana" then
		status.addEphemeralEffect("raceorcana",math.huge)
		status.addEphemeralEffect("swimboostorcana",math.huge)
	end
	--ponex
	if world.entitySpecies(entity.id()) == "ponex" then
		status.addEphemeralEffect("raceponex",math.huge)
	end
	--viera
	if world.entitySpecies(entity.id()) == "viera" then
		status.addEphemeralEffect("raceviera",math.huge)
	end	

	
  local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
  if status.statPositive("breathProtection") or world.breathable(mouthPosition) 
	or status.statPositive("waterbreathProtection") and world.liquidAt(mouthPosition) 
	then
    status.modifyResource("breath", status.stat("breathRegenerationRate") * dt)
  else
    status.modifyResource("breath", -status.stat("breathDepletionRate") * dt)
  end
  
  
  
	
end