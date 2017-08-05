require'/scripts/power.lua'

liquids = {
  aethersea = {liquid=100,cooldown=2},
  moon = {liquid=49,cooldown=2},
  moon_desert = {liquid=49,cooldown=2},
  moon_shadow = {liquid=49,cooldown=2},
  moon_stone = {liquid=49,cooldown=2},
  moon_volcanic = {liquid=49,cooldown=2},
  moon_toxic = {liquid=49,cooldown=2},
  atropus = {liquid=53,cooldown=2},
  atropusdark = {liquid=53,cooldown=2},
  fugasgiant = {liquid=62,cooldown=2},
  bog = {liquid=12,cooldown=2},
  chromatic = {liquid=69,cooldown=2},
  crystalmoon = {liquid=43,cooldown=2},
  nitrogensea = {liquid=56,cooldown=2},
  infernus = {liquid=2,cooldown=2},
  infernusdark = {liquid=2,cooldown=2},
  slimeworld = {liquid=13,cooldown=2},
  strangesea = {liquid=41,cooldown=2},
  sulphuric = {liquid=46,cooldown=2},
  tarball = {liquid=42,cooldown=2},
  toxic = {liquid=3,cooldown=2},
  metallicmoon = {liquid=52,cooldown=3},
  lightless = {liquid=100,cooldown=3},
  penumbra = {liquid=60,cooldown=4},
  protoworld = {liquid=44,cooldown=5},
  irradiated = {liquid=47,cooldown=2},
  other = {liquid=1,cooldown=2}
}

function init()
  object.setInteractive(true)
  storage.timer = storage.timer or 1
  power.init()
end

function update(dt)
  if storage.timer > 0 then
    if power.consume(config.getParameter('isn_requiredPower')*dt) then
	  animator.setAnimationState("machineState", "active")
      storage.timer = math.max(storage.timer - dt)
	else
      animator.setAnimationState("machineState", "idle")
	end
  elseif storage.timer == 0 then
	local liquid = world.liquidAt(entity.position())
	local value = liquids[world.type()] or liquids.other
    if not liquid or (liquid[2] <= 0.5 and liquid[1] == value.liquid) then
	  world.spawnLiquid(entity.position(),value.liquid,0.5)
	  storage.timer = value.cooldown
	end	  
  end
  power.update(dt)
end