require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weaponammo.lua"

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end

  if self.weapon.reloadParam then
	activeItem.setInstanceValue("tooltipFields",{ammoNameLabel = "Energy",ammoIconImage = "/interface/tooltips/energy.png"})
  end

  self.debug = ""

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
	--world.debugText(animator.animationState("gunState").." Ammo: "..tostring(self.weapon.ammoAmount).."/"..tostring(self.weapon.ammoMax).." "..tostring(config.getParameter("ammoName")),{mcontroller.position()[1]-1,mcontroller.position()[2]-3.5},"red")

	world.debugText(self.debug,{mcontroller.position()[1]-1,mcontroller.position()[2]-3.5},"red")

	if config.getParameter("extraAmmo") then
		local extraStorage = config.getParameter("extraAmmoList")
		for k,v in pairs(extraStorage) do
			if v >= 0 then
				world.spawnItem(k,mcontroller.position(),v,_)
				self.debug = self.debug..", "..k.." : "..v
				extraStorage[k] = nil
			end
		end
		activeItem.setInstanceValue("extraAmmo",false)
		activeItem.setInstanceValue("extraAmmoList",extraStorage)
	end

	extraStorage = config.getParameter("tooltipFields")

	if self.weapon.ammoAmount == 0 then
		if not self.weapon.reloadParam then
			extraStorage["ammoNameLabel"] = "empty"
			extraStorage["ammoIconImage"] = ""
		end
		if animator.animationState("gunState") == "armed" then
			animator.setAnimationState("gunState","empty")
		end
	elseif animator.animationState("gunState") == "empty" then
		animator.setAnimationState("gunState","armed")
	end

	extraStorage["ammoAmountLabel"]=self.weapon.ammoAmount.."/"..self.weapon.ammoMax
	activeItem.setInstanceValue("tooltipFields",extraStorage)

end

function uninit()
  self.weapon:uninit()
end
