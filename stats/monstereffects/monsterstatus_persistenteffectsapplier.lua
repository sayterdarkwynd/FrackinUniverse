local fu_monsters_init = init

function init()
	if fu_monsters_init then
		fu_monsters_init()
	end
	self.monsterPersistentEffects=config.getParameter("fu_monsterPersistentEffects",{})
	status.setPersistentEffects("fu_monsterPersistentEffects",self.monsterPersistentEffects)
end
