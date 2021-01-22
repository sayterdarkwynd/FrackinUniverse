function init()
	cloningPrep()
end

function cloningPrep()
	if self.hasPrepped == false then
		storage.heldItems = world.containerItems(entity.id())
		self.pause = false
		self.hasPrepped = true
	end
end

function containerCallback()
    local items = world.containerItems(entity.id())

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