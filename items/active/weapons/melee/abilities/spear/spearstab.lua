require "/items/active/weapons/melee/meleeslash.lua"
require("/scripts/FRHelper.lua")

-- Spear stab attack
-- Extends normal melee attack and adds a hold state
SpearStab = MeleeSlash:new()

function SpearStab:init()
	MeleeSlash.init(self)

	self.holdDamageConfig = sb.jsonMerge(self.damageConfig, self.holdDamageConfig)
	self.holdDamageConfig.baseDamage = self.holdDamageMultiplier * self.damageConfig.baseDamage
end

function SpearStab:fire()
	MeleeSlash.fire(self)

	if self.fireMode == "primary" and self.allowHold ~= false then
        self:setState(self.hold)
		--*************************************
		-- FU/FR ADDONS
        if self.blockCount == nil then
            self.blockCount = 5
        end
        if self.blockCount2 == nil then
            self.blockCount2 = 0
        end
        if self.blockCount3 == nil then
            self.blockCount3 = 0
        end

        if status.isResource("food") then
            self.foodValue = status.resource("food")	--check our Food level
        else
            self.foodValue = 60
        end

        -- *********************************
        -- FR RACIAL BONUSES FOR WEAPONS	--- Bonus effect when attacking
        -- *********************************
        setupHelper(self, "spearstab-fire")
        if self.helper then
            self.helper:runScripts("spearstab-fire", self)
        end
        --**************************************
    end
end

function SpearStab:hold()
	self.weapon:setStance(self.stances.hold)
	self.weapon:updateAim()
	while self.fireMode == "primary" do

        local damageArea = partDamageArea("blade")
        self.weapon:setDamage(self.holdDamageConfig, damageArea)
        coroutine.yield()
	end

	self.cooldownTimer = self:cooldownTime()
end


function SpearStab:uninit()
	if self.helper then
        self.helper:clearPersistent()
    end
	self.blockCount = 0
end
