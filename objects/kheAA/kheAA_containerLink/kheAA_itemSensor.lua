require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	self.linkRange=config.getParameter("linkRange",4)
end

function update(dt)
	deltatime = (deltatime or 0) + dt;
	if deltatime < 1 then
		return;
	end
	deltatime=0
	local buffer=world.itemDropQuery(storage.position, self.linkRange, { order = "nearest" })
	local itemFound=(util.tableSize(buffer) > 0)
	--later might introduce detection of specific item drops. for now...nah
	--[[if util.tableSize(buffer) > 0 then
		itemFound=true
	end]]
	object.setOutputNodeLevel(0,itemFound)
end