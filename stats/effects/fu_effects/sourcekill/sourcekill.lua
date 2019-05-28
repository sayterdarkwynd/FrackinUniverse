function init()
	source={}
	source.id=effect.sourceEntity()
	source.hp=world.callScriptedEntity(source.id,"status.resourceMax","health")
	world.callScriptedEntity(source.id,"status.applySelfDamageRequest",{
			damageType = "IgnoresDef",
			damage = source.health,
			sourceEntityId = source.id
		}
	)
end