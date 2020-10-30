-- first research. allows leaving the ship
function unlockTeleportation(name)
end

-- play a specific cinematic when research is completed on a node
function PlayCinematic(name)
	self.cinematicToPlay = config.getParameter("cinematicToPlay")
	player.playCinematic(self.theParameter)
end


-- increase madness upon researching node
function increaseMadness(name)
end

-- gain random research bonus
function randomResearchBonus(name)
end