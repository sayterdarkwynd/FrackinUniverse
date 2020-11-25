function init()
	fTickRate = config.getParameter("tickRate", 60)
	fTickAmount = config.getParameter("tickAmount", 1)
	--species = world.entitySpecies(entity.id())
	timer = 20
        script.setUpdateDelta(fTickRate)
end

function update(dt)
 if timer <= 0 then
  world.spawnMonster("maggotcritter",mcontroller.position())
  timer = 2
 else
   timer = timer - dt
 end
end

function uninit()

end
