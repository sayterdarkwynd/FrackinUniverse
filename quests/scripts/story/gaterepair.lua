require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/portraits.lua"

function init()
	self.compassUpdate = config.getParameter("compassUpdate", 0.5)
	self.descriptions = config.getParameter("descriptions")

	self.gateRepairItem = config.getParameter("gateRepairItem")
	self.gateRepairCount = config.getParameter("gateRepairCount")

	if player.hasItem({name = "statustablet", count = 1}) then
		self.gateUid = "ancientgate2"
	else
		self.gateUid = "ancientgate"
	end

	self.estherUid = config.getParameter("estherUid")

	self.findRange = config.getParameter("findRange")

	setPortraits()

	storage.stage = storage.stage or 1
	self.stages = {
		explore,
		findGate,
		collectRepairItem,
		repairGate,
		findEsther
	}

	self.state = FSM:new()
	self.state:set(self.stages[storage.stage])
end

function questInteract(entityId)
	if self.onInteract then
		return self.onInteract(entityId)
	end
end

function questStart()
	player.upgradeShip(config.getParameter("shipUpgrade"))
	self.gateUid = "ancientgate"
	if not player.hasQuest("madnessquestdata") then
		player.startQuest("madnessquestdata")
	end
end

function update(dt)
	self.state:update(dt)
	checkGate()
	if storage.stage > 1 then
		player.addTeleportBookmark(config.getParameter("outpostBookmark2"))--science outpost bookmark
	end

	if storage.stage < 5 and gateActive() then
		storage.stage = 5
		self.state:set(gateRepaired)
	end

	if storage.complete then
		quest.setCanTurnIn(true)
	end
end

function gateActive()
	if storage.gateActive then return true end

	if not self.gatePromise then
		self.gatePromise = world.sendEntityMessage(self.gateUid, "isActive")
	else
		if self.gatePromise:finished() then
			if self.gatePromise:succeeded() then
				storage.gateActive = self.gatePromise:result() == true
			end
			self.gatePromise = nil
		end
	end

	return storage.gateActive
end

function explore()
	quest.setObjectiveList({{self.descriptions.explore, false}})
	self.gateUid = config.getParameter("gateUid")

	-- Wait until the player is no longer on the ship
	local findGate = util.uniqueEntityTracker(self.gateUid, self.compassUpdate)
	while true do
		local gatePosition = findGate()
		if gatePosition then
			-- Gate is on this world, put buffer onto the exploration timer
			if world.magnitude(mcontroller.position(), gatePosition) < 60 then
				self.state:set(gateFound)
				coroutine.yield()
			end
		end
		coroutine.yield()
	end
end


function checkGate()
	--if player.hasItem({name = "fuancientkey", count = 1}) then
	if player.hasCompletedQuest("create_matterassembler") then
		self.gateUid = "ancientgate2"
	else
		self.gateUid = "ancientgate"
	end
end

function findGate()
	quest.setProgress(nil)
	quest.setObjectiveList({{self.descriptions.findGate, false}})

	-- Wait until the player is no longer on the ship
	local findThing = util.uniqueEntityTracker(self.gateUid, self.compassUpdate)

	while true do
		local result = findThing()
		questutil.pointCompassAt(result)
		if result and world.magnitude(mcontroller.position(), result) < 75 then
			self.state:set(gateFound)
		end
		coroutine.yield()
	end
end

function gateFound()
	quest.setProgress(nil)
	quest.setCompassDirection(nil)

	quest.setParameter("ancientgate", {type = "entity", uniqueId = self.gateUid})
	quest.setIndicators({"ancientgate"})

	player.radioMessage("gaterepair-gateFound1")
	player.radioMessage("gaterepair-gateFound2")
	storage.stage = 3

	util.wait(14)

	self.state:set(self.stages[storage.stage])
end

