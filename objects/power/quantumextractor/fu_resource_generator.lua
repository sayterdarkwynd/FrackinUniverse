require "/scripts/util.lua"
require "/scripts/kheAA/transferUtil.lua"

function init()
	object.setInteractive(true)
	self.timer = 0.05
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end

	if self.timer <= 0 then

		if isn_hasRequiredPower() == false then
			animator.setAnimationState("samplingarrayanim", "idle")
			return
		end

		if world.liquidAt(entity.position()) == true and config.getParameter("isn_liquidCollector") == false then return end

		animator.setAnimationState("samplingarrayanim", "working")

		local output
		local rarityroll = math.random(1,100)
		if rarityroll == 100 then
			output = util.randomFromList(config.getParameter("rareOutputs"))
			self.timer = 0.05
		elseif rarityroll >= 79 then
			output = util.randomFromList(config.getParameter("uncommonOutputs"))
			self.timer = 0.05
		else
			output = util.randomFromList(config.getParameter("commonOutputs"))
			self.timer = 0.05
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
