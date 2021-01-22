require "/scripts/util.lua"
require "/stats/effects/fu_armoreffects/new/SetBonusHelper.lua"

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of SetBonusHelper. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from SetBonusHelper. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

RegenSetBonus = SetBonusHelper:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuSetBonusBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

function RegenSetBonus.init(self)
  self.parent.init(self)
  -- Set up parameters for health regen.
  self.healthRegen = config.getParameter("healthRegen")
  self.regenHandler=effect.addStatModifierGroup({})
end

function RegenSetBonus.update(self, dt)
  self.parent.update(self)
  --local healPercent = self.healthRegen * dt
  --status.modifyResourcePercentage("health", healPercent)
  effect.setStatModifierGroup(self.regenHandler,{{stat="healthRegen",amount=status.resourceMax("health")*self.healthRegen*math.max(0,1+status.stat("healingBonus"))}})
end

function RegenSetBonus.uninit(self)
	effect.removeStatModifierGroup(self.regenHandler)
end

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
    They should not need to be modified (apart from the class name). ]]--

function init()
  RegenSetBonus:init()
end

function uninit()
  RegenSetBonus:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
  RegenSetBonus:update(dt)
end
