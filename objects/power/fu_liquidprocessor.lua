function init()
	
	storage.checkticks = 0
	storage.truepos = isn_getTruePosition()
	self.outputPos = object.position()
end

function update(dt)
  if config.getParameter("isn_liquidCollector") == true then 
    self.outputPos = object.position()
    world.spawnLiquid(self.outputPos,1,11)
  end	
	
end


function onNodeConnectionChange()
	if isn_checkValidOutput() == true then object.setOutputNodeLevel(0, true)
	else object.setOutputNodeLevel(0, false) end
end

function isn_powerGenerationBlocked()
	-- Power generation does not occur if...
	if world.underground(location) == true then return true end -- it's underground
	if world.tileIsOccupied(location,false) == true then return true end -- there's a wall in the way
end

