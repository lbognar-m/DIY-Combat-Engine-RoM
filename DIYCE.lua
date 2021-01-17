-- Title: DIY Combat Engine
-- Version: 2.4.2
-- Description: Combat Engine to help with skill rotations, and maintaining buffs/debuffs for maximizing DPS.
-- Author: MisterSippi

local g_skill  = {}
local DIYCE_Timers = {}
local g_lastaction = ""
local addonName = "DIY Combat Engine"
local addonVersion = "v2.4"

function Msg(outstr,a1,a2,a3)
	DEFAULT_CHAT_FRAME:AddMessage(tostring(outstr),a1,a2,a3)
end

function ReadSkills()
	g_skill = {}
	local skillname,slot

	for page = 1,4 do
		slot = 1
		skillname = GetSkillDetail(page,slot)
		repeat
			local a1,a2,a3,a4,a5,a6,a7,a8,skillusable = GetSkillDetail(page,slot)
			if skillusable then
				g_skill[skillname] = { ["page"] = page, ["slot"] = slot }
			end
			slot = slot + 1
			skillname = GetSkillDetail(page,slot)
		until skillname == nil
	end
end

-- Read Skills on Log-In/Class Change/Level-Up
		local DIYCE_EventFrame = CreateUIComponent("Frame","DIYCE_EventFrame","UIParent")
			DIYCE_EventFrame:SetScripts("OnEvent", [=[ 
					if event == "PLAYER_SKILLED_CHANGED" then
						ReadSkills()
						end
					]=] )
			DIYCE_EventFrame:RegisterEvent("PLAYER_SKILLED_CHANGED")
			DIYCE_EventFrame:SetScripts("OnUpdate", [=[ DIYCE_TimerUpdate(elapsedTime) ]=] )
			
function PctH(tgt)
	return (UnitHealth(tgt)/UnitMaxHealth(tgt))
end

function PctM(tgt)
	return (UnitMana(tgt)/UnitMaxMana(tgt))
end

function PctS(tgt)
	return (UnitSkill(tgt)/UnitMaxSkill(tgt))
end

function CancelBuff(buffname)
	local i = 1
	local buff = UnitBuff("player",i)

	local buff = string.gsub(buff, "(Function:)( *)(.*)", "%3")
	
	while buff ~= nil do
		if buff == buffname then
			CancelPlayerBuff(i)
			return true
		end

		i = i + 1
		buff = UnitBuff("player",i)
	end
	return false
end

function BuffList(tgt)
	local list = {}
	local buffcmd = UnitBuff
	local infocmd = UnitBuffLeftTime

	if UnitCanAttack("player",tgt) then
		buffcmd = UnitDebuff
		infocmd = UnitDebuffLeftTime
	end

	-- There is a max of 100 buffs/debuffs per unit apparently
	for i = 1,100 do
		local buff, _, stackSize, ID = buffcmd(tgt, i)
		local timeRemaining = infocmd(tgt,i)
		if buff then
			-- Ad to list by name
			list[buff:gsub("(%()(.)(%))", "%2")] = { stack = stackSize, time = timeRemaining or 0, id = ID }
			-- We also list by ID in case two different buffs/debuffs have the same name.
			list[ID] = {stack = stackSize, time = timeRemaining, name = buff:gsub("(%()(.)(%))", "%2") }
		else
			break
		end
	end

	return list
end

--		Example of useage of ChkBuffCount()
--			{ name = "Tactical Attack",   use = ((EnergyBar1 >= 15) and (ChkBuffCount("target",_,500081,2))) },
function ChkBuffCount(tgt,buffname,BuffID,buffcount)
	local cnt = 1
	local buffcmd = UnitBuff
	local buffcounter = 0

	if UnitCanAttack("player",tgt) then
		buffcmd = UnitDebuff
	end
	
	local buff, _, _, ID = buffcmd(tgt,cnt)

	while buff ~= nil do
		if string.gsub(buff, "(%()(.)(%))", "%2") == buffname
			or ID == BuffID then
			buffcounter = buffcounter + 1		
		end
		cnt = cnt + 1
		buff = buffcmd(tgt,cnt)
		
		if buffcounter >= buffcount then
			return true
		end
	end	
