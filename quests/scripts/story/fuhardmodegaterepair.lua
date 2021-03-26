require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/portraits.lua"

function init()
	self.descriptions = config.getParameter("descriptions")
	self.gateUid = config.getParameter("targetUid","ancientgate2")
	self.instanceWorld=config.getParameter("instanceWorld")
	self.currentWorld=world.type()
	self.estherUid = config.getParameter("estherUid")
	setPortraits()
end

function questStart()
end

function update(dt)
	hardmodeGateRepairTimer=(hardmodeGateRepairTimer or 0.0)-dt
	if hardmodeGateRepairTimer<=0.0 then
		if storage.complete then
			quest.setObjectiveList({{self.descriptions.findEsther, false}})
		elseif (self.instanceWorld==self.currentWorld) then
			if gateActive() then
				storage.complete=true
				quest.setObjectiveList({{self.descriptions.findEsther, false}})
			else
				quest.setObjectiveList({{self.descriptions.repairGate, false}})
			end
		else
			quest.setObjectiveList({{self.descriptions.explore, false}})
		end

		if storage.complete then
			quest.setCanTurnIn(true)
		end
	end
end

function gateActive()
	if storage.gateActive then return true end

	if not self.gatePromise then
		if self.gateUid then
			self.gatePromise = world.sendEntityMessage(self.gateUid, "isActive")
		end
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

function questComplete()
	setPortraits()
	questutil.questCompleteActions()
end
