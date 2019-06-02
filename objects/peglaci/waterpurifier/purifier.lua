function main()
	if world.liquidAt(entity.toAbsolutePosition({ 0.0, 10 })) == null then
      world.spawnProjectile("purewater", entity.toAbsolutePosition({ 0.0, 0.0 }), entity.id(), { 0, -5 }, false, {})
    end
end