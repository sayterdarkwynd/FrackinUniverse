require "/scripts/util.lua"
require "/stats/effects/fu_armoreffects/new/fuSetBonusBase.lua"

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of fuSetBonusBase. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from fuSetBonusBase. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

fuDefaultSetBonus = fuSetBonusBase:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuSetBonusBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
    They should not need to be modified (apart from the class name). ]]--

function init()
  local config_file = config.getParameter("configPath")
  fuDefaultSetBonus:init(tostring(config_file))
end

function uninit()
  fuDefaultSetBonus:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update()
  fuDefaultSetBonus:update()
end
