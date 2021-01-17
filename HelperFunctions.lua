-------------------------------------------------------------------------------------------------------
-------------------------------------------TARGET------------------------------------------------------
-------------------------------------------------------------------------------------------------------
--	select the party member with the lowest hp
function _getSickestPartyMember()
	lowHPChar = "player"
	if GetNumPartyMembers() >= 2 then
		for num=1,GetNumPartyMembers()-1 do
			if (( _checkRange("party"..num,'friend')) and (PctH("party"..num) < PctH(lowHPChar))) then
				lowHPChar = "party"..num
			end
		end
	end
	return lowHPChar
end

-- get the number of projectiles of the player
function _getCountProjectiles()
	return GetInventoryItemCount("player",9)
end

--	select the party member with selected debuff type
function _getDebuffedPartyMember(matchType)
	if GetNumPartyMembers() >= 2 then
		for num=1,GetNumPartyMembers()-1 do
			if UnitIsSick("party"..num, matchType) and ( _checkRange("party"..num,'friend')) then
				return "party"..num
			end
		end
		if UnitIsSick("player", matchType) then
			return "player"
		end
	end
	return false
end

--	select the party member without selected buff name
function _getUnbuffedPartyMember(matchType)
	if GetNumPartyMembers() >= 2 then
		for num=1,GetNumPartyMembers()-1 do
			containsbuff = BuffList("party"..num)
			if not containsbuff[matchType] and ( _checkRange("party"..num,'friend')) then
				return "party"..num
			end
		end
		containsbuff = BuffList("player")
		if not containsbuff[matchType] then
			return "player"
		end
	end
	return false
end

--	destroy a party or raid
function _destroyGroup()
	local numParty = GetNumPartyMembers();
	local numRaid = GetNumRaidMembers();
	local unitId = "";
	if (numRaid >= 2) then
		unitId = "raid";
		limit = 36;
	elseif (numParty >= 2) then
		unitId = "party";
		limit = numParty - 1;
	end
	if (IsRaidLeader("player") or IsPartyLeader("player")) then
		for i = 1, limit do
			if (UnitName(unitId .. i) ~= nil and UnitName(unitId .. i) ~= UnitName("player")) then
				UninviteFromParty(unitId .. i);
			end
		end
	else
		Msg("You haven't got rights to destroy the group, either you aren't in a group or you are not leader.");
	end
end

--	get raid indexes populated by players
function _getRaidMemberIndexes()
	indexes = ''
	for num=1,36 do
		if UnitExists("raid"..num) then
			indexes = indexes.." raid"..num
		end
	end
	return indexes
end

--	target party member by name
function _targetUnitByName(name,method)
	if GetNumPartyMembers() >= 2 then
		if DIYCEVars["PartyLeader"] == "" then
			return ("party1")
		end
		for num=1,GetNumPartyMembers()-1 do
			if UnitName("party"..num) == name then
				if method == 'target' then
					TargetUnit("party"..num)
				else
					return ("party"..num)
				end
			end
		end
	end
	return ("target")
end

--	target enemy by name
function _targetEnemyByName(name,hppercent)
	for i=1,15 do
		TargetNearestEnemy()
		if hppercent then
			targetable = (UnitName("target") == name and PctH("target") > hppercent)
		else
			targetable = (UnitName("target") == name)
		end
		
		if targetable then
			break
		end
	end
	if not targetable then
		TargetUnit()
	end
end

--	target something, and remember previous 
function _TargetAndRemember(tgt)
	FocusUnit( 12 , "target" );
	TargetUnit(tgt)
end

--	target original target, and forget the temporary one 
function _TargetAndForget()
	TargetUnit('focus12')
	FocusUnit( 12 , "" );
end

--	check if targetable unit is in range or dead
function _checkRange(tgt,arg1)
	if arg1 == 'friend' then
		slot = 19
	else
		slot = 18
	end
	_TargetAndRemember('target')
	if GetActionUsable(slot) then
		-- Msg("- HP for "..UnitName("party"..num) .. " is: " .. UnitMaxHealth("party"..num))
		_TargetAndForget()
		return true
	else
		-- Msg("- Player "..UnitName("party"..num).." out of range or dead.")
		TargetUnit('focus12')
		FocusUnit(12,"")
		return false
	end
end
-------------------------------------------------------------------------------------------------------
-------------------------------------------BAGITEM-----------------------------------------------------
-------------------------------------------------------------------------------------------------------
--	check for item in bag if usable
--	{ name = "Item: Potion: Clear Thought", use = ((not pbuffs['Clear Thought']) and (not pbuffs['Thunder Force']) and (IsBagItemUsable("Potion: Clear Thought"))) },
function IsBagItemUsable(itemname)
	if (GetCountInBagByName(itemname) == 0) then
		return false
	end
		i=1
		while (i < 180)
			do
				local inventoryIndex, icon, name, itemCount, locked, invalid = GetBagItemInfo ( i )
				if (name == itemname) then
					local maxCD, CurrentCD = GetBagItemCooldown ( inventoryIndex )
					if (locked == true) then
						return false
					elseif (CurrentCD == 0) then
						return true
					else
						return false
					end
				end
				i = i + 1
			end
end

--	slotNumber = _bagItemSlot("Guild Rune"); DEFAULT_CHAT_FRAME:AddMessage("Index is: "..slotNumber);
function _bagItemSlot(itemname)
		i=0
		while (i < 500)	do
			local inventoryIndex, icon, name, itemCount, locked, invalid = GetBagItemInfo ( i )
			if (name == itemname) then
					return inventoryIndex
			end
			i = i + 1
		end
end

-- local PHdebuffTypes = {
	-- [0]		= "Earth",
	-- [1]		= "Water",
	-- [2]		= "Fire",
	-- [3]		= "Wind",
	-- [4]		= "Light",
	-- [5]		= "Dark",
	-- [6]		= "Poison",
	-- [7]		= "Transform",
	-- [8]		= "Helpless",
	-- [9]		= "Curse",
	-- [10]	= "Harmful Effect",
	-- [11]	= "Beneficial Effect", -- some buffs are removable
	-- [12]	= "Immobilization",
	-- [13]	= "Stun",
	-- [14]	= "Special",	-- ??
	-- [15]	= "Fear",
-- }
--	for i=1,100,1 do local name, icon, count, ID, params = UnitDebuff( "target", i ); DEFAULT_CHAT_FRAME:AddMessage(i.." "..name.." "..icon.." "..count.." "..ID.." "..params); end
function UnitIsSick(thisunit, matchType)
	local cnt = 1
	local debuff,iconpath,count,buffID,debuffType = UnitBuff(thisunit, cnt)

	while debuff ~= nil do
		if (matchType == nil) or (matchType == debuffType) then
				-- Msg(UnitName(thisunit) .. " has "..debuff.." (type: "..debuffType..")")
				return thisunit
		end

		cnt = cnt + 1
		debuff,iconpath,count,buffID,debuffType = UnitBuff(thisunit, cnt)
	end
	-- Msg(UnitName(thisunit) .. " does not have "..matchType)
	return nil
end

--	count nature's power
function _countBuff(target,buffName)
	local cnt = 1
	local debuff,iconpath,count,buffID,debuffType = UnitBuff(target, cnt)

	while debuff ~= nil do
		if (debuff == buffName) then
				-- Msg(UnitName(target) .. " has "..debuff.." (rank: "..count..")")
				return count
		end

		cnt = cnt + 1
		debuff,iconpath,count,buffID,debuffType = UnitBuff("player", cnt)
	end
	-- Msg(UnitName(target) .. " does not have "..debuff)
	return 0
end