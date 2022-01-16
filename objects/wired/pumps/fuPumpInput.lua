require "/scripts/vec2.lua"

function init()
	isInstance=world.getProperty("ephemeral")
	self.inputLocation = object.position()
	storage.currentState = setCurrentOutput() and (not object.isOutputNodeConnected(0) or object.getInputNodeLevel(0))
	animate()
end

function animate()
	animator.setAnimationState("inputState",storage.currentState and "on" or "off")
end

function locatePump(area)
    for outputObject in pairs(area) do
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

        if outputId then
            self.outputLocation = world.entityPosition(outputId)
            --self.outputProtected = world.isTileProtected(self.outputLocation)
			self.liquidStandard = not isPressure
			self.liquidPressurized = isPressure
			return true
		end
	end

	self.liquidStandard=false
	self.liquidPressurized=false
	self.outputLocation=nil
	--self.outputProtected=nil
	return false
end

function moveLiquid(inputLocation,outputLocation)
    local inputLiquid = world.liquidAt(inputLocation)

    if inputLiquid and inputLiquid[2] > 0.1 then
        local outputLiquid = world.liquidAt(outputLocation)

        if (self.liquidPressurized or (not outputLiquid or (outputLiquid[1] == inputLiquid[1] and outputLiquid[2] < 1))) then

			local protectCheckOutput=false
			if world.isTileProtected(self.outputLocation) then
				world.setTileProtection(world.dungeonId(self.outputLocation), false)
				protectCheckOutput=true
            end
			local destroyed
			if world.isTileProtected(inputLocation) then
				destroyed=world.forceDestroyLiquid(isTileProtected)
			else
				destroyed=world.destroyLiquid(inputLocation)
			end

			if destroyed then
				world.spawnLiquid(outputLocation,inputLiquid[1],inputLiquid[2])
           end
            if protectCheckOutput then
				world.setTileProtection(world.dungeonId(self.outputLocation), true)
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

	if not self.timer2 or self.timer2 <= 0 then
		local hasMovedLiquid = false

		if storage.currentState then
			if self.liquidStandard or self.liquidPressurized then
				local buffer=world.objectAt(self.outputLocation)
				if buffer then
					hasMovedLiquid = moveLiquid(self.inputLocation,self.outputLocation)
					hasMovedLiquid = moveLiquid(vec2.add(self.inputLocation,{1,0}),vec2.add(self.outputLocation,{1,0})) or hasMovedLiquid

					world.callScriptedEntity(buffer,"receivedLiquidPumpInput")
				end
			end
		end
		self.timer2 = dt * ((hasMovedLiquid and not isInstance) and 1 or 0)
		object.setAllOutputNodes(storage.currentState)
		animate()
	else
		self.timer2 = self.timer2 - dt
	end
end
