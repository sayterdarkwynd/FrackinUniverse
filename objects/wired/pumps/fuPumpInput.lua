require "/scripts/vec2.lua"

function init()
	self.inputLocation = object.position()
	storage.currentState = setCurrentOutput() and (not object.isOutputNodeConnected(0) or object.getInputNodeLevel(0))
	animate()
end

function animate()
	animator.setAnimationState("inputState",storage.currentState and "on" or "off")
end

function locatePump(area)
    for outputObject,v in pairs(area) do
        local isStandard = world.getObjectParameter(outputObject,"pumpOutputStandard")
		local isPressure = world.getObjectParameter(outputObject,"pumpOutputPressure")
        if isStandard or isPressure then
			return outputObject,isPressure
        end
    end
    return false
 end

function setCurrentOutput()
    if object.isOutputNodeConnected(0) then
        local outputId,isPressure =  locatePump(object.getOutputNodeIds(0))
        local var -- set to null
		
        if outputId then
            storage.outputLocation = world.entityPosition(outputId)
            storage.outputProtected = world.isTileProtected(storage.outputLocation)
			storage.liquidStandard = not isPressure
			storage.liquidPressurized = isPressure
			return true
		end
	end
	
	storage.liquidStandard=false
	storage.liquidPressurized=false
	storage.outputLocation=nil
	storage.outputProtected=nil
	return false
end

function moveLiquid(inputLocation,outputLocation)
    local inputLiquid = world.liquidAt(inputLocation)
	
    if inputLiquid and inputLiquid[2] > 0.1 then  
        local outputLiquid = world.liquidAt(outputLocation)
		
        if (storage.liquidPressurized or (not outputLiquid or (outputLiquid[1] == inputLiquid[1] and outputLiquid[2] < 1))) then 
            
			if storage.outputProtected then 
				world.setTileProtection(world.dungeonId(storage.outputLocation), false) 
            end
			
            world.destroyLiquid(inputLocation)
            world.spawnLiquid(outputLocation,inputLiquid[1],inputLiquid[2]*1.01)
           
            if storage.outputProtected then 
				world.setTileProtection(world.dungeonId(storage.outputLocation), true) 
            end
            
            return true
        end

    end
    return false
end

function onInputNodeChange(args)
	storage.currentState = setCurrentOutput() and (not object.isInputNodeConnected(0) or object.getInputNodeLevel(0))
end

function onNodeConnectionChange() 
	storage.currentState = setCurrentOutput() and (not object.isInputNodeConnected(0) or object.getInputNodeLevel(0))
end

function update(dt)

    if not self.timer or self.timer <= 0 then
        storage.currentState = setCurrentOutput() and (not object.isInputNodeConnected(0) or object.getInputNodeLevel(0))
		self.timer = 1
	else
		self.timer = self.timer - dt
    end

    local hasMovedLiquid = false
	
    if storage.currentState then
        if storage.liquidStandard or storage.liquidPressurized then
            hasMovedLiquid = moveLiquid(self.inputLocation,storage.outputLocation)
            hasMovedLiquid = moveLiquid(vec2.add(self.inputLocation,{1,0}),vec2.add(storage.outputLocation,{1,0})) or hasMovedLiquid
			world.callScriptedEntity(world.objectAt(storage.outputLocation),"receivedLiquidPumpInput")
        end
	end
	
	object.setAllOutputNodes(storage.currentState)
    animate()
end