end

function CD(skillname)
	local firstskill = GetSkillDetail(2,1)
	if (g_skill[firstskill] == nil) or (g_skill[firstskill].page ~= 2) then
		ReadSkills()
	end

	if g_skill[skillname] ~= nil then
		local tt,cd = GetSkillCooldown(g_skill[skillname].page,g_skill[skillname].slot)
		if cd <= tonumber(DIYCEVars["CDready"]) then --0.3
			return cd
		end
	elseif skillname == nil then
		return false
	else
		return
	end
end

function MyCombat(Skill, arg1)
	local spell_name = UnitCastingTime("player")
	local talktome = ((arg1 == "v1") or (arg1 == "v2"))
	local action,actioncd,actiondef,actioncnt
	
	if spell_name ~= nil then
		if (arg1 == "v2") then Msg("- ["..spell_name.."]", 0, 1, 1) end
		return true
	end

	for x,tbl in ipairs(Skill) do
	
		-- if (Skill[x].target) then
			-- TargetUnit(Skill[x].target)
		-- end
			
		local useit = type(Skill[x].use) ~= "function" and Skill[x].use or (type(Skill[x].use) == "function" and Skill[x].use() or false)
		if useit then
			if string.find(Skill[x].name, "Action:") then
				action = tonumber((string.gsub(Skill[x].name, "(Action:)( *)(%d+)(.*)", "%3")))
				_1,actioncd = GetActionCooldown(action)
				actiondef,_1,actioncnt = GetActionInfo(action)
				if GetActionUsable(action) and (actioncd == 0) and (actiondef ~= nil) and (actioncnt > 0) then
					if talktome then Msg("1- "..Skill[x].name) end
					UseAction(action)
					return true
				end
			elseif string.find(Skill[x].name, "Custom:") then
				action = string.gsub(Skill[x].name, "(Custom:)( *)(.*)", "%3")
				if CustomAction(action) then
					return true
				end
			elseif string.find(Skill[x].name, "Item:") then
				action = string.gsub(Skill[x].name, "(Item:)( *)(.*)", "%3")
				if talktome then Msg("2- "..Skill[x].name) end
				UseItemByName(action)
				return true
			elseif (Skill[x].ignoretimer or GetDIYCETimerValue(Skill[x].timer) == 0) and CD(Skill[x].name) then 
				if talktome then Msg("3- "..Skill[x].name) end
				if (Skill[x].target and not UnitCanAttack("player","target")) then	--	LORCHNG
					_TargetAndRemember(Skill[x].target)	--	LORCHNG
					remember = true	--	LORCHNG
				end	--	LORCHNG
				CastSpellByName(Skill[x].name)
				if (Skill[x].target and remember) then	--	LORCHNG
					_TargetAndForget()	--	LORCHNG
				end	--	LORCHNG
				StartDIYCETimer(Skill[x].timer)
				return true
			elseif string.find(Skill[x].name, "Pet Skill:") then
				action = string.gsub(Skill[x].name, "(Pet Skill:)( *)(%d+)(.*)", "%3")
					UsePetAction(action)
				if (arg1 == "v2") then Msg(Skill[x].name.." has been fully processed") end
				return true
			elseif string.find(Skill[x].name, "Function:") then
				action = string.gsub(Skill[x].name, "(Function:)( *)(.*)", "%3")
				if action and type(_G[action]) == "function" then
					_G[action](unpack(Skill[x].params or {}))
				end
				return true
			end
		end
	end
	--if (arg1 == "v2") then Msg("- [IDLE]", 0, 1, 1) end

	return false
end

function BuffTimeLeft(tgt, buffname)
	local cnt = 1
	local buff = UnitBuff(tgt,cnt)

	while buff ~= nil do
		if string.find(buff,buffname) then
		-- Msg(buffname.." has left: "..UnitBuffLeftTime(tgt,cnt));
			return UnitBuffLeftTime(tgt,cnt)
		end
		cnt = cnt + 1
		buff = UnitBuff(tgt,cnt)
	end

	return 0
