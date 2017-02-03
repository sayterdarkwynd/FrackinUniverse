require "/scripts/util.lua"

function init()
  object.setInteractive(true)
  self.timer = 1
end

function update(dt)
self.timer = self.timer - dt

if self.timer <= 0 then

  if isn_hasRequiredPower() == false then
    animator.setAnimationState("machineState", "idle")
	return
  end
  
  if world.liquidAt(entity.position()) == true and config.getParameter("isn_liquidCollector") == false then 
    return 
  end

  if config.getParameter("isn_liquidCollector") == true then 
    local output = nil
    local rarityroll = math.random(1,100)
    self.outputPos = object.position()
    
    --what biome are we in?
    if world.type() == "aethersea" then
            world.spawnLiquid(self.outputPos,100,0.5)    
	    self.timer = 2    
    elseif world.type() == "moon" or world.type() == "moon_desert" or world.type()== "moon_shadow" or world.type()=="moon_stone" or world.type()=="moon_volcanic" or world.type()=="moon_toxic" then
            world.spawnLiquid(self.outputPos,49,0.5)    
	    self.timer = 2          
    elseif world.type() == "atropus" or world.type() == "atropusdark" then
            world.spawnLiquid(self.outputPos,53,0.5)    
	    self.timer = 2        
    elseif world.type() == "fugasgiant" then
             world.spawnLiquid(self.outputPos,62,0.5)    
	    self.timer = 2    
    elseif world.type() == "bog" then
            world.spawnLiquid(self.outputPos,12,0.5)    
	    self.timer = 2      
    elseif world.type() == "chromatic" then
            world.spawnLiquid(self.outputPos,69,0.5)    
	    self.timer = 2       
    elseif world.type() == "crystalmoon" then
            world.spawnLiquid(self.outputPos,43,0.5)    
	    self.timer = 2              
    elseif world.type() == "nitrogensea" then
            world.spawnLiquid(self.outputPos,56,0.5)    
	    self.timer = 2         
    elseif world.type() == "infernus" or world.type() == "infernusdark" then
            world.spawnLiquid(self.outputPos,2,0.5)    
	    self.timer = 2    
    elseif world.type() == "slimeworld" then
              world.spawnLiquid(self.outputPos,13,0.5)    
	    self.timer = 2    
    elseif world.type() == "strangesea" then
            world.spawnLiquid(self.outputPos,41,0.5)    
	    self.timer = 2      
    elseif world.type() == "sulphuric" or world.type() == "sulphuricdark" or world.type() == "sulphuricocean" then
            world.spawnLiquid(self.outputPos,46,0.5)    
	    self.timer = 2        
    elseif world.type() == "tarball" then
            world.spawnLiquid(self.outputPos,42,0.5)    
	    self.timer = 2      
    elseif world.type() == "toxic" then
            world.spawnLiquid(self.outputPos,3,0.5)    
	    self.timer = 2      
    elseif world.type() == "metallicmoon" then
            world.spawnLiquid(self.outputPos,52,0.5)    
	    self.timer = 3         
    elseif world.type() == "lightless" then
            world.spawnLiquid(self.outputPos,100,0.5)    
	    self.timer = 3    
    elseif world.type() == "penumbra" or world.type() == "tidewater" then
            world.spawnLiquid(self.outputPos,60,0.5)    
	    self.timer = 4    
    elseif world.type() == "protoworld" or world.type() == "protoworlddark" then
            world.spawnLiquid(self.outputPos,44,0.5)    
	    self.timer = 5  
    elseif world.type() == "irradiated" then
            world.spawnLiquid(self.outputPos,47,0.5)    
	    self.timer = 2  
    else
            world.spawnLiquid(self.outputPos,1,0.5)    
	    self.timer = 2  
    end
    
    
  end	  
  
  animator.setAnimationState("machineState", "active")
  

  
  
  

end


end
