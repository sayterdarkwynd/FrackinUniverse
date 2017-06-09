require "/scripts/util.lua"
require "/scripts/kheAA/transferUtil.lua"
local deltaTime=0

function init()
  transferUtil.init()
  object.setInteractive(true)
  self.timer = 1
end

function update(dt)
self.timer = self.timer - dt

if deltaTime > 1 then
	deltaTime=0
	transferUtil.loadSelfContainer()
else
	deltaTime=deltaTime+dt
end

if self.timer <= 0 then

  if isn_hasRequiredPower() == false then
    animator.setAnimationState("machineState", "idle")
	return
  end
  
  if world.liquidAt(entity.position()) == true and config.getParameter("isn_liquidCollector") == false then return end
  
  animator.setAnimationState("machineState", "active")
  
  local output = nil
  local rarityroll = math.random(1,100)
  
  --what biome are we in?
    if world.type() == "aethersea" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("aetherrareOutputs"))
	    self.timer = 6
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("aetheruncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("aetherOutputs"))
	    self.timer = 2
	  end 
    elseif world.type() == "moon" or world.type() == "moon_desert" or world.type()== "moon_shadow" or world.type()=="moon_stone" or world.type()=="moon_volcanic" or world.type()=="moon_toxic" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("moonrareOutputs"))
	    self.timer = 8
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("moonuncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("moonOutputs"))
	    self.timer = 3
	  end         
    elseif world.type() == "atropus" or world.type() == "atropusdark" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("atropusrareOutputs"))
	    self.timer = 6
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("atropusuncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("atropusOutputs"))
	    self.timer = 2
	  end      
    elseif world.type() == "fugasgiant" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("gasrareOutputs"))
	    self.timer = 7
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("gascuncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("gasOutputs"))
	    self.timer = 2
	  end      
    elseif world.type() == "bog" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("bograreOutputs"))
	    self.timer = 5
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("bogcuncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("bogOutputs"))
	    self.timer = 2
	  end     
    elseif world.type() == "chromatic" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("chromaticrareOutputs"))
	    self.timer = 6
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("chromaticuncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("chromaticOutputs"))
	    self.timer = 2
	  end      
    elseif world.type() == "crystalmoon" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("crystalrareOutputs"))
	    self.timer = 7
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("crystaluncommonOutputs"))
	    self.timer = 5.5
	  else
	    output = util.randomFromList(config.getParameter("crystalOutputs"))
	    self.timer = 4
	  end        
    elseif world.type() == "desert" or world.type() == "desertwastes" or world.type() == "desertwastesdark" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("desertrareOutputs"))
	    self.timer = 5
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("desertuncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("desertOutputs"))
	    self.timer = 2
	  end      
    elseif world.type() == "icewaste" or world.type() == "icewastedark" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("icerareOutputs"))
	    self.timer = 8
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("iceuncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("iceOutputs"))
	    self.timer = 2
	  end       
    elseif world.type() == "nitrogensea" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("nitrogenrareOutputs"))
	    self.timer = 8
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("nitrogenuncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("nitrogenOutputs"))
	    self.timer = 2
	  end         
    elseif world.type() == "infernus" or world.type() == "infernusdark" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("infernusrareOutputs"))
	    self.timer = 8
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("infernusuncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("infernusOutputs"))
	    self.timer = 2
	  end       
    elseif world.type() == "slimeworld" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("slimerareOutputs"))
	    self.timer = 6
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("slimeuncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("slimeOutputs"))
	    self.timer = 2
	  end      
    elseif world.type() == "strangesea" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("strangesearareOutputs"))
	    self.timer = 6
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("strangeseauncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("strangeseaOutputs"))
	    self.timer = 2
	  end     
    elseif world.type() == "ocean" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("oceanrareOutputs"))
	    self.timer = 5
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("oceanuncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("oceanOutputs"))
	    self.timer = 2
	  end     
    elseif world.type() == "sulphuric" or world.type() == "sulphuricdark" or world.type() == "sulphuricocean" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("sulphuricrareOutputs"))
	    self.timer = 5
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("sulphuricuncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("sulphuricOutputs"))
	    self.timer = 2
	  end      
    elseif world.type() == "tarball" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("tarballrareOutputs"))
	    self.timer = 7
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("tarballuncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("tarballOutputs"))
	    self.timer = 2
	  end      
    elseif world.type() == "toxic" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("toxicrareOutputs"))
	    self.timer = 5
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("toxicuncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("toxicOutputs"))
	    self.timer = 2
	  end     
    elseif world.type() == "metallicmoon" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("metallicrareOutputs"))
	    self.timer = 5
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("metallicuncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("metallicOutputs"))
	    self.timer = 2
	  end        
    elseif world.type() == "lightless" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("lightlessrareOutputs"))
	    self.timer = 5
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("lightlessuncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("lightlessOutputs"))
	    self.timer = 2
	  end    
    elseif world.type() == "penumbra" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("penumbrarareOutputs"))
	    self.timer = 6
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("penumbrauncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("penumbraOutputs"))
	    self.timer = 2
	  end     
    elseif world.type() == "protoworld" or world.type() == "protoworlddark" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("protorareOutputs"))
	    self.timer = 6
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("protouncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("protoOutputs"))
	    self.timer = 2
	  end     
    elseif world.type() == "irradiated" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("radiationrareOutputs"))
	    self.timer = 7
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("radiationuncommonOutputs"))
	    self.timer = 4.5
	  else
	    output = util.randomFromList(config.getParameter("radiationOutputs"))
	    self.timer = 2
	  end 
    elseif world.type() == "fungus" then
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("fungusrareOutputs"))
	    self.timer = 5.3
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("fungusuncommonOutputs"))
	    self.timer = 3.7
	  else
	    output = util.randomFromList(config.getParameter("fungusOutputs"))
	    self.timer = 2
	  end 	  
    else
	  if rarityroll == 100 then  
	    output = util.randomFromList(config.getParameter("rareOutputs"))
	    self.timer = 5
	  elseif rarityroll >= 79 then
	    output = util.randomFromList(config.getParameter("uncommonOutputs"))
	    self.timer = 3.5
	  else
	    output = util.randomFromList(config.getParameter("commonOutputs"))
	    self.timer = 2
	  end    
    end

  
  if output == nil or clearSlotCheck(output) == false then return end
  
  world.containerAddItems(entity.id(), {name = output, count = 1, data={}})
end


end




function clearSlotCheck(checkname)
	if world.containerItemsCanFit(entity.id(), {name= checkname, count=1, data={}}) > 0 then
		return true
	end
	return false
end