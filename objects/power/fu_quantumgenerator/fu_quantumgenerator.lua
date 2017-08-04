require '/scripts/power.lua'

function init()
  heat = config.getParameter('heat')
  power.init()
end
function update(dt)
  if storage.fueltime and storage.fueltime > 0 then
    storage.fueltime = math.max(storage.fueltime - dt,0)
  end
  if (not storage.fueltime or storage.fueltime == 0) and not object.getInputNodeLevel(0) then
    storage.powermod = nil
    item = world.containerItemAt(entity.id(),0)
	if item then
	  itemlist = config.getParameter('acceptablefuel')
	  for key,value in pairs(itemlist) do
	    if item.name == key then
	      world.containerConsumeAt(entity.id(),0,1)
	      storage.fueltime = value
		  storage.powermod = value
		end
	  end
	end
  end
  if storage.fueltime and storage.fueltime > 0 then
    storage.heat = math.min((storage.heat or 0) + dt*5,100)
  else
    storage.heat = math.max((storage.heat or 0) - dt*5,0)
  end
  for i=1,#heat do
    if storage.heat >= heat[i].minheat then
	  power.setPower(heat[i].power + (storage.powermod or 0))
	  local light = config.getParameter("lightColor", heat[i].light)
	  local brightness = math.min(0.75,0.75*(storage.heat/90))
	  light[1] = math.floor(light[1]*0.25 + light[1]*brightness)
      light[2] = math.floor(light[2]*0.25 + light[2]*brightness)
      light[3] = math.floor(light[3]*0.25 + light[3]*brightness)
	  object.setLightColor(light)
	  object.setSoundEffectEnabled(heat[i].sound)
	  for key,value in pairs(heat[i].animator) do
	    animator.setAnimationState(key, value)
	  end
	  break
	end
  end
  power.update(dt)
end