function init()
	source={}
	source.id=effect.sourceEntity()
	world.callScriptedEntity(source.id,"status.applySelfDamageRequest",{
			damageType = "IgnoresDef",
			damage = math.huge
		}
	)
end