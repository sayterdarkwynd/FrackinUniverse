require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")

--================================== NOTES ==================================--
--[[
I got bored and revamped the lightning storm weather effects. What they now do:
- Apply a fixed penalty to energy regen rate and regen delay
- At semi-random intervals, cause your energy supply to "overload". This deals
    a small amount of shock damage, and drains a random percentage (depending
    on tier) of your total energy.
All of these values scale with your electric resistance. So higher electric
resistance reduces the energy regen penalties, HP and total energy damage on
overload, and frequency of the overloads.

Additional note: The electric storm status effect is only applied when outside.
Going inside (somewhere with a background wall) or underwater (I think, need to
confirm) will remove the effect. Hence the wet effect and warning do not seem
to occur very often in practice.

Additional note 2: Effects applied by weather events (electric storms, poison
gas etc.) seem to be initialised by Starbound every tick. This doesn't actually
cause problems, as it seems the new instance it uninitialised instantly...
However, it's pretty poor form performance-wise. Not sure if there's any way
to fix it.

-Wannas (Wannas16)
]]--

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of fuWeatherBase. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from fuWeatherBase. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

fuElectricWeather = fuWeatherBase:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuWeatherBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

function fuElectricWeather.init(self, config_file)
  local effectConfig = self.parent.init(self, config_file)
  self.shockParams = effectConfig.shockParams
  self.shockTimer = self.shockParams.baseDelay + math.random() * self.shockParams.randomDelay
end

function fuElectricWeather.applyShock(self, modifier)
  -- Cap modifier between 0.25 and 1.25.
  local cappedMod = math.max(math.min(modifier, 1.25), 0.25)
  local rMulti = math.random()
  local healthDamage = (self.shockParams.baseHealth + rMulti * self.shockParams.randomHealth) * cappedMod
  local energyPercent = (self.shockParams.baseEnergy + rMulti * self.shockParams.randomEnergy) * cappedMod
  -- Apply health damage (as shock) and energy damage.
  self:applySelfDamage(healthDamage, "electric")
  if status.isResource("energy") then
    local energyDrain = math.min(status.resource("energy"), status.stat("maxEnergy") * energyPercent)
    status.modifyResource("energy", -energyDrain)
  end
end

function fuElectricWeather.update(self, dt)
  local modifier = self.parent.update(self, dt)
  -- Stop if the modifier was zero (the player is not affected).
  if (modifier == 0) then
    return
  end
  -- Shock the player (damage HP and energy) at semi-random intervals.
  self.shockTimer = math.max(self.shockTimer - dt, 0)
  if (self.shockTimer == 0) then
    self:applyShock(modifier)
    self.shockTimer = self.shockParams.baseDelay + math.random() * self.shockParams.randomDelay
  end
end


--============================= GRAPHICAL EFFECTS ============================--

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
    They should not need to be modified (apart from the class name). ]]--

function init()
  local config_file = config.getParameter("configPath")
  fuElectricWeather:init(tostring(config_file))
end

function uninit()
  fuElectricWeather:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
  fuElectricWeather:update(dt)
end
