function init()
	targetObject=config.getParameter("targetForReplace","futurelight")
	targetRoll=config.getParameter("targetCadaverRoll",math.huge)
	world.placeObject(targetObject,entity.position(),object.direction(),{cadaverRoll=targetRoll})
	object.smash(true)
end
