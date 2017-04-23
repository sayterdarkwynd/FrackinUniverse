
--[[for k, v in pairs(items) do
    if v.name == "sapling" then]]--
function init()
	prep()
end

function prep()
	if self.hasPrepped == false then
	storage.heldItems = world.containerItems(entity.id())
	self.pause = false
	self.hasPrepped = true
	end
end

function containerCallback()
    local items = world.containerItems(entity.id())
    -- sb.logInfo("ITEM IS: %s", items)
	-- for k, v in pairs(items) do
	   -- sb.logInfo("Item: %s", v)
	-- end
    if items[1]~=null and items[2]~=null and
       items[1].name == "sapling" and items[2].name == "sapling" then
	local leafsample = items[2]
	local stemsample = items[1]
	local biomatteramount = leafsample.count + stemsample.count
	stemsample.parameters["foliageHueShift"] = leafsample.parameters["foliageHueShift"]
	stemsample.parameters["foliageName"] = leafsample.parameters["foliageName"]
	world.containerTakeAll(entity.id())
	stemsample.count = biomatteramount
	world.containerPutItemsAt(entity.id(),stemsample,1)
    end
end

function die()

end