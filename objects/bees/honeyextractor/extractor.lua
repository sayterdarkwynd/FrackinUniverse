require "/scripts/kheAA/transferUtil.lua"
local contents
local deltaTime=0
 
function init()
	transferUtil.init()
	self.initialCraftDelay = 3
	self.craftDelay = self.craftDelay or self.initialCraftDelay
	self.inputSlot = 3 -- for use in honeyCheck()
end
 
function update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	local contents = world.containerItems(entity.id())
	if contents[3] and contents[2] and contents[2].name == 'emptyhoneyjar' then
		if not workingCombs(contents) then
			-- reset crafting delay if indicated
			self.craftDelay = self.initialCraftDelay
		end
	end
end

function workingCombs(contents)
	-- returns true if the delay is NOT to be reset
	local jar = honeyCheck()
	if not jar then return end

	self.craftDelay = self.craftDelay - 1
	if self.craftDelay > 0 then return true end

	self.craftDelay = self.initialCraftDelay

	-- check that we have enough resources; recipes say 3 combs and one jar
	if contents[2].count < 1 or contents[3].count < 3 then return end

	-- try to add a honey jar; if this fails, we bail without consuming anything
	if world.containerAddItems(entity.id(), { name = jar, count = 1, data={} }) then return end

	-- okay, succeeded
	world.containerConsumeAt(entity.id(), 1, 1) -- consume one jar
	world.containerConsumeAt(entity.id(), 2, 3) -- consume three combs
	return true
end
