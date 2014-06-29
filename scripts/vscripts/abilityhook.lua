tHookElements = tHookElements or {}

tnHookDamage = {175 , 250 , 350 , 500  }
tnHookLength = {500 , 700 , 900 , 1200 }
tnHookRadius = {20  , 30  , 50  , 80   }
tnHookSpeed  = {0.3 , 0.4 , 0.6 , 0.9  }

tnUpgradeHookDamageCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookLengthCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookRadiusCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookSpeedCost  = {500 , 1000 , 1500 , 2000  }

tnPlayerHookDamage  = {}
tnPlayerHookLength  = {}
tnPlayerHookRadius  = {}
tnPlayerHookSpeed   = {}
tnPlayerHookType    = {}
tnPlayerHookBodyPType = {}



tPudgeLastForwardVec = {}
tnPlayerHookType    = {}
tbHookedNothing     = {}

PER_HOOK_BODY_LENGTH = 50

tnHookTypeString = {
	[1] = "npc_dota2x_pudgewars_unit_pudgehook_lv1",
	[2] = "npc_dota2x_pudgewars_unit_pudgehook_lv2",
	[3] = "npc_dota2x_pudgewars_unit_pudgehook_lv3",
	[4] = "npc_dota2x_pudgewars_unit_pudgehook_lv4"
}

tnHookParticleString = {
	 --TODO FIND THE PARTICLES
	 [1] = ""
	,[2] = ""
	,[3] = ""
	,[4] = ""
}
tPossibleHookTargetName = {
	 "npc_dota2x_pudgewars_pudge"
	,"npc_dota2x_pudgewars_chest"
	,"npc_dota2x_pudgewars_gold"
	--,"npc_dota2x_pudgewars_rune" TODO

}

local function distance(a, b)
    -- Pythagorian distance
    local xx = (a.x-b.x)
    local yy = (a.y-b.y)

    return math.sqrt(xx*xx + yy*yy)
end

for i = 0,9 do
	tHookElements[i] = {
		Head = nil,
		Target = nil,
		CurrentLength = nil,
		Body = {}
	}
	tnPlayerHookType[i] = tnHookTypeString[1]
	tnPlayerHookBodyPType[i] = tnHookParticleString[1]
	tnPlayerHookRadius[i] = 20
	tnPlayerHookLength[i] = 500
	tnPlayerHookSpeed[i] = 0.3

	--tHookLastPos[i] = nil
	--tHookCurrentPos[i] = nil
	--tbHookedNothing[i] = false
end

print("[pudgewars] finish init hook data")