end

function BuffParty(arg1,arg2)
--	arg1 = Quickbar slot # for targetable, instant-cast buff without a cooldown (eg. Amp Attack) for range checking.
--	arg2 = buff expiration time cutoff (in seconds) for refreshing buffs, default is 45 seconds.

	local selfbuffs = { "Soul Bond", "Enhanced Armor", "Holy Seal" }
	local groupbuffs = { "Grace of Life", "Amplified Attack", "Angel's Blessing", "Essence of Magic", "Magic Barrier", "Fire Ward", "Savage Blessing", "Concentration Prayer", "Shadow Fury", "Embrace of the Water Spirit"  }

	local buffrefresh = arg2 or 45			 -- Refresh buff time (seconds)
	local spell = UnitCastingTime("player")  -- Spell being cast?
	local vocal = IsShiftKeyDown()			 -- Generate feedback if Shift key held

	if (spell ~= nil) then
		return
	end

	if vocal then Msg("- Checking self buffs on "..UnitName("player")) end
	for i,buff in ipairs(selfbuffs) do
		if (g_skill[buff] ~= nil) and CD(buff) and (BuffTimeLeft("player",buff) <= buffrefresh) then
			if vocal then Msg("- Casting "..buff.." on "..UnitName("player")) end
			TargetUnit("player")
			CastSpellByName(buff)
			return
		end
	end

	if vocal then Msg("- Checking group buffs on "..UnitName("player")) end
	for i,buff in ipairs(groupbuffs) do
		if (g_skill[buff] ~= nil) and CD(buff) and (BuffTimeLeft("player",buff) <= buffrefresh) then
			if vocal then Msg("- Casting "..buff.." on "..UnitName("player")) end
			TargetUnit("player")
			CastSpellByName(buff)
			return
		end
	end

	for num=1,GetNumPartyMembers()-1 do
		TargetUnit("party"..num)
		if GetActionUsable(arg1) and (UnitHealth("party"..num) > 0) then
			if vocal then Msg("- Checking group buffs on "..UnitName("party"..num)) end
			for i,buff in ipairs(groupbuffs) do
				if (g_skill[buff] ~= nil) and CD(buff) and (BuffTimeLeft("target",buff) <= buffrefresh) then
					if UnitIsUnit("target","party"..num) then
						if vocal then Msg("- Casting "..buff.." on "..UnitName("target")) end
						CastSpellByName(buff)
						return
					else
						if vocal then Msg("- Error: "..UnitName("target").." != "..UnitName("party"..num)) end
					end
				end
			end
		else
			if vocal then Msg("- Player "..UnitName("party"..num).." out of range or dead.") end
		end
	end

	if vocal then Msg("- Nothing to do.") end			
end

--[[ Timer Update function ]]--
-- Tick down any active timers
function DIYCE_TimerUpdate(elapsed)
	for k,v in pairs(DIYCE_Timers) do
		v.timeLeft = v.timeLeft - elapsed
		if v.timeLeft < 0 then
			v.timeLeft = 0
		end
	end
end

--[[ Create a named timer ]]--
-- if the named timer already exists, this does nothing.
function CreateDIYCETimer(timerName, waitTime)
	if not DIYCE_Timers[timerName] then
		DIYCE_Timers[timerName] = { timeLeft = 0, waitTime = waitTime }
	end
end

--[[ Set/reset waitTimer of an existing timer ]]--
-- if the timer doesn't exist, this does nothing
function SetDIYCETimerDelay(timerName, waitTime)
	if DIYCE_Timers[timerName] then
		DIYCE_Timers[timerName].waitTime = waitTime
	end
end

--[[ Delete named timer ]]--
-- if the timer doesn't exist, this does nothing
-- Not really needed, but added for completeness
function DeleteDIYCETimer(timerName)
	if DIYCE_Timers[timerName] then
		DIYCE_Timers[timerName] = nil
	end
