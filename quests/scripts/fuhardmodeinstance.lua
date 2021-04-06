require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"

function init()
	self.descriptions = config.getParameter("descriptions")

	self.warpAction = config.getParameter("warpAction")

	self.goalTrigger = config.getParameter("goalTrigger", "proximity")

	self.goalEntity = config.getParameter("goalEntityUid")
	self.trackGoalEntity = config.getParameter("trackGoalEntity", false)
	self.indicateGoal = config.getParameter("indicateGoal", false)

	self.turnInEntity = config.getParameter("turnInEntityUid")
	self.currentWorld=world.type()
	if self.goalTrigger == "proximity" then
		self.proximityRange = config.getParameter("proximityRange", 20)
	elseif self.goalTrigger == "interact" then
		self.interactEntity = config.getParameter("interactEntityUid")

		self.goalInteract = function(entityId)
			if world.entityUniqueId(entityId) == self.interactEntity then
				storage.stage = 3
			end
		end
	elseif self.goalTrigger == "message" then
		self.triggerMessage = config.getParameter("triggerMessage")

		message.setHandler(self.triggerMessage, function()
			storage.stage = 3
		end)
	end

	setPortraits()

	self.stages = {
		enterInstance,
		findGoal,
		turnIn
	}

	storage.stage = storage.stage or 1
	self.state = FSM:new()
	self.state:set(self.stages[storage.stage])
end

function questStart()
end

function update(dt)
	self.state:update()
end

function questInteract(entityId)
	if self.onInteract then
		return self.onInteract(entityId)
	end
end

function questComplete()
	setPortraits()

	questutil.questCompleteActions()
end

function enterInstance(dt)
	quest.setCompassDirection(nil)
	quest.setObjectiveList({
		{self.descriptions.enterInstance, false}
	})

	local findGoalEntity = util.uniqueEntityTracker(self.goalEntity, 1.0)
	while storage.stage == 1 do
		quest.setCompassDirection(nil)
		if findGoalEntity() then
			storage.stage = 2
		end
		coroutine.yield()
	end
	self.state:set(self.stages[storage.stage])
end

function findGoal(dt)
	quest.setCompassDirection(nil)
	quest.setObjectiveList({
		{self.descriptions.findGoal, false}
	})
	quest.setIndicators({})
	self.onInteract = nil

	if self.indicateGoal then
		quest.setParameter("goalentity", {type = "entity", uniqueId = self.goalEntity})
		quest.setIndicators({"goalentity"})
	end

	if self.goalTrigger == "interact" then
		self.onInteract = self.goalInteract
	end

	local findGoalEntity = util.uniqueEntityTracker(self.goalEntity, 0.5)
	while storage.stage == 2 do
		local goalPosition = findGoalEntity()
		if self.trackGoalEntity then
			questutil.pointCompassAt(goalPosition)
		end

		if (self.warpAction==self.currentWorld) and (self.goalTrigger == "proximity" and goalPosition) then
			if world.magnitude(mcontroller.position(), goalPosition) < self.proximityRange then
				storage.stage = 3
			end
		end

		if goalPosition == nil then
			storage.stage = 1
		end

		coroutine.yield()
	end

	self.state:set(self.stages[storage.stage])
end

function turnIn()
	quest.setCompassDirection(nil)
	quest.setObjectiveList({
		{self.descriptions.turnIn, false}
	})
	quest.setIndicators({})
	self.onInteract = nil

	if self.turnInEntity then
		quest.setCanTurnIn(true)

		local findTurnInEntity = util.uniqueEntityTracker(self.turnInEntity, 0.5)
		while true do
			questutil.pointCompassAt(findTurnInEntity())
			coroutine.yield()
		end
	else
		quest.complete()
	end
end