function collectRepairItem()
	checkGate()

	quest.setCompassDirection(nil)

	quest.setParameter("ancientgate", {type = "entity", uniqueId = self.gateUid})
	quest.setIndicators({"ancientgate"})

	local findThing = util.uniqueEntityTracker("ancientgate2", self.compassUpdate)
	while storage.stage == 3 do

		if player.hasItem({name = self.gateRepairItem, count = self.gateRepairCount}) then
			quest.setObjectiveList({{self.descriptions.collectRepairItem, false}})
			quest.setProgress(player.hasCountOfItem(self.gateRepairItem) / self.gateRepairCount)
			storage.stage = 4
		elseif not player.hasItem({name = self.gateRepairItem, count = self.gateRepairCount}) then
			quest.setObjectiveList({{self.descriptions.collectRepairItem, false}})
			quest.setProgress(player.hasCountOfItem(self.gateRepairItem) / self.gateRepairCount)
		end
		local result = findThing()
		questutil.pointCompassAt(result)
		coroutine.yield()
	end

	quest.setObjectiveList({})
	self.state:set(self.stages[storage.stage])
end

function repairGate()
	checkGate()

	quest.setCompassDirection(nil)
	quest.setProgress(nil)

	quest.setParameter("ancientgate", {type = "entity", uniqueId = self.gateUid})
	quest.setIndicators({"ancientgate"})

	quest.setObjectiveList({
		{self.descriptions.repairGate, false}
	})

	local findGate = util.uniqueEntityTracker(self.gateUid, self.compassUpdate)
	while storage.stage == 4 do
		questutil.pointCompassAt(findGate())

		-- Go back to last stage if player loses core fragments
		if not player.hasItem({name = self.gateRepairItem, count = self.gateRepairCount}) then
			storage.stage = 3
			self.state:set(self.stages[storage.stage])
		else
			storage.stage = 3
			quest.setObjectiveList({{self.descriptions.makeTable, false}})
			player.radioMessage("fu_start_needstricorder")
			self.state:set(self.stages[storage.stage])
		end

		coroutine.yield()
	end

	self.onInteract = nil
	self.state:set(self.stages[storage.stage])
end

function gateRepaired()
	self.onInteract = nil
	quest.setCompassDirection(nil)
	quest.setProgress(nil)
	quest.setIndicators({})

	storage.stage = 5

	player.radioMessage("gaterepair-gateOpened1")
	player.radioMessage("gaterepair-gateOpened2")
	player.radioMessage("fu_outpost1")
	player.radioMessage("fu_outpost2")

	self.state:set(self.stages[storage.stage])
end

function findEsther(dt)
	quest.setCompassDirection(nil)
	quest.setParameter("esther", {type = "entity", uniqueId = self.estherUid})
	quest.setIndicators({"esther"})
	quest.setObjectiveList({{self.descriptions.findEsther, false}})

	local trackEsther = util.uniqueEntityTracker(self.estherUid, self.compassUpdate)
	while true do
		if not storage.complete then
			local estherResult = trackEsther()
			questutil.pointCompassAt(estherResult)
			if estherResult then
				if not storage.bookmarked then
					player.addTeleportBookmark(config.getParameter("outpostBookmark"))
					storage.bookmarked = true
				end
				if world.magnitude(estherResult, mcontroller.position()) < self.findRange then
					player.playCinematic(config.getParameter("findEstherCinema"))
					storage.complete = true
				end
			end
		else
			quest.setCanTurnIn(true)
			quest.setIndicators({})
		end
		coroutine.yield()
	end
end

function questComplete()
	setPortraits()
	questutil.questCompleteActions()


	if player.hasCompletedQuest("fu_byos") then
		quest.addReward(config.getParameter("BYOSRewards"))
		quest.setCompletionText(config.getParameter("BYOSCompletionText"))
	else
		player.upgradeShip(config.getParameter("shipUpgrade2"))
		player.playCinematic(config.getParameter("shipUpgradeCinema"))
	end

	world.sendEntityMessage(player.id(), "setQuestFuelCount", 500)
	player.setUniverseFlag("outpost_mission1")
end