end

--[[ Get a timer's current time ]]--
-- if the timer doesn't exist, this returns 0
function GetDIYCETimerValue(timerName)
	if timerName then
		return DIYCE_Timers[timerName] and DIYCE_Timers[timerName].timeLeft or 0
	end
	return 0
end

--[[ Starts a timer ticking down ]]--
-- if timer doesn't exist, this does nothing
function StartDIYCETimer(timerName)
	if timerName and DIYCE_Timers[timerName] then
		DIYCE_Timers[timerName].timeLeft = DIYCE_Timers[timerName].waitTime
	end
end

--[[ Stop a named timer ]]--
-- if timer doesn't exist, this does nothing
function StopDIYCETimer(timerName)
   if DIYCE_Timers[timerName] then
		DIYCE_Timers[timerName].timeLeft = 0
  end
end


--	===========================		Addonmanager	=================================
DIYCE = {}

function DIYCE.OnLoad(this)
	this:RegisterEvent("VARIABLES_LOADED")
	SLASH_SHOWCONFIG1 = "/dyce"
	-- SlashCmdList.DYICE = DIYCE.SaveData
	SlashCmdList["SHOWCONFIG"] = function(editBox, msg) -- Definition of a slash command, having to use editBox and a message
		DIYCE.ToggleVisible()
	end
	DEFAULT_CHAT_FRAME:AddMessage("DIYCEVars |cff00ff00Slash Commands defined successfully. Set leader: /dyce|r")
	setupDIYCEAddonManagerMiniButton()
end

--	===================	UI	===========================================

--	setup addon manager button
function setupDIYCEAddonManagerMiniButton()
	if AddonManager then
		local DIYCEaddon = {
			name = addonName,
			description = "Combat Engine to help with skill rotations, and maintaining buffs/debuffs for maximizing DPS.",
			category = "Other",
			version = addonVersion,
			author = 'LuLu',
			slashCommands = "/dycl",
			miniButton = DIYCEMiniButton,
			icon = "Interface\ItemMall\IM_Help-Normal",
			onClickScript = DIYCE.ToggleVisible,
		}

		if AddonManager.RegisterAddonTable then
			AddonManager.RegisterAddonTable(DIYCEaddon)
		else
			AddonManager.RegisterAddon(DIYCEaddon.name, DIYCEaddon.description, DIYCEaddon.icon, DIYCEaddon.category,
				DIYCEaddon.configFrame, DIYCEaddon.slashCommands, DIYCEaddon.miniButton, DIYCEaddon.onClickScript)
		end
		DEFAULT_CHAT_FRAME:AddMessage(addonName .. " " .. addonVersion .. " loaded successfully!")
		DEFAULT_CHAT_FRAME:AddMessage("DIYCEVars |cff00ff00DIYCE Vars installed successfully.|r")
	end
end

-- Toogle the config frame
function DIYCE.ToggleVisible()
	local frame = DIYCEFrame
	if frame:IsVisible() then
		frame:Hide()
	else
		frame:Show()
	end
end

--	load the variable or set it empty
function DIYCE.VARIABLES_LOADED()
	if not DIYCEVars then
		DIYCEVars = {
			["PartyLeader"] = nil,
			["PetSlot"] = 1,
			["CDready"] = 0.3,
			["useBossBuffs"] = true,
			["useLongBuffs"] = true,
			["useBossPots"] = true,
			["useLongPots"] = true,
			["debugCount"] = false,
			["TimerSkill"] = nil,
			["modePvP"] = false,
			["targetBossOnly"] = false,
		}
	end
	SaveVariables("DIYCEVars")
end

function DIYCE.SaveSettings()
	SaveVariables("DIYCEVars")
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00DIYCEVars settings saved successfully.|r")
	DEFAULT_CHAT_FRAME:AddMessage("DIYCEVars party leader set to: |cff00ff00"..DIYCEVars["PartyLeader"]..'|r')
end