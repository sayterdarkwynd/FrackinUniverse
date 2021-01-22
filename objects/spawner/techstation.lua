require "/objects/ship/fu_byospethouse/fu_byospethouse.lua"

local petInit = init or function() end
local petUpdate = update or function() end

function init()
	self.purchasablePetsPresent = root.itemConfig("pethouseSlime") and true
	self.objectName = object.name()

	if not self.purchasablePetsPresent or self.objectName == "fu_byostechstation" then
		petInit()
	end

	message.setHandler("activateShip", function()
		animator.playSound("shipUpgrade")
		self.dialog = config.getParameter("dialog.wakeUp")
		self.dialogTimer = 0.0
		self.dialogInterval = 5.0
		self.drawMoreIndicator = true
		object.setOfferedQuests({})
	end)

	message.setHandler("wakePlayer", function()
		self.dialog = config.getParameter("dialog.wakePlayer")
		self.dialogTimer = 0.0
		self.dialogInterval = 14.0
		self.drawMoreIndicator = false
		object.setOfferedQuests({})
	end)
end

function onInteraction()
	if self.dialogTimer then
		sayNext()
		return nil
	else
		if world.getProperty("ship.level", 1) == 0 and not world.getProperty("fu_byos") then
			local miscShipConfig = root.assetJson("/frackinship/configs/misc.config")
			local interface = root.assetJson(miscShipConfig.shipSelctionInterface)
			interface = util.mergeTable(interface, miscShipConfig.shipResetSelectionInterfaceData or {})
			return {"ScriptPane", interface}
		else
			local interactAction=config.getParameter("interactAction")
			local interactData=config.getParameter("interactData")

			if interactAction and interactData then
				return {interactAction, interactData}
			elseif interactAction then
				return interactAction
			else
				return nil
			end
		end
	end
end

function sayNext()
	if self.dialog and #self.dialog > 0 then
		if #self.dialog > 0 then
			local options = {
				drawMoreIndicator = self.drawMoreIndicator
			}
			self.dialogTimer = self.dialogInterval
			if #self.dialog == 1 then
				options.drawMoreIndicator = false
				self.dialogTimer = 0.0
			end

			object.sayPortrait(self.dialog[1][1], self.dialog[1][2], nil, options)
			table.remove(self.dialog, 1)

			return true
		end
	else
		self.dialog = nil
		return false
	end
end

function update(dt)
	if not self.purchasablePetsPresent or self.objectName == "fu_byostechstation" then
		petUpdate(dt)
	end

	if self.dialogTimer then
		self.dialogTimer = math.max(self.dialogTimer - dt, 0.0)
		if self.dialogTimer == 0 and not sayNext() then
			self.dialogTimer = nil
		end
	end

	if self.dialogTimer == nil then
		object.setOfferedQuests(config.getParameter("offeredQuests"))
	end
end