function OnHookStart(keys)

	-- a player starts a hook
	PrintTable(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vOrigin = caster:GetOrigin()
	local vForwardVector = caster:GetForwardVector()
	PrintTable(vForwardVector)
	local nPlayerID = keys.unit:GetPlayerID()
	print("player "..tostring(nPlayerID).." Start a hook")
	
	-- create the hook head
	local unit = CreateUnitByName("npc_dota2x_pudgewars_unit_pudgehook_lv1",caster:GetOrigin(),false,nil,nil,caster:GetTeam())
	if unit == nil then 
		print("fail to create the head")
	else
		tHookElements[nPlayerID].Head = unit
		unit:SetForwardVector(vForwardVector)
		-- TODO change the model scale to the correct hook radiu
		--unit:SetModelScele(40 / tnPlayerHookRadius[nPlayerID] , -1 )
	end
	
	-- TODO replace "veil of discord" with correct particle， or even a table of effect 
	-- defined by units killed by the caster
	
	local nFXIndex = ParticleManager:CreateParticle( "veil_of_discord", PATTACH_CUSTOMORIGIN, caster )
	
	--local nFXIndex = ParticleManager:CreateParticle( tnPlayerHookBodyPType[ nPlayerID ] , PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( nFXIndex, 0, vOrigin)
	tHookElements[nPlayerID].Body[1] = {
	    index = nFXIndex,
	    vec = vOrigin
	}
end

-- get the hooked unit
local function GetHookedUnit(caster, head , plyid)
		
	-- find unit in radius within hook radius	
	local tuHookedUnits = FindUnitsInRadius(
		caster:GetTeam(),		--caster team
		head:GetOrigin(),		--find position
		nil,					--find entity
		tnPlayerHookRadius[plyid],			--find radius
		DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER, 
		0, FIND_CLOSEST,
		false
	)
	if #tuHookedUnits >= 1 then
		for k,v in pairs(tuHookedUnits) do
			local va = false
			for s,t in pairs (tPossibleHookTargetName) do
				if v:GetName() == t then
					-- the unit in the table , a valid hook unit
					va = true
				end
			end
			if not va then
				-- not a valid unit , remove
				table.remove(tuHookedUnits , k)
			end
		end
	end
	
	if #tuHookedUnits >= 1  and tuHookedUnits[1] ~= caster then
		-- return the nearest unit
		return tuHookedUnits[1]
	end
	return nil
end

local function HookUnit( unit , caster )
	print ( "hooking enemy" )
	caster:SetOrigin(unit:GetOrigin())
	ABILITY_HOOK = caster:FindAbilityByName( "dota2x_pudgewars_hook" )
	if ABILITY_HOOK ~= nil then
		if ABILITY_HOOK:GetLevel() ~= 1 then
			ABILITY_HOOK:SetLevel(1)
		end
		ExecuteOrderFromTable({
			UnitIndex = caster:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			AbilityIndex = ABILITY_HOOK:entindex(),
			TargetIndex = unit:entindex()
		})
	end
	if unit:HasModifier(" dota2x_modifier_hooked ") then
		return 1
	else
		return nil
	end
end

function OnHookChanneling(keys)


	local caster = EntIndexToHScript(keys.caster_entindex)
	local casterOrigin = caster:GetOrigin()
	local casterForwardVector = caster:GetForwardVector()
	local nPlayerID = caster:GetPlayerID()
	local uHead = tHookElements[nPlayerID].Head
	tHookElements[nPlayerID].Target = GetHookedUnit(caster , uHead , nPlayerID )
	
	if tHookElements[nPlayerID].CurrentLength == nil then
		tHookElements[nPlayerID].CurrentLength = 2
	else
		tHookElements[nPlayerID].CurrentLength = tHookElements[nPlayerID].CurrentLength + 1
	end
	
	-- if not hook anything and not reach the max length continue to longer the hook
	if not tHookElements[nPlayerID].Target and 
		tHookElements[nPlayerID].CurrentLength * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID] 
			< tnPlayerHookLength[nPlayerID]
		then
		if tPudgeLastForwardVec[nPlayerID] == nil then
			tPudgeLastForwardVec[nPlayerID] = casterForwardVector
		end
		
		-- get the changed angle of pudge
		local aChangedFV = math.atan2(casterForwardVector.y , casterForwardVector.x) 
			- math.atan2(tPudgeLastForwardVec[nPlayerID].y , tPudgeLastForwardVec[nPlayerID].x)
		local aChangedFV = aChangedFV / 10
		local x = (math.cos(aChangedFV)) * 1
		local y = (math.sin(aChangedFV)) * 1
		local base = uHead:GetOrigin()
		local vec3 = Vector(base.x + x * PER_HOOK_BODY_LENGTH , base.y + y * PER_HOOK_BODY_LENGTH , base.z )

		-- TODO replace "veil of discord" with correct particle， or even a table of effect 
		-- defined by units killed by the caster
		-- create next hook body
		local nFXIndex = ParticleManager:CreateParticle( "veil_of_discord", PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( nFXIndex, 0, vec)
		tHookElements[nPlayerID].Body[#tHookElements[nPlayerID] + 1] = {
		    index = nFXIndex,
		    vec = vec3
		}
		
		-- move the head
		uHead:SetOrigin(vec)
		uHead:SetForwardVector(x,y,base.z)
		
		tPudgeLastForwardVec[nPlayerID] = casterForwardVector
	end
	-- if hoooked someone then hook it
	--[[
	local hooked = nil
	if tHookElements[nPlayerID].Target then
		local unit = tHookElements[nPlayerID].Target
		while hooked == nil do
			hooked = HookUnit( unit , uHead )
		end
	end
	]]

	--if hooked something or hook reaches the max length then begin to go back
	if (tHookElements[nPlayerID].Target and hooked ) or  
		(tHookElements[nPlayerID].CurrentLength * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID] > tnPlayerHookLength[nPlayerID])
		then
		
		local backVec = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].vec
		local paIndex = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].index
		
		ParticleManager:ReleaseParticleIndex( paIndex )
		uHead:SetOrigin(backVec)
		
		table.remove(tHookElements[nPlayerID].Body,#HookElements[nPlayerID].Body)
		
		if #tHookElements[nPlayerID].Body == 0 then
			if tHookElements[nPlayerID].Target:IsAlive() then
				tHookElements[nPlayerID].Target:RemoveModifierByName( "dota2x_modifier_hooked" )
			end
			
			hooked = false
			tHookElements[nPlayerID].CurrentLength = nil
			
			uHead:Remove()
			tHookElements[nPlayerID].Head = nil
			HookElements[nPlayerID].Body = {}
			tHookElements[nPlayerID].Target = nil
			
			caster:RemoveModifierByName( "modifier_pudgewars_pudgemeathook_think_interval" )
		end
	end
	--[[
	--print("********* TRYING TO CATCH UNIT *** *********")
	--PrintTable(tuHookedUnits)
	--print("********************************************")
	--PrintTable(caster)
	--print("********************************************")
	
	tHookElements[nPlayerID].Target = nil
	-- if find any unit then think about it
	if #tuHookedUnits >= 1 then
		for k,v in pairs(tuHookedUnits) do
			local va = false
			for s,t in pairs (tPossibleHookTargetName) do
				if v:GetName == t then
					va = true
				end
			end
			if not va then
				table.remove(tuHookedUnits , k)
			end
		end
	end
	
	if #tuHookedUnits >= 1 then
		tHookElements[nPlayerID].Target = tuHookedUnits[1]
	end


	-- 没有钩中任何单位，也没达到最大距离，继续延长
	if tHookElements[nPlayerID].Target == nil and not tbHookedNothing[nPlayerID] then
		local vHeadOrigin = uHead:GetOrigin()
		local vDirection = caster:GetForwardVector()
		print("print forward vector************************")
		print("x  "..vDirection.x)
		print("y  "..vDirection.y)
		print("z  "..vDirection.z)
		print("********************************************")


		--TODO think about earth shaker's totem
		local vHeadMoveTarget = Vector(vHeadOrigin.x + 200 * vDirection.x , vHeadOrigin.y + 200 * vDirection.y , vHeadOrigin.z)

              -- Begin to rewrite hook
              --better sleep first
              -- Todo 2014 06 27 00 49

		--order the head to move
		local moveOrder = {
			UnitIndex = uHead:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = vHeadMoveTarget,
			Queue = false
		}
		ExecuteOrderFromTable(moveOrder)

		-- check the head moved distance
		tHookCurrentPos[nPlayerID] = vHeadOrigin
		if tHookLastPos[nPlayerID] == nil then 
			tHookLastPos[nPlayerID] = tHookCurrentPos[nPlayerID]
		end
		tnHookMovedDistance[nPlayerID] = tnHookMovedDistance[nPlayerID]  + distance( tHookCurrentPos[nPlayerID] , tHookLastPos[nPlayerID])
		tHookLastPos[nPlayerID] = tHookCurrentPos[nPlayerID]
		print("moved_length**************************")
		print(tostring(tnHookMovedDistance[nPlayerID]))

		--[[
		if tnHookMovedDistance[nPlayerID] >= tnPlayerHookLength[nPlayerID] then
			tbHookedNothing[nPlayerID] = true
		end
		

		if #tHookElements[nPlayerID].Body == 0 then
			latestedCreateBody[nPlayerID] = caster
		else
			latestedCreateBody[nPlayerID] = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body]
		end

		if distance(tHookCurrentPos[nPlayerID] , latestedCreateBody[nPlayerID]:GetOrigin()) > 70 then
			local unit = CreateUnitByName(
				"npc_dota2x_pudgewars_unit_pudgehook_body",
				uHead:GetOrigin(),
				false,nil,nil,
				caster:GetTeam()
			)
			if unit == nil then 
				print("fail to create the head")
			else
				table.insert( tHookElements[nPlayerID].Body , #tHookElements[nPlayerID].Body + 1 , unit )
			end
		end

	end
	--[[ if hook someone then catch it
	if tHookElements[nPlayerID].Target ~= nil then
		
		print("tHookElements[nPlayerID].Target ~= nil" )
		print(type(tHookElements[nPlayerID].Target))
		for k,v in pairs(tHookElements[nPlayerID].Target) do
			print(k,v)
		end
		local lassoAbility = uHead:FindAbilityByName("ability_dota2x_pudgewars_lasso")
		if lassoAbility == nil then
			uHead:AddAbility("ability_dota2x_pudgewars_lasso")
		end
		lassoAbility = uHead:FindAbilityByName("ability_dota2x_pudgewars_lasso")
		lassoAbility:SetLevel(1)
		--[[
		ExecuteOrderFromTable({
			UnitIndex = uHead:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			Ability = lassoAbility,
			Target = tHookElements[nPlayerID].Target,
			Queue = false
		})
	end
	-- if max length then call the elements back
	if tbHookedNothing[nPlayerID] or tHookElements[nplayerID].Target then

		local uHead = tHookElements[nPlayerID].Head
		local nBodyCount = #tHookElements[nPlayerID].Body
		local nearestUnit = tHookElements[nPlayerID].Body[nBodyCount]

		local moveOrder = {
			UnitIndex = uHead:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = nearestUnit:GetOrigin(),
			Queue = false
		}
		ExecuteOrderFromTable(moveOrder)
		
		
		if distance(nearestUnit:GetOrigin() , uHead:GetOrigin()) < 30 then
			local unitToRemove = tHookElements[nPlayerID].Body[nBodyCount]
			unitToRemove:Remove()
			table.remove( tHookElements[nPlayerID].Body , nBodyCount )
		end
	end
	--]]
end

function OnUpgradeHookDamage(keys)

	tPrint(keys)
	local caster    = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrage_hook_damage")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookDamageCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_damage_not_enough_gold",caster:GetTeam())
	end

end

function OnUpgradeHookRadius( keys )

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	
	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_radius")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_radius_not_enough_gold",caster:GetTeam())
	end

end

function OnUpgradeHookLength( keys )

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_length")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookLengthCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_length_not_enough_gold",caster:GetTeam())
	end
	
end

function OnUpgradeHookSpeed( keys )

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_speed")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_speed_not_enough_gold",caster:GetTeam())
	end
	
end

function OnUpgradeHookDamageFinished( keys )

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrage_hook_damage")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookDamageCost[nCurrentLevel]
	
	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_damage_fail_to_spend_gold",caster:GetTeam())
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookDamage[ nPlayerID ] =  tnHookDamage[ nCurrentLevel + 1 ]
	end
end

function OnUpgradeHookRadiusFinished( keys )

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_radius")
	local nCurrentLevel = hHookAbility:GetLevel()
	
	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_radius_fail_to_spend_gold",caster:GetTeam())
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookRadius[ nPlayerID ] =  tnHookRadius[ nCurrentLevel + 1 ]
	end
	
end

function OnUpgradeHookLengthFinished( keys )

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeLengthCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_length")
	local nCurrentLevel = hHookAbility:GetLevel()
	
	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_length_fail_to_spend_gold",caster:GetTeam())
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookLength[ nPlayerID ] =  tnHookLength[ nCurrentLevel + 1 ]
	end
	
end

function OnUpgradeHookSpeedFinished( keys )

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_speed")
	local nCurrentLevel = hHookAbility:GetLevel()
	

	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_speed_fail_to_spend_gold",caster:GetTeam())
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookSpeed[ nPlayerID ] =  tnHookSpeed[ nCurrentLevel + 1 ]
	end
	
end
