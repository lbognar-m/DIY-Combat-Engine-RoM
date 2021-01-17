-- Title: DIY Combat Engine
-- Version: 2.4.2
-- Description: Combat Engine to help with skill rotations, and maintaining buffs/debuffs for maximizing DPS.
-- Author: MisterSippi 

local WHITE = "|cffffffff"
local SILVER = "|cffc0c0c0"
local GREEN = "|cff00ff00"
local LTBLUE = "|cffa0a0ff"

function DIYCE_DebugSkills(skillList)
	DEFAULT_CHAT_FRAME:AddMessage(GREEN.."Skill List:")
	
	for i,v in ipairs(skillList) do
		DEFAULT_CHAT_FRAME:AddMessage(SILVER.."  ["..WHITE..i..SILVER.."]: "..LTBLUE.."\" "..WHITE..v.name..LTBLUE.."\"  use = "..WHITE..(v.use and "true" or "false"))
	end

	DEFAULT_CHAT_FRAME:AddMessage(GREEN.."----------")
end

function DIYCE_DebugBuffList(buffList)
	DEFAULT_CHAT_FRAME:AddMessage(GREEN.."Buff List:")
	
	for k,v in pairs(buffList) do
		-- We ignore numbered entries because both the ID and name 
		-- are stored in the list. This avoids doubling the output.
		if type(k) ~= "number" then
			DEFAULT_CHAT_FRAME:AddMessage(SILVER.."  ["..WHITE..k..SILVER.."]:  "..LTBLUE.."id: "..WHITE..v.id..LTBLUE.."  stack: "..WHITE..v.stack..LTBLUE.."  time: "..WHITE..(v.time or "none"))
		end
	end
	
	DEFAULT_CHAT_FRAME:AddMessage(GREEN.."----------")	
end

function CustomAction(action)
	if CD(action) then
		if IsShiftKeyDown() then Msg("- "..action) end
		g_lastaction = action
		CastSpellByName(action)
		return true
	else
		return false
	end
end

--The Potion function is for using in a macro either by itself or combined with the KillSequence function. 
--I used it with my Priest in combo with the PartyHealer Addon to make sure to use potions when I needed them most.
function Potion(healthpot,manapot)
	local Skill = {}
	local i = 0
	local phealth = PctH("player")
	local pctmana = PctM("player")
	healthpot = healthpot or 0
	manapot = manapot or 0
	Skill = {
	{ name = "Action: "..healthpot,		use = (phealth <= .70) },
	{ name = "Action: "..manapot,		use = (pctmana <= .40) },
			}
	MyCombat(Skill,arg1)
end

--Summon and dismiss a pet.
function Pet(petnum)
	if IsPetSummoned(petnum)
		then ReturnPet(petnum) 
	else SummonPet(petnum)
	end
end

--Summon and use the Warden Pet.
function WardenPet(arg1)
	local Skill = {}
	local pctEB1 = PctM("player")
	local pbuffs = BuffList("player")

	local SpiritOfTheOakActive = UnitExists("pet") and (UnitName("pet") == "Spirit of the Oak")
	local NatureCrystalActive = UnitExists("pet") and (UnitName("pet") == "Nature Crystal")
	
	Skill = {
		--{ name = "Summon Spirit of the Oak",			use = (not pbuffs["Heart of the Oak"]) and (not SpiritOfTheOakActive) and (pctEB1 >= .15) },
		--{ name = "Heart of the Oak",					use = SpiritOfTheOakActive and (not pbuffs["Heart of the Oak"]) and (pctEB1 >= .05) },
		{ name = "Summon Nature Crystal",				use = (not NatureCrystalActive) and (pctEB1 >= .15) },
			}	
	
	MyCombat(Skill, arg1)
end

--Summon and use the Priest Fairy.,
function PriestFairySequence(arg1)
	local Skill = {}
	local Skill2 = {}
	local i = 0
	local FairyExists = UnitExists("playerpet")
	local FairyBuffs = BuffList("playerpet")
	local combat = GetPlayerCombatState()

	--Determine Class-Combo
	mainClass, subClass = UnitClassToken( "player" )

	--Summon Fairy
	if (not FairyExists) and (not combat) then
		if mainClass == "AUGUR" then
			if subClass == "THIEF" then
				Skill = {
					{ name = "Shadow Fairy",			use = true },
						}
			elseif subClass == "RANGER" then
				Skill = {
					{ name = "Water Fairy",				use = true },
						}
			elseif subClass == "MAGE" then
				Skill = {
					{ name = "Wind Fairy",				use = true },
						}			
			elseif subClass == "KNIGHT" then
				Skill = {
					{ name = "Light Fairy",				use = true },
						}			
			elseif subClass == "WARRIOR" then
				Skill = {
					{ name = "Fire Fairy",				use = true },
						}
			end
		end
	end	
	
	--Cast Halo
	if FairyExists then
		if mainClass == "AUGUR" then
			if subClass == "THIEF" then
				if (not FairyBuffs[503459]) then
					if (arg1 == "v1") then
						Msg("- Activating Halo", 0, 1, 1)
					end
					Skill = {
						{ name = "Pet Skill: 5 (Wraith Halo)",	use = true },
							}
				end
			elseif subClass == "RANGER" then
				if (not FairyBuffs[503457]) then
					if (arg1 == "v1") then
						Msg("- Activating Halo", 0, 1, 1)
					end
					Skill = {
						{ name = "Pet Skill: 5 (Frost Halo)",	use = true },
							}
				end
			elseif subClass == "MAGE" then
				if (not FairyBuffs[503461]) then
					if (arg1 == "v1") then
						Msg("- Activating Halo", 0, 1, 1)
					end
					Skill = {
						{ name = "Pet Skill: 5 (Windrider Halo)",	use = true },
							}
				end
			elseif subClass == "KNIGHT" then
				if (not FairyBuffs[503507]) then
					if (arg1 == "v1") then
						Msg("- Activating Halo", 0, 1, 1)
					end
					Skill = {
						{ name = "Pet Skill: 5 (Devotion Halo)",	use = true },
							}
				end
			elseif subClass == "WARRIOR" then
				if (not FairyBuffs[503455]) then
					if (arg1 == "v1") then
						Msg("- Activating Halo", 0, 1, 1)
					end
					Skill = {
						{ name = "Pet Skill: 5 (Accuracy Halo)",	use = true },
							}
				end
			end
		
			--Cast Conceal
		if (not MyCombat(Skill, arg1)) then
			if (not FairyBuffs[503753]) then
				if (arg1 == "v1") then
					Msg("- Activating Conceal", 0, 1, 1)
				end
				Skill2 = {
					{ name = "Pet Skill: 6 (Conceal)",	use = true },
						}
			end
		end
		end
	end
	
	if (not MyCombat(Skill, arg1)) then
		MyCombat(Skill2, arg1)
	end
end

