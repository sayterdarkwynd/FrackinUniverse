require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/quests/scripts/portraits.lua"
require "/quests/scripts/questutil.lua"

function init()
	self.descriptions = config.getParameter("descriptions")

	self.artifactUid = config.getParameter("artifactUid")

	self.estherUid = config.getParameter("estherUid")

	self.trackArtifact = util.uniqueEntityTracker(self.artifactUid)
	self.trackEsther = util.uniqueEntityTracker(self.estherUid)
	self.associatedMission=config.getParameter("associatedMission")
	self.currentWorld=world.type()
	message.setHandler(config.getParameter("artifactMessage", "artifactTaken"), function()
		if (not storage.artifact) and (self.currentWorld==self.associatedMission) then
			storage.artifact = true
		end
	end)

	setPortraits()
	quest.setIndicators({})
end

function questStart()
end

function questComplete()
	setPortraits()
	questutil.questCompleteActions()
end

function pointCompassAt(position)
	if storage.artifact or ((not storage.artifact) and (self.currentWorld==self.associatedMission)) then
		if position then
			local direction = world.distance(position, mcontroller.position())
			quest.setCompassDirection(vec2.angle(direction))
		elseif position == nil then
			quest.setCompassDirection(nil)
		end
	else
		quest.setCompassDirection(nil)
	end
end

function update(dt)
	if not storage.artifact then
		quest.setObjectiveList({{self.descriptions.artifact, false}})
		pointCompassAt(self.trackArtifact())
	else
		quest.setObjectiveList({{self.descriptions.turnIn, false}})
		pointCompassAt(self.trackEsther())
		quest.setCanTurnIn(true)
	end
end
