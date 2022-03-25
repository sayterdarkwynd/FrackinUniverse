require "/scripts/kheAA/transferUtil.lua"

function init()
    transferUtil.init()
    message.setHandler("transferUtil.sendConfig", transferUtil.sendConfig)
    message.setHandler("transferItem", transferItem)
    object.setInteractive(true)
end

function update(dt)
    deltaTime = (deltaTime or 0) + dt
    if deltaTime >= 1 then
        deltaTime = 0
    else
        return
    end
    transferUtil.updateInputs(transferUtil.vars.inDataNode)
end

function transferItem(_, _, itemData)
    -- dbg(itemData)
    -- itemData={containerID, index}, itemDescriptor, itemConfig,pos
    local source = itemData[1][1]
    if type(source) == "string" then source = tonumber(source) end
    local sourcePos = itemData[4]
    local targetPos = itemData[5]
    local slot = itemData[1][2]
    local count = itemData[2].count
    local awake, newId = transferUtil.containerAwake(source, sourcePos)
    if not (awake == true) then
        return
    else
        if newId ~= nil then source = newId end
        local item = world.containerTakeNumItemsAt(source, slot - 1, count)
        if item ~= nil then
            world.spawnItem(item, targetPos or entity.position())
        end
    end
end

function transferUtil.sendConfig()
    local buffer = {}
    for id, pos in pairs(transferUtil.vars.inContainers or {}) do
        local awake, newId = transferUtil.containerAwake(id, pos)
        if awake then
            id = newId or id
            buffer[id] = pos
        end
    end
    transferUtil.vars.inContainers = buffer
    return transferUtil.vars
end

