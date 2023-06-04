require "/scripts/util.lua"

local CSAILoldInit = init

function init()
	if world.type() ~= "unknown" and config.getParameter("uniqueId") then
		object.smash()
	end

	if CSAILoldInit then CSAILoldInit() end
	object.setConfigParameter("retainScriptStorageInItem", true)
	self.fallback = false
	storage.data = storage.data or {}
	storage.imageconfig = storage.imageconfig or nil
	object.setAnimationParameter("imageConfig", storage.imageconfig)

	--there are too many similar handlers, but I'm too tired to rewrite now, and later I'll be too lazy because it'd work anyway, rip this
	message.setHandler("setFallback", function(_,_, value) self.fallback = value end)
	message.setHandler("storeData", function(_,_, widget, data) storage.data[widget] = data end)
	message.setHandler("returnData", function() return storage.data end)
	message.setHandler("screwdriverInteraction", function() return {config.getParameter("screwdriverInteractAction"), config.getParameter("screwdriverInteractData")} end) --also this is probably a super shitty way to handle this but maybe I'll use that screwdriver for other things later
	message.setHandler("setImage", function(_,_, imageconfig)
		storage.imageconfig = imageconfig
		object.setAnimationParameter("imageConfig", imageconfig)
	end)
	message.setHandler("setInterfaceObj", function(_,_, itemDesc) storage.interfaceObjIDesc = itemDesc end)
	message.setHandler("gibInterfaceObj", function() return storage.interfaceObjIDesc end)
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
		elseif not self.fallback then
			return {config.getParameter("interactAction"), config.getParameter("interactData")}
		else
			return {config.getParameter("fallbackInteractAction"), config.getParameter("fallbackInteractData")}
		end
	end
end
