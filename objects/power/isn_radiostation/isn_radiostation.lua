require "/scripts/power.lua"

function init()
  power.init()
  object.setInteractive(true)
  storage.frequencies = storage.frequencies or  config.getParameter("isn_baseFrequencies")
  storage.currentconfig = storage.currentconfig or storage.frequencies["isn_miningVendor"]
  storage.currentkey = storage.currentkey or "isn_miningVendor"
end

function onInteraction(args)
  if not storage.haspower then
	animator.burstParticleEmitter("noPower")
	animator.playSound("error")
  else
	local itemName = world.entityHandItem(args.sourceId, "primary")
	local tradingConfig = { config = storage.currentconfig, recipes = { } }
	for key, value in pairs(config.getParameter(storage.currentkey)) do
	  local recipe = { input = { { name = "money", count = value } }, output = { name = key } }
	  table.insert(tradingConfig.recipes, recipe)
	end
	return {"OpenCraftingInterface", tradingConfig}
  end
end

function update(dt)
  if power.consume(config.getParameter('isn_requiredPower')) then 
	animator.setAnimationState("anim", "on")
	object.setLightColor({30, 50, 90})
	storage.haspower = true
  else
	animator.setAnimationState("anim", "off")
	object.setLightColor({0, 0, 0})
	storage.haspower = false
  end
  power.update(dt)
end