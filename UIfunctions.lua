--	FIELDS:
-- Party Tank TEXT
-- useBossBuffs CHECK
-- useLongBuffs CHECK
-- useBossPots CHECK
-- useLongPots CHECK
-- modePvP CHECK
-- targetBossOnly CHECK
-- petslot TEXT 1-6
-- cooldownresidue TEXT




--	show action slot number
function DIYCE.ShowHotKeys()
	local key, pos, frame, info, button, hotkey
	for key, pos in pairs({"Main", "Right", "Left", "Bottom"}) do
		frame=getglobal(pos.."ActionBarFrame")
		--info = ActionBarInfo[frame:GetID()];
		for i = 1, ACTIONBAR_NUM_BUTTONS do
			button = getglobal(frame:GetName().."Button"..i);
			--if ( i <= info.count ) then			
				hotkey = getglobal(button:GetName().."Hotkey");
				hotkey:SetText(i+frame:GetID()*20-20);
			--end
		end
	end
end

--	hide action slot number
function DIYCE.HideHotKeys()
	local key, pos, frame
	for key, pos in pairs({"Main", "Right", "Left", "Bottom"}) do
		frame=getglobal(pos.."ActionBarFrame")
		ActionBarFrame_Update(frame)
	end
end

--	show zone info
function DIYCE.zonename()
	DEFAULT_CHAT_FRAME:AddMessage(GREEN.."====== Zone Name ======")
	DEFAULT_CHAT_FRAME:AddMessage(GetZoneLocalName(GetZoneID()));
	DEFAULT_CHAT_FRAME:AddMessage(GREEN.."====== Zone ID ======")
	DEFAULT_CHAT_FRAME:AddMessage(GetZoneID());
	DEFAULT_CHAT_FRAME:AddMessage(LTBLUE.."====== Region Name ======")
	DEFAULT_CHAT_FRAME:AddMessage(GetZoneName());
	DEFAULT_CHAT_FRAME:AddMessage(SILVER.."====== Ingame Zone Name ======")
	DEFAULT_CHAT_FRAME:AddMessage(GetZoneEnglishName(GetZoneID()));
	DEFAULT_CHAT_FRAME:AddMessage(GREEN.."====================")
end

--	create default macros
function DIYCE.CreateMacros()
	MacroFrame:Show()
	local empty = 0
	macroname = {
		[1] = "Buffs",
		[2] = "Dps",
		[3] = "Ranged",
		[4] = "Boss Burst Buffs",
		[5] = "Food/Pot",
		[6] = "AoE",
		[7] = "PvP",
		}
	macroicon = {
		[1] = 94,
		[2] = 189,
		[3] = 77,
		[4] = 167,
		[5] = 208,
		[6] = 23,
		[7] = 210,
		}
	macrotext = {
		[1] = "0",
		[2] = "1",
		[3] = "2",
		[4] = "3",
		[5] = "4",
		[6] = "aoe",
		[7] = "pvp",
		}
	for i = 1, 49 do
		local index, name, script = GetMacroInfo(i)
		if index == nil then
			empty = empty + 1
		end
	end
	if empty < 7 then
		SendSystemMsg("Only "..empty.." macro space left, Required is 7")
		return
	end	
	
	for k = 1, 7 do
		for i = 1, 49 do
			local index, name, script = GetMacroInfo(i)
			if index == nil then
				EditMacro(i, macroname[k], macroicon[k], "/script KillSequence('v1','"..macrotext[k].."')");
				break
			end
		end
	end
end

-- Suicide button
function DIYCE.Death()
	SetCameraPosition (0,0,10000000);
end

--Summon and dismiss a pet.
function DIYCE.Pet()
	local petSlot = DIYCEVars["PetSlot"]
	local petname = GetPetItemName(petSlot)
	if petSlot == nil then
		SendSystemMsg("|H|h|cffFF0000No pet specified. Set a pet slot in config window.|h")
	elseif IsPetSummoned(petSlot) then
		ReturnPet(petSlot)
		SendSystemMsg("|H|h|cffFF0000Recalling "..petname.."|h")
	else
		SummonPet(petSlot)
		SendSystemMsg("|H|h|cff00FFFFSummoning "..petname.."|h")
	end
end

function DIYCE.LogBattle(msg)
	local remaining = 404
	if DIYCEVars["TimerSkill"] then
		local cooldown, remaining = GetActionCooldown(DIYCEVars["TimerSkill"])
	end
	Msg(msg..' -- '.. string.format("%.1f", remaining))
end