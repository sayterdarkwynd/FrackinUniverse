function init()
  self.inputPos = object.position()
  self.pumped = self.pumped or 0
  storage.ispump     = storage.ispump      or false
  storage.ispumppres = storage.ispumppres  or false
  storage.outputProtected = storage.outputProtected or false
  storage.state = storage.state or false
  output(storage.state)
  self.timer = 0
end

-- Change Animation
function output(state)
  if state ~= storage.state then
    storage.state = state
    animator.setAnimationState("pumpinState",fif(state,"on","off"))
  end
end



--call when activated
function pump(inputPos,outputPos)
    local inliq= world.liquidAt(inputPos)
    if inliq and inliq[2] > 0.1 then  --if input has liquid
        local outliq = world.liquidAt(outputPos)
        if (storage.ispumppres or (not outliq or (outliq[1] == inliq[1] and outliq[2] < 1))) then --if output has no liquid or (liquid ids are the same and outliquidlever < 2)
            if storage.outputProtected then world.setTileProtection(world.dungeonId(storage.outputPos), false) end
            world.destroyLiquid(inputPos)
            world.spawnLiquid(outputPos,inliq[1],inliq[2]*1.01)
            if storage.outputProtected then world.setTileProtection(world.dungeonId(storage.outputPos), true) end
            return true
        end
    end
    return false
end


function onInputNodeChange(args) setoutputpump()end
function onNodeConnectionChange()  setoutputpump() end

--some reason entityid is the key instead of a value in the table object.getOutputNodeIds(0).
function findpump(map)
    for k,v in pairs(map) do
        local var = world.entityName(k)
        if var == "pumpoutfuelder" or  var == "pumpoutpressurefuelder" then
            return k
        end
    end
    return false
 end


--called when anything changes with the wires, stores the location of the outputpump
function setoutputpump()
    if object.isOutputNodeConnected(0) then
        local outputid =  findpump(object.getOutputNodeIds(0))
        local var
        if not outputid then
            var = "nope"
        else
            storage.outputPos = world.entityPosition(outputid)
            var = world.entityName(outputid)
            --tile protection will break the pumps if we dont store it and toggle it before and after each pump sequence.
            storage.outputProtected = world.isTileProtected(storage.outputPos)
        end
        storage.ispump     = var == "pumpoutfuelder"
        storage.ispumppres = var == "pumpoutpressurefuelder"
    end
end


--update every dt ms
function update(dt)
    if self.timer <= 0 then
        setoutputpump()
        self.firsttime = 1000
    end
    self.firsttime = self.firsttime - 1
    local pumped = false
    if object.isOutputNodeConnected(0) and object.getInputNodeLevel(0)  then
        output(true)

        if storage.ispump or storage.ispumppres then
            pumped = pump(self.inputPos,storage.outputPos)
            pumped = pump(toright(self.inputPos),toright(storage.outputPos)) or pumped
        end
    else
        output(false)
        object.setAllOutputNodes(false)
    end
    --maintainwireoutput
    self.pumped = fif(pumped,3,self.pumped -1)
    object.setAllOutputNodes(self.pumped > 0)
end




--random helper functions
--ternary operator
function fif(condition,iftrue,iffalse)
    if condition then return iftrue else return iffalse end
end
--return one pos to the right
function toright( pos )
    return {pos[1]+1,pos[2]}
end
