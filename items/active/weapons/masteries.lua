require "/items/active/tagCaching.lua" --integral to mastery identification
masteries={}
--vars are temporary, and are reset if weapons are swapped
masteries.vars={}
--these two are for SETS of modifiers/statuses to apply.
masteries.vars.ephemeralEffects={}
masteries.vars.controlModifiers={}
--need a persistent set for the heartbeat
masteries.persistentVars={}
--stats are loaded by masteries.load every update.
masteries.stats={}
--listeners are not reset by weapon swap, instead they reset with roughly after a second (see fustatusextenderquest.lua)
masteries.listeners={}
--timers are in the form of key:{value,directionMultiplier,(optional)max}. DO NOT put anything directly in masteries.timers itself, it is not designed for that.
masteries.timers={}
masteries.timers.primary={}
masteries.timers.alt={}
--probably never seeing use, but option for dual wield.
masteries.timers.both={}
--this is an option for later
--masteries.timers.other={}

function masteries.apply(args)
	if activeItem then error("masteries.lua: Masteries don't belong in activeitem scripts. Stop trying.") end
	for hand,data in pairs(masteries.timers) do
		for var,set in pairs(data) do
			local e=set[1]+(args.dt*set[2])
			if set[3] then
				if set[2]>0 then e=math.min(e,set[3])
				elseif set[2]<0 then e=math.max(e,set[3])
				else error(string.format("You nitwit, timer variables in masteries must be either positive or negative! %s isn't either.",var))
				end
			end
			masteries.timers[hand][var][1]=e
			--sb.logInfo("masteries.timers: hand %s, var %s, set %s, change to %s",hand,var,set,e)
		end
	end
	--if weapon is wielded alongside another weapon, cut the bonuses in half.
	--here, we don't ASSUME that the weapon type is only in one hand, because anyone can slap the 'broadsword' tag on a fucking onehanded weapon.
	local dualWield=(tagCaching["primaryTagCache"]["weapon"] and tagCaching["altTagCache"]["weapon"])
	--due to implementation this has...awkward results I may need to adjust. mostly because 1.05*1.05 is not 1.1, it is 1.1025. the difference is negligible, and fixing this would need a recode to use sqrt instead for multipliers.
	local handMultiplier=(dualWield and 0.5) or 1.0

	--if either item changed, readjust buffs.
	if args["primaryChanged"] or args["altChanged"] then
		--these two are for SETS of modifiers/statuses to apply.
		masteries.vars.ephemeralEffects={}
		masteries.vars.controlModifiers={}
		--handle each combination in turn.
		for currentHand,otherHand in pairs({primary="alt",alt="primary"}) do
			--rather than applying dozens of separate effects...we just build a single list to apply.
			local masteryBuffer={}

			--trying to reduce code overhead by adding checks for melee/ranged/staff fails, sadly. because vanilla shit like fist weapons or wands/staves

			--bonuses to ammo and reload time for certain specific weapontypes that tend to be ammo based.
			--magazine bonuses for these work best when done in a hybrid manner like this. means they get roughly the same overall increase.
			--magazineMultiplier is a stat to multiply base magazine size (tooltip on weapon)
			if tagCaching[currentHand.."TagCache"]["ranged"] then
				masteryBuffer[#masteryBuffer + 1]={stat="magazineMultiplier", amount=(masteries.stats.ammoMastery*handMultiplier) }
				masteryBuffer[#masteryBuffer + 1]={stat="magazineSize", amount=4*masteries.stats.ammoMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="reloadTime", amount=(-1/3)*masteries.stats.ammoMastery*handMultiplier}
			end

			--pistols: reduced Reload time, increased crit chance and damage
			if tagCaching[currentHand.."TagCache"]["pistol"] then
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.pistolMastery*handMultiplier) }
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=(1/4)*masteries.stats.pistolMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="reloadTime", amount=(-1/4)*masteries.stats.pistolMastery*handMultiplier}
			end

			--machine pistols: increased power & crit chance. reduced Reload time.
			if tagCaching[currentHand.."TagCache"]["machinepistol"] then
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.machinepistolMastery*handMultiplier/2) }
				masteryBuffer[#masteryBuffer + 1]={stat="reloadTime", amount=(-1/4)*masteries.stats.machinepistolMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=(1/2)*masteries.stats.machinepistolMastery*handMultiplier}
			end

			--arm cannons: increased damage, defense. increased crit damage or crit chance.
			--values based on how many arm cannons and/or shields are equipped.
			if tagCaching[currentHand.."TagCache"]["armcannon"] then
				local powerModifier=(masteries.stats.armcannonMastery*handMultiplier)
				local critChanceModifier=(masteries.stats.armcannonMastery*handMultiplier)
				local critDamageModifier=(masteries.stats.armcannonMastery*handMultiplier)
				local protectionModifier=(masteries.stats.armcannonMastery*handMultiplier)
				if tagCaching[otherHand.."TagCache"]["armcannon"] then
					--dual arm cannons: full power bonus, half protection bonus, grant crit chance instead of crit damage
					critChanceModifier=critChanceModifier*2.0
					critDamageModifier=0.0
					protectionModifier=protectionModifier/2
				elseif tagCaching[otherHand.."TagCache"]["shield"] then
					--with a shield: 1/3 power bonus, full crit damage bonus, full protection bonus
					powerModifier=powerModifier/3.0
					critChanceModifier=0.0
				else
					--every other case: the only part of this that needs to be kept is the crit modifier, due to the hand multiplier
					--powerModifier=powerModifier/2.0
					critChanceModifier=0.0
					--protectionModifier=protectionModifier/2
				end
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+powerModifier}
				masteryBuffer[#masteryBuffer + 1]={stat="protection", effectiveMultiplier=1+protectionModifier}
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=2*critChanceModifier}
				masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=0.3*critDamageModifier}
			end

			--assault rifles: increased damage, magazine, crit damage
			if tagCaching[currentHand.."TagCache"]["assaultrifle"] then
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.assaultrifleMastery*handMultiplier/2) }
				--{stat="magazineMultiplier", amount=(masteries.stats.assaultrifleMastery*handMultiplier/2) })
				--{stat="magazineSize", amount=2*masteries.stats.assaultrifleMastery*handMultiplier})
				masteryBuffer[#masteryBuffer + 1]={stat="magazineSize", amount=(1/2)*masteries.stats.assaultrifleMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=(0.3/2)*masteries.stats.assaultrifleMastery*handMultiplier}
			end

			--sniper rifles: increased magazine, crit chance
			if tagCaching[currentHand.."TagCache"]["sniperrifle"] then
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=(1/2)*masteries.stats.sniperrifleMastery*handMultiplier}
				--masteryBuffer[#masteryBuffer + 1]={stat="magazineMultiplier", amount=(masteries.stats.sniperrifleMastery*handMultiplier/2) }
				--masteryBuffer[#masteryBuffer + 1]={stat="magazineSize", amount=2*masteries.stats.sniperrifleMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="magazineSize", amount=(1/2)*masteries.stats.sniperrifleMastery*handMultiplier}
			end

			--grenade launchers: increased power, magazine size. reduced reload time
			if tagCaching[currentHand.."TagCache"]["grenadelauncher"] then
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.grenadelauncherMastery*handMultiplier/2) }
				masteryBuffer[#masteryBuffer + 1]={stat="reloadTime", amount=(-1/4)*masteries.stats.grenadelauncherMastery*handMultiplier}
				--{stat="magazineMultiplier", amount=(masteries.stats.grenadelauncherMastery*handMultiplier/2) })
				--{stat="magazineSize", amount=2*masteries.stats.grenadelauncherMastery*handMultiplier})
				masteryBuffer[#masteryBuffer + 1]={stat="magazineSize", amount=(1/2)*masteries.stats.grenadelauncherMastery*handMultiplier}
			end

			--rocket launchers: increased power, magazine size. reduced reload time
			if tagCaching[currentHand.."TagCache"]["rocketlauncher"] then
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.rocketlauncherMastery*handMultiplier/2) }
				masteryBuffer[#masteryBuffer + 1]={stat="reloadTime", amount=(-1/4)*masteries.stats.rocketlauncherMastery*handMultiplier}
				--{stat="magazineMultiplier", amount=(masteries.stats.rocketlauncherMastery/2) })
				--{stat="magazineSize", amount=2*masteries.stats.rocketlauncherMastery})
				masteryBuffer[#masteryBuffer + 1]={stat="magazineSize", amount=(1/2)*masteries.stats.rocketlauncherMastery*handMultiplier}
			end

			--shotguns: increased Power, Magazine Size, Crit Chance
			if tagCaching[currentHand.."TagCache"]["shotgun"] then
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.shotgunMastery*handMultiplier/2) }
				masteryBuffer[#masteryBuffer + 1]={stat="reloadTime", amount=(-1/4)*masteries.stats.shotgunMastery*handMultiplier}
				--{stat="magazineMultiplier", amount=(masteries.stats.shotgunMastery*handMultiplier/2) },
				--{stat="magazineSize", amount=2*masteries.stats.shotgunMastery*handMultiplier},
				masteryBuffer[#masteryBuffer + 1]={stat="magazineSize", amount=(1/2)*masteries.stats.shotgunMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=(1/4)*masteries.stats.shotgunMastery*handMultiplier}
			end

			--magnorbs: damage, crit chance/damage, max energy
			if tagCaching[currentHand.."TagCache"]["magnorb"] then
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.magnorbMastery*handMultiplier) }
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=2*masteries.stats.magnorbMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=0.15*masteries.stats.magnorbMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="maxEnergy", effectiveMultiplier=1+(masteries.stats.magnorbMastery*handMultiplier/2) }
			end

			--bows: crit chance, crit damage, faster draw time, reduced cost to fire/hold, increased damage.
			if tagCaching[currentHand.."TagCache"]["bow"] then
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=2*masteries.stats.bowMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=0.35*masteries.stats.bowMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="bowDrawTimeBonus", amount=(0.01/2)*masteries.stats.bowMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="bowEnergyBonus", amount=(1/2)*masteries.stats.bowMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.bowMastery*handMultiplier) }
				masteryBuffer[#masteryBuffer + 1]={stat="arrowSpeedMultiplier", effectiveMultiplier=1+(masteries.stats.bowMastery*handMultiplier) }
				table.insert(masteries.vars.controlModifiers,{speedModifier=1+(masteries.stats.bowMastery*handMultiplier/8) })
			end

			--whips: damage, crit chance/damage
			if tagCaching[currentHand.."TagCache"]["whip"] then
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.whipMastery*handMultiplier) }
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=1*masteries.stats.whipMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=(0.25/2)*masteries.stats.whipMastery*handMultiplier}
			end

			--daggers:dodge tech and damage boost, combo based protection and crit chance.
			--also: when paired with another melee of any kind, grants a speed boost status effect. (why? why not just apply a control modifier?)
			if tagCaching[currentHand.."TagCache"]["dagger"] then
				local protectionModifier=(masteries.stats.daggerMastery/2)
				local critModifier=0
				if masteries.vars[currentHand.."Firing"] then
					--protectionModifier=protectionModifier+(1/(math.max(1,masteries.vars[currentHand.."ComboStep"])*6))--was *4. adjusted.
					protectionModifier=protectionModifier+((masteries.vars[currentHand.."ComboStep"]/4)*0.25)
					critModifier=masteries.vars[currentHand.."ComboStep"]*(1+(masteries.stats.daggerMastery*handMultiplier))
				end
				masteryBuffer[#masteryBuffer + 1]={stat="dodgetechBonus", amount=0.25*(1+(masteries.stats.daggerMastery*handMultiplier)) }
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.daggerMastery*handMultiplier/4) }
				masteryBuffer[#masteryBuffer + 1]={stat="protection", effectiveMultiplier=1+(protectionModifier*handMultiplier)}
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=critModifier }
				if tagCaching[otherHand.."TagCache"]["melee"] then
					table.insert(masteries.vars.ephemeralEffects,{{effect="runboost5", duration=0.02}})
				end
			end

			--quarterstaves: dodge/defense/heal tech boosts. protection boost. damage boost.
			if tagCaching[currentHand.."TagCache"]["quarterstaff"] or tagCaching[currentHand.."TagCache"]["qs"] then
				if not masteries.stats.quarterstaffMastery then masteries.stats.quarterstaffMastery=status.stat("quarterstaffMastery") end
				masteryBuffer[#masteryBuffer + 1]={stat="dodgetechBonus", amount=0.25*masteries.stats.quarterstaffMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.quarterstaffMastery*handMultiplier/2) }
				masteryBuffer[#masteryBuffer + 1]={stat="protection", effectiveMultiplier=1+(0.12*masteries.stats.quarterstaffMastery*handMultiplier) }
				masteryBuffer[#masteryBuffer + 1]={stat="defensetechBonus", amount=0.25*masteries.stats.quarterstaffMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="healtechBonus", amount=0.15*masteries.stats.quarterstaffMastery*handMultiplier}
			end

			--rapiers: complicated. dodge, dash, crit and protection modifiers based on wield state (solo, with dagger, else).
			if tagCaching[currentHand.."TagCache"]["rapier"] then
				local rapierTimerDefault={0,1,5}--when we set a timer: start at 0, increment by dt, and max at 5
				masteries.timers[currentHand]["rapierTimerBonus"]=masteries.timers[currentHand]["rapierTimerBonus"] or rapierTimerDefault--don't reset it yet.
				local dodgeModifier=0.35
				local dashModifier=0.35
				local critModifier=0
				local protectionModifier=0

				--combo started, first hit got the crit bonus and now it resets.
				if masteries.vars[currentHand.."Firing"] and (masteries.vars[currentHand.."ComboStep"] > 1) then
					masteries.timers[currentHand]["rapierTimerBonus"]=rapierTimerDefault
				end

				--a single rapier, with no other weapon in the other hand whatsoever, grants a crit chance boost based on time since last attack. wielding alongside a dagger reduces the tech boosts, but grants a protection multiplier.
				-- one handed --does it need to be HARD one-handed? can't use with a non-weapon?
				--apparently supposed to grant crit damage? but didnt in previous code. instead, we have this.
				if (not (tagCaching[otherHand.."TagCache"]["weapon"] or tagCaching[otherHand.."TagCache"]["thrown"])) and masteries.vars[currentHand.."Firing"] then
					--due to the implementation and nature of this bonus it will never display in the adv stats page or anywhere else. it is only active during the attack, and that is a very brief time frame
					--to fully test this, it requires the use of debug code in crits.lua
					critModifier=masteries.timers[currentHand]["rapierTimerBonus"][1]*(1+masteries.stats.rapierMastery)
				elseif tagCaching[otherHand.."TagCache"]["dagger"] then
					--"properly" dual wielded
					dodgeModifier=0.25
					dashModifier=0.25
					protectionModifier=0.12*(1+masteries.stats.rapierMastery)
				end

				masteryBuffer[#masteryBuffer + 1]={stat="dodgetechBonus", amount=dodgeModifier*(1+(masteries.stats.rapierMastery))*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="dashtechBonus", amount=dashModifier*(1+(masteries.stats.rapierMastery))*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=critModifier}
				--sb.logInfo("crit modifier in masteries: %s",critModifier)
				masteryBuffer[#masteryBuffer + 1]={stat="protection", effectiveMultiplier=1+(protectionModifier) }
			end

			--shortspears: modifiers based on what else is or isn't wielded. none when combo'd.
			if tagCaching[currentHand.."TagCache"]["shortspear"] then
				if not (tagCaching[otherHand.."TagCache"]["weapon"] or tagCaching[otherHand.."TagCache"]["thrown"] or tagCaching[otherHand.."TagCache"]["shield"]) then --solo shortspear, no other weapons: boost crit damage.
					masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=0.3*(1+masteries.stats.shortspearMastery) }
				else
					-- using shortspear with a shield: boost shield and defense tech stats.
					if tagCaching[otherHand.."TagCache"]["shield"] then
						masteryBuffer[#masteryBuffer + 1]={stat="shieldBash", amount=10 }
						masteryBuffer[#masteryBuffer + 1]={stat="shieldBashPush", amount=2}
						masteryBuffer[#masteryBuffer + 1]={stat="shieldStaminaRegen", effectiveMultiplier=1+(0.2*(1+masteries.stats.shortspearMastery)) }
						masteryBuffer[#masteryBuffer + 1]={stat="defensetechBonus", amount=0.50}
					end
					--technically should be an elseif, but hey...maybe shellguard adds a spearshield?
					-- with another shortspear: penalize protection and crit chance (crit one is a joke.)
					if tagCaching[otherHand.."TagCache"]["shortspear"] then
						--yes, the awkward looking math is needed. this ensures that the system doesn't apply the same 0.8x twice, but instead splits it.
						masteryBuffer[#masteryBuffer + 1]={stat="protection", effectiveMultiplier=1+((0.2*(masteries.stats.shortspearMastery-1))*handMultiplier) }
						masteryBuffer[#masteryBuffer + 1]={stat="critChance", effectiveMultiplier=1+((0.5*(masteries.stats.shortspearMastery-1))*handMultiplier) }
					end
				end
			end

			--scythe: combo based crit damage and crit chance.
			if tagCaching[currentHand.."TagCache"]["scythe"] then
				masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=(0.05+((masteries.vars[currentHand.."Firing"] and masteries.vars[currentHand.."ComboStep"] or 0)*0.1))*(1+masteries.stats.scytheMastery)*handMultiplier }
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=((masteries.vars[currentHand.."Firing"] and masteries.vars[currentHand.."ComboStep"] or 0)*(1+masteries.stats.scytheMastery))*handMultiplier }
			end

			--longswords: no baseline value, like shortspears, due to fart.
			if tagCaching[currentHand.."TagCache"]["longsword"] then
				if masteries.vars[currentHand.."Firing"]and (masteries.vars[currentHand.."ComboStep"] >=3) then
					masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=0.15*(1+masteries.stats.longswordMastery)*handMultiplier}
				end
				-- longsword solo, no other weapons: attack speed.
				if not (tagCaching[otherHand.."TagCache"]["weapon"] or tagCaching[otherHand.."TagCache"]["thrown"] or tagCaching[otherHand.."TagCache"]["shield"]) then
					--this would be funny to apply at full value if wielding alongside another longsword. especially with a minor damage penalty.
					masteryBuffer[#masteryBuffer + 1]={stat="attackSpeedUp", amount=0.7*masteries.stats.longswordMastery}
				else
					 --using a shield: increase shield stats, heal/defense techs.
					if tagCaching[currentHand.."TagCache"]["shield"] or tagCaching[otherHand.."TagCache"]["shield"] then
						--the below line was placed as a 'baseline' mastery, not in shields. why? commenting out.
						--masteryBuffer[#masteryBuffer + 1]={stat="shieldBash", amount=1.0+((10*handMultiplier)*(1+masteries.stats.longswordMastery)) }
						masteryBuffer[#masteryBuffer + 1]={stat="shieldBash", amount=4*(1+masteries.stats.longswordMastery) }
						masteryBuffer[#masteryBuffer + 1]={stat="shieldBashPush", amount=1}
						masteryBuffer[#masteryBuffer + 1]={stat="defensetechBonus", amount=0.25*(1+masteries.stats.longswordMastery) }
						masteryBuffer[#masteryBuffer + 1]={stat="healtechBonus", amount=0.15*(1+masteries.stats.longswordMastery) }
					end
					-- dual wielding longsword with any other weapon: reduced protection, increased movespeed
					--yes, the awkward looking math is needed. this ensures that the system doesn't apply the same 0.8x twice, but instead splits it.
					if tagCaching[otherHand.."TagCache"]["weapon"] then
						masteryBuffer[#masteryBuffer + 1]={stat="protection", effectiveMultiplier=1+((0.2*(masteries.stats.longswordMastery-1))*handMultiplier) }
						table.insert(masteries.vars.ephemeralEffects,{{effect="runboost5", duration=0.02}})
					end
				end
			end

			--spears: crit chance, damage, and dash tech bonuses.
			if tagCaching[currentHand.."TagCache"]["spear"] then
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=2*masteries.stats.spearMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.spearMastery*handMultiplier/2) }
				masteryBuffer[#masteryBuffer + 1]={stat="dashtechBonus", amount=0.08*masteries.stats.spearMastery*handMultiplier}
			end

			--shortswords: combo based crit chance. other stats based on wield state.
			if tagCaching[currentHand.."TagCache"]["shortsword"] then
				masteryBuffer[#masteryBuffer + 1]= {stat="critChance", amount=(1+((masteries.vars[currentHand.."Firing"] and masteries.vars[currentHand.."ComboStep"] or 0)*(1+masteries.stats.shortswordMastery)))*handMultiplier}
				local powerModifier=masteries.stats.shortswordMastery*handMultiplier
				local dodgeModifier=masteries.stats.shortswordMastery*handMultiplier
				local dashModifier=masteries.stats.shortswordMastery*handMultiplier
				local gritModifier=masteries.stats.shortswordMastery*handMultiplier

				-- solo shortsword, no other weapons: increased damage, dash/dodge tech bonuses, and knockback resistance
				if not (tagCaching[otherHand.."TagCache"]["weapon"] or tagCaching[otherHand.."TagCache"]["thrown"] or tagCaching[otherHand.."TagCache"]["shield"]) then
					powerModifier=(powerModifier/1.5)
					dashModifier=0.1*dashModifier/2
					dodgeModifier=0.1*masteries.stats.shortswordMastery/2
				else
					-- if holding a shield: lower damage boost. increased defense tech boost, shield bash. increased knockback resistance.
					if tagCaching[otherHand.."TagCache"]["shield"] then
						powerModifier=(powerModifier/3)
						dashModifier=0
						dodgeModifier=0
						masteryBuffer[#masteryBuffer + 1]={stat="defensetechBonus", amount=0.1*(masteries.stats.shortswordMastery*handMultiplier/2) }
						masteryBuffer[#masteryBuffer + 1]={stat="shieldBash", amount=3*(masteries.stats.shortswordMastery*handMultiplier/3) }
					else
						-- anything else: increased damage, increased dash/dodge techs.
						powerModifier=(powerModifier/2)
						dashModifier=0.1*(dashModifier/3)
						dodgeModifier=0.1*(dodgeModifier/3)
						gritModifier=0
					end
				end

				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+powerModifier}
				masteryBuffer[#masteryBuffer + 1]={stat="dashtechBonus", amount=dashModifier }
				masteryBuffer[#masteryBuffer + 1]={stat="dodgetechBonus", amount=dodgeModifier }
				masteryBuffer[#masteryBuffer + 1]={stat="grit", amount=gritModifier}
			end

			if tagCaching[currentHand.."TagCache"]["katana"] then
				if masteries.vars[currentHand.."Firing"] and (masteries.vars[currentHand.."ComboStep"] >1) then -- combos higher than 1 move
					table.insert(masteries.vars.controlModifiers,{speedModifier=1+((masteries.vars[currentHand.."ComboStep"]/10)*(1+masteries.stats.katanaMastery/48)) })
				end
				-- holding one katana with no other weapon: increase  defense techs, damage, protection and crit chance
				if not (tagCaching[otherHand.."TagCache"]["weapon"] or tagCaching[otherHand.."TagCache"]["thrown"]) then
					masteryBuffer[#masteryBuffer + 1]={stat="defensetechBonus", amount=0.15*(1+(masteries.stats.katanaMastery/2)) }
					masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.katanaMastery/3) }
					masteryBuffer[#masteryBuffer + 1]={stat="protection", effectiveMultiplier=1+(masteries.stats.katanaMastery/8) }
					masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=2*masteries.stats.katanaMastery}
				else
					-- dual wielding heavy weapons: reduced damage and protection --you really hate these don't you?
					if tagCaching[otherHand.."TagCache"]["longsword"] or tagCaching[otherHand.."TagCache"]["katana"] or tagCaching[otherHand.."TagCache"]["axe"] or tagCaching[otherHand.."TagCache"]["flail"] or tagCaching[otherHand.."TagCache"]["shortspear"] or tagCaching[otherHand.."TagCache"]["mace"] then
						masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+((0.2*(masteries.stats.katanaMastery-1))*handMultiplier) }
						masteryBuffer[#masteryBuffer + 1]={stat="protection", effectiveMultiplier=1+((0.1*(masteries.stats.katanaMastery-1))*handMultiplier) }
					end
					-- dual wielding with a short blade: increased energy
					if tagCaching[otherHand.."TagCache"]["shortsword"] or tagCaching[otherHand.."TagCache"]["dagger"] or tagCaching[otherHand.."TagCache"]["rapier"] then
						masteryBuffer[#masteryBuffer + 1]={stat="maxEnergy", effectiveMultiplier=1+(0.15+((0.02/3)*masteries.stats.katanaMastery*handMultiplier)) }
						masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=0.2*(1+(masteries.stats.katanaMastery*handMultiplier/3)) }
						masteryBuffer[#masteryBuffer + 1]={stat="dodgetechBonus", amount=0.08*(1+(masteries.stats.katanaMastery*handMultiplier/2)) }
						masteryBuffer[#masteryBuffer + 1]={stat="dashtechBonus", amount=0.08*(1+(masteries.stats.katanaMastery*handMultiplier/2)) }
						masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=2*masteries.stats.katanaMastery*handMultiplier/2}
					end
				end
			end

			-- maces: increased damage. crit, stun chance. crit damage.
			if tagCaching[currentHand.."TagCache"]["mace"] then
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.maceMastery*handMultiplier/2) }
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=2*masteries.stats.maceMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="stunChance", amount=2*masteries.stats.maceMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=2*masteries.stats.maceMastery*handMultiplier/2}
				-- increased power after first strike in combo.
				if masteries.vars[currentHand.."Firing"] and (masteries.vars[currentHand.."ComboStep"] > 1) then
					masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(0.01+(masteries.stats.maceMastery*handMultiplier/3)) }
				end
				if tagCaching[otherHand.."TagCache"]["shield"] then -- if using a shield: shield bash, defense.
					masteryBuffer[#masteryBuffer + 1]={stat="shieldBash", amount=3*(1+(masteries.stats.maceMastery*handMultiplier)) }
					masteryBuffer[#masteryBuffer + 1]={stat="shieldBashPush", amount=handMultiplier}
					masteryBuffer[#masteryBuffer + 1]={stat="protection", effectiveMultiplier=1+((0.1+(0.05*masteries.stats.maceMastery))*handMultiplier) }
				end
			end

			-- hammers: increased damage. crit, stun chance. crit damage.
			--special bonuses while doing charged attacks, like greataxes.
			--note:
			---greataxes are exclusively handled in /items/active/weapons/melee/abilities/greataxe/greataxesmash.lua which provides timer-scaling crit chance and crit damage --#greataxeMastery
			---hammers also have similar code in /items/active/weapons/melee/abilities/hammer/hammersmash.lua which provides timer-scaling crit chance and stun chance -#hammerMastery
			if tagCaching[currentHand.."TagCache"]["hammer"] then
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.hammerMastery*handMultiplier/2) }
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=2*masteries.stats.hammerMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="stunChance", amount=2*masteries.stats.hammerMastery*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=2*masteries.stats.hammerMastery*handMultiplier/2}
				-- increased power after first strike in combo.
				if masteries.vars[currentHand.."Firing"] and (masteries.vars[currentHand.."ComboStep"] > 1) then
					masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(0.01+(masteries.stats.hammerMastery*handMultiplier/3)) }
				end
			end

			if tagCaching[currentHand.."TagCache"]["axe"] then
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=2*(masteries.stats.axeMastery*handMultiplier) }
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.axeMastery*handMultiplier) }
			end

			--fist weapons: mastery: increased crit and stun chance. increased damage. combo: increased crit chance/damage, stun chance.
			--fist weapons aren't 'melee' in vanilla. many mods unfortunately follow that idiot trend. ERM is even worse in that they don't even properly use the fistWeapon category.
			if tagCaching[currentHand.."TagCache"]["fist"] or tagCaching[currentHand.."TagCache"]["fistweapon"] or tagCaching[currentHand.."TagCache"]["gauntlet"] then
				--I hate stupid people.
				if not masteries.stats.fistMastery then masteries.stats.fistMastery=status.stat("fistMastery") end
				--for some reason fist combos start at 0, unlike meleecombo
				local comboStep=math.max(masteries.vars[otherHand.."ComboStep"],masteries.vars[currentHand.."ComboStep"])
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier",effectiveMultiplier=1+(masteries.stats.fistMastery*handMultiplier/2) }
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=((1*comboStep)+(2*masteries.stats.fistMastery))*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="stunChance", amount=((4*comboStep)+(2*masteries.stats.fistMastery))*handMultiplier}
				masteryBuffer[#masteryBuffer + 1]={stat="protection", amount=(1*comboStep)*handMultiplier}
			end

			--below this point should be stuff that doesn't fall under melee or ranged; elemental modifiers, staves, wands.

			--energy weapons: increased Energy
			if tagCaching[currentHand.."TagCache"]["energy"] then
				masteryBuffer[#masteryBuffer + 1]={stat="maxEnergy", effectiveMultiplier=1+(masteries.stats.energyMastery*handMultiplier/2) }
			end

			--plasma weapons: increased Crit Damage
			if tagCaching[currentHand.."TagCache"]["plasma"] then
				masteryBuffer[#masteryBuffer + 1]={stat="critDamage", amount=masteries.stats.plasmaMastery*handMultiplier}
			end

			--bioweapons: increased Crit Chance
			if tagCaching[currentHand.."TagCache"]["bioweapon"] then
				masteryBuffer[#masteryBuffer + 1]={stat="critChance", amount=1/2*masteries.stats.bioweaponMastery*handMultiplier}
			end

			--wands: increased damage, reduced cast time, increased projectiles (+1 per 16.66% mastery, up to 100%), increased range.
			--khe's take: slightly less damage and range from mastery as it's a more versatile weapon. Instead, it casts a bit faster and gains projectiles from mastery faster.
			--notes: projectile count does not increase total damage, as the damage is split per projectile.
			--math: 20% mastery grants: 5% range and damage when wielded alone, or 2.5% wielded with another weapon. 0.96 charge time multiplier, or 0.98. +1.2 projectiles, or +0.6. note that 0.2 projectiles is a 20% chance for a projectile.
			if tagCaching[currentHand.."TagCache"]["wand"] then
				masteryBuffer[#masteryBuffer + 1]={stat="focalRangeMult",amount=(masteries.stats.wandMastery*handMultiplier/4) }
				masteryBuffer[#masteryBuffer + 1]={stat="focalCastTimeMult", amount=-(masteries.stats.wandMastery*handMultiplier/5) }
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.wandMastery*handMultiplier/4) }
				masteryBuffer[#masteryBuffer + 1]={stat="focalProjectileCountBonus", amount=math.min(1.0,math.floor(masteries.stats.wandMastery*6))*handMultiplier }
			end

			--staves: increased damage, reduced cast time, increased projectiles (+1 per 20% mastery, up to 100%), increased range.
			--khe's take: staves are the more cast range and damage focused weapon, less about speed and many hits.
			--notes: projectile count does not increase total damage, as the damage is split per projectile.
			--math: 20% mastery grants: 10% range, 6% damage, 0.98 charge time multiplier. +1 projectile.
			if tagCaching[currentHand.."TagCache"]["staff"] then
				masteryBuffer[#masteryBuffer + 1]={stat="focalRangeMult",amount=(masteries.stats.staffMastery*handMultiplier/2) }
				masteryBuffer[#masteryBuffer + 1]={stat="focalCastTimeMult", amount=-(masteries.stats.staffMastery*handMultiplier/10) }
				masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.staffMastery*handMultiplier/3) }
				masteryBuffer[#masteryBuffer + 1]={stat="focalProjectileCountBonus", amount=math.min(1.0,math.floor(masteries.stats.staffMastery*5))*handMultiplier }
			end

			--broadswords
			if tagCaching[currentHand.."TagCache"]["broadsword"] then
				if masteries.vars[currentHand.."Firing"] and (masteries.vars[currentHand.."ComboStep"] > 2) then
					masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.broadswordMastery*handMultiplier/2) }
				else
					masteryBuffer[#masteryBuffer + 1]={stat="powerMultiplier", effectiveMultiplier=1+(masteries.stats.broadswordMastery*handMultiplier/3) }
				end
			end
			--sb.logInfo("%s masteryBuffer (decluttered) %s",currentHand,masteries.declutter(masteryBuffer))
			--sb.logInfo("%s ephemeralEffects %s controlModifiers %s",currentHand,masteries.vars.ephemeralEffects,masteries.vars.controlModifiers)
			--sb.logInfo("mvars %s, mpersistvars %s",masteries.vars,masteries.persistentVars)
			status.setPersistentEffects("masteryBonus"..currentHand,masteries.declutter(masteryBuffer))
		end
	end
	for _,set in pairs(masteries.vars.ephemeralEffects) do
		status.addEphemeralEffects(set)
	end
	for _,set in pairs(masteries.vars.controlModifiers) do
		mcontroller.controlModifiers(set)
	end
	masteries.vars.applied=true
	local notices,newBeat=status.inflictedDamageSince(masteries.persistentVars.heartbeat)
	masteries.persistentVars.heartbeat=newBeat
	masteries.listenerBonuses(notices,args.dt)
end
--end mastery application

--begin listener bonuses
function masteries.listenerBonuses(notifications,dt)
	--initialize vars
	if not masteries.vars.inflictedKillCounter then masteries.vars.inflictedKillCounter=0 end
	if not masteries.vars.inflictedHitCounter then masteries.vars.inflictedHitCounter=0 end
	if not masteries.vars.hitTimer then masteries.vars.hitTimer=0.0 end
	if not masteries.vars.killTimer then masteries.vars.killTimer=0.0 end
	if not masteries.vars.leechInstances then masteries.vars.leechInstances={} end

	--load the buffer with valid targets, verify hitType
	local notificationBuffer={}
	for _,notification in pairs(notifications) do
		if (notification.sourceEntityId ==entity.id()) and (notification.targetEntityId ~=entity.id()) then
			notification.hitType=string.lower(notification.hitType)
			if (notification.hitType~="kill") and not status.resourcePositive("health") then
				notification.hitType="kill"
			end
			table.insert(notificationBuffer,notification)
		end
	end

	--if #notificationBuffer>0 then sb.logInfo("notices %s",notificationBuffer) end

	--hit stuff, typically for hit/kill count combos
	local hitCount=0
	local killCount=0
	local strongHitCount=0
	local weakHitCount=0

	--total damage, used for leech calcs.
	local totalDamage=0
	--overkill damage, not used
	--local overkillDamage=0
	--leech percent - percent of damage leeched over the duration of the leech effect.
	local leechPercent=status.stat("fuLeechPercent")
	--maximum leech per second
	local leechMaxRate=0.1+status.stat("fuLeechMaxRate")
	--leech rate modifier: bigger number means faster ticks.
	local leechDuration=10.0/(1.0+status.stat("fuLeechRateMod"))

	for _,notification in pairs(notificationBuffer) do
		--check if it's a valid target. only the first valid target is counted
		--kill computation
		if notification.hitType =="kill" then
			killCount=killCount+1
		elseif notification.hitType =="hit" then
			--hit computation
			hitCount=hitCount+1
		elseif notification.hitType =="weakhit" then
			--weak hit computation. this and strong hit are added as potential options for later.
			weakHitCount=weakHitCount+1
		elseif notification.hitType =="stronghit" then
			--strong hit computation
			strongHitCount=strongHitCount+1
		end
		--overkillDamage=overkillDamage+notification.damageDealt
		totalDamage=totalDamage+notification.healthLost
	end

	--leech calculation
	local leechValue=totalDamage*leechPercent
	--short leeches get squished to fit in 1 second so they have more meaningful effect at lower levels.
	if leechValue>=10 then
		leechValue=leechValue/leechDuration
	else
		leechDuration=1
	end
	leechValue=math.min(status.stat("maxHealth")*leechMaxRate,leechValue)
	--sb.logInfo
	--handle leech instances
	local leechBuffer={}
	if leechValue>0 then
		table.insert(leechBuffer,{timer=leechDuration,amount=leechValue})
	end
	leechValue=0
	for _,instance in pairs(masteries.vars.leechInstances) do
		instance.timer=instance.timer-dt
		if instance.timer>0 then
			table.insert(leechBuffer,instance)
		end
	end
	for _,instance in pairs(leechBuffer) do
		leechValue=leechValue+instance.amount
	end
	masteries.vars.leechInstances=leechBuffer

	--rather than limiting it to one per, making it so that it instead rounds down from sqrt, up to 5.
	--this means that hitting 1-3 targets counts as 1, 4-8 counts as 2, 9-15 counts as 3, and 16  counts as 4. etc.
	hitCount=math.min(5,math.floor(math.sqrt(weakHitCount+hitCount+strongHitCount)))
	killCount=math.min(5,math.floor(math.sqrt(killCount)))

	--implement timer for hit/kill bonuses. cap each at 500. for now.
	if hitCount>0 then
		masteries.vars.hitTimer=3.0
		masteries.vars.inflictedHitCounter=masteries.vars.inflictedHitCounter+hitCount
		masteries.vars.inflictedHitCounter=math.min(masteries.vars.inflictedHitCounter,500)
	else
		masteries.vars.hitTimer=math.max(0,masteries.vars.hitTimer-dt)
		if masteries.vars.hitTimer==0 then
			masteries.vars.inflictedHitCounter=0
		end
	end
	if killCount>0 then
		masteries.vars.killTimer=10.0
		masteries.vars.inflictedKillCounter=masteries.vars.inflictedKillCounter+killCount
		masteries.vars.inflictedKillCounter=math.min(masteries.vars.inflictedKillCounter,500)
	else
		masteries.vars.killTimer=math.max(0,masteries.vars.killTimer-dt)
		if masteries.vars.killTimer==0 then
			masteries.vars.inflictedKillCounter=0
		end
	end

	local listenerbonus={}
	--process kills
	if masteries.vars.inflictedKillCounter > 0 then
		--longswords and daggers: 0.02% power per kill, increased further by averaged mastery. no cap, because it's so damn weak.
		if tagCaching.mergedCache["longsword"] or tagCaching.mergedCache["dagger"] then
			--add special coding to handle mixed weapons, rather than just going by longsword mastery
			local masteryValue=1.0
			local masteryCalcBuffer=0.0
			local masteryCounts=0

			if tagCaching.mergedCache["longsword"] then
				masteryCalcBuffer=masteryCalcBuffer+masteries.stats.longswordMastery
				masteryCounts=masteryCounts+1
			end

			if tagCaching.mergedCache["dagger"] then
				masteryCalcBuffer=masteryCalcBuffer+masteries.stats.daggerMastery
				masteryCounts=masteryCounts+1
			end

			if masteryCounts>0 then
				masteryCalcBuffer=masteryCalcBuffer/masteryCounts
				masteryValue=masteryValue+masteryCalcBuffer
			end

			table.insert(listenerbonus,{stat="powerMultiplier", effectiveMultiplier=1+((masteries.vars.inflictedKillCounter/50)*masteryValue) })
		end

		--axes: 1% power per kill
		if tagCaching.mergedCache["axe"] and (status.resourcePercentage("health") >= 0.2) then
			table.insert(listenerbonus,{stat="powerMultiplier", effectiveMultiplier=1+masteries.vars.inflictedKillCounter/100})
		end

		--broadswords: 0.5% knockback resistance per mastery on kill, not per kill.  increased protection, taking 7 to reach full effect at 35%. Mastery reduces the count to reach this bonus.
		if tagCaching.mergedCache["broadsword"] then
			table.insert(listenerbonus,{stat="protection", effectiveMultiplier=math.min(1.35,(1+masteries.vars.inflictedKillCounter/20)*(1+masteries.stats.broadswordMastery)) })
			table.insert(listenerbonus,{stat="grit", amount=(masteries.stats.broadswordMastery)*0.5})	-- secret bonus from Broadsword Mastery
		end
	end

	--process hits
	if masteries.vars.inflictedHitCounter > 0 then
		--katana: knockback resistance.
		if tagCaching.mergedCache["katana"] then
			table.insert(listenerbonus,{stat="grit", amount=masteries.vars.inflictedHitCounter/20.0})
		end

		--shortsword: 5% crit damage per hit.
		if tagCaching.mergedCache["shortsword"] then
			table.insert(listenerbonus,{stat="critDamage", amount=((masteries.vars.inflictedHitCounter/100)*5) })
		end

		--quarterstaff: 10% protection per hit, with cap at 50%
		if tagCaching.mergedCache["quarterstaff"] then
			table.insert(listenerbonus,{stat="protection", effectiveMultiplier=1+math.min(masteries.vars.inflictedHitCounter,5)/10.0 })
		end

		--mace: stun chance, +2% per hit.
		if tagCaching.mergedCache["mace"] then
			table.insert(listenerbonus,{stat="stunChance", amount=masteries.vars.inflictedHitCounter*2})
		end

		--axe: +3% crit chance per hit, with cap at 5 hits.
		if tagCaching.mergedCache["axe"] then
			table.insert(listenerbonus,{stat="critChance", amount=math.min(5,masteries.vars.inflictedHitCounter)*3})
		end
	end

	--insert leech last
	if leechValue>0 then
		--sb.logInfo("leechValue %s",leechValue)
		world.sendEntityMessage(entity.id(),"recordFUPersistentEffect","fuLeeching")
		status.setPersistentEffects("fuLeeching",{{stat="healthRegen",amount=leechValue}})
		--status.setPersistentEffects("fuLeeching",{{stat="healthRegen",amount=0.05}})
	end
	--sb.logInfo("leechdata: hp %s, lmr %s, lp %s, lv %s, ld %s",status.resource("health"),leechMaxRate,leechPercent,leechValue,leechDuration)

	--using the temporary persistent effect system, to make it wear off
	status.setPersistentEffects("listenerMasteryBonus", listenerbonus)
	if (masteries.vars.hitTimer+masteries.vars.killTimer) > 0 then
		world.sendEntityMessage(entity.id(),"recordFUPersistentEffect","listenerMasteryBonus")
	end
end
--end listener bonuses

function masteries.load(dt)
	--load mastery stats by forced lowercase tag (tagCaching forces lowercase). streamlines shit.
	for tag,_ in pairs(tagCaching.mergedCache) do
		local e=tag.."Mastery"
		masteries.stats[e]=status.stat(e)
	end
	if tagCaching.mergedCache["ranged"] then
		masteries.stats.fireRateMastery=status.stat("fireRateBonus")
		masteries.stats.ammoMastery=status.stat("ammoMastery")
	end
	if not masteries.vars.heartbeat then masteries.vars.heartbeat=0 end

	masteries.vars.loaded=true
end

function masteries.update(dt)
	local args={}
	args.dt=dt

	--update tracking of combo steps for each weapon.
	masteries.vars.primaryComboStepOld=masteries.vars.primaryComboStep
	masteries.vars.altComboStepOld=masteries.vars.altComboStep
	--assume default of 1 globally for combo step, as if a weapon is a combo weapon, that is the initial step. current only exception: fists. because wtf?
	masteries.vars.primaryComboStep=status.statusProperty("primaryComboStep") or 1
	masteries.vars.altComboStep=status.statusProperty("altComboStep") or 1

	--update tracking of firing state for each weapon.
	masteries.vars.primaryFiringOld=masteries.vars.primaryFiring
	masteries.vars.altFiringOld=masteries.vars.altFiring
	masteries.vars.primaryFiring=status.statusProperty("primaryFiring")
	masteries.vars.altFiring=status.statusProperty("altFiring")

	--if this segment fires i'm going to shoot someone with rusty nails from a shotgun.
	local pType=type(masteries.vars.primaryComboStep)
	local aType=type(masteries.vars.altComboStep)
	if pType=="string" then
		--WTF, this shouldn't happen
		masteries.vars.primaryComboStep=tonumber(masteries.vars.primaryComboStep)
	elseif pType~="number" then
		--this really, really should not happen
		masteries.vars.altComboStep=nil
	end
	if aType=="string" then
		--WTF, this shouldn't happen
		masteries.vars.altComboStep=tonumber(masteries.vars.altComboStep)
	elseif aType~="number" then
		--this really, really should not happen
		masteries.vars.altComboStep=nil
	end

	--if weapon state changed, then the script will do more update stuff
	--typically, weapons set combo state to 1 (Exception: below), on init, and when finishing a combo.
	--note that fist weapons don't set their firing state. instead, their combo step sets itself to 0 when they're not attacking.
	--firing state is only set in primary fire modes
	if (tagCaching.primaryTagCacheItemChanged)then
		--sb.logInfo("primary changed to %s",tagCaching.primaryTagCacheItem)
		masteries.clearHand("primary")
		args.primaryChanged=true
	elseif (masteries.vars.primaryComboStepOld~=masteries.vars.primaryComboStep) then
		--sb.logInfo("primary combo step changed from %s to %s",masteries.vars.primaryComboStepOld,masteries.vars.primaryComboStep)
		args.primaryChanged=true
	elseif (masteries.vars.primaryFiringOld~=masteries.vars.primaryFiring) then
		--sb.logInfo("primary firing state changed from %s to %s",masteries.vars.primaryFiringOld,masteries.vars.primaryFiring)
		args.primaryChanged=true
	end
	if (tagCaching.altTagCacheItemChanged) then
		--sb.logInfo("alt changed to %s",tagCaching.altTagCacheItem)
		args.altChanged=true
		masteries.clearHand("alt")
	elseif (masteries.vars.altComboStepOld~=masteries.vars.altComboStep) then
		--sb.logInfo("alt combo step changed from %s to %s",masteries.vars.altComboStepOld,masteries.vars.altComboStep)
		args.altChanged=true
	elseif (masteries.vars.altFiringOld~=masteries.vars.altFiring) then
		--sb.logInfo("alt firing state changed from %s to %s",masteries.vars.altFiringOld,masteries.vars.altFiring)
		args.altChanged=true
	end
	masteries.load(dt)
	masteries.apply(args)
end

function masteries.clearHand(hand)
	if (type(hand)~="string") or (type(tagCaching[hand.."TagCacheOld"])~="table") then return end
	masteries.timers[hand]={}
	masteries.timers["both"]={}
	status.setPersistentEffects("masteryBonus"..hand, {})
	status.setPersistentEffects("ammoMasteryBonus"..hand, {})
end

function masteries.reset()
	for currentHand,_ in pairs({primary="alt",alt="primary"}) do
		masteries.clearHand(currentHand)
	end
	status.setPersistentEffects("listenerMasteryBonus", {})
end

function masteries.declutter(inList)
	local outList={}
	if type(inList)~="table" then return {} end
	for _,element in pairs(inList) do
		if ((element.amount or 0)~=0) or ((element.effectiveMultiplier or 1.0)~=1.0) or ((element.baseMultiplier or 1.0)~=1.0) then table.insert(outList,element) end
	end
	return outList
end
