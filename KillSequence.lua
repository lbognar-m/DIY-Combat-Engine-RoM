--The main function of DIYCE.
function KillSequence(arg1, mode, healthpot, manapot, Healslot, foodslot, speedpot, ragepot, HoTslot)
--arg1 = "v1" or "v2" for debugging
--mode = used for various purposes, such as setting custom sections for specific situation. (IE: Seige War/PvP)
--healthpot = # of actionbar slot for health potions
--manapot = # of actionbar slot for mana potions
--foodslot = # of actionbar slot for food (add more args for more foodslots if needed)

	local Skill = {}
	local Skill2 = {}
	local i = 0
	
	

	local silenceList = {
			["Annihilation"] = true,
			["King Bug Shock"] = true,
			["Mana Rift"] = true,
			["Dream of Gold"] = true,
			["Flame"] = true,
			["Flame Spell"] = true,
			["Wave Bomb"] = true,
			["Silence"] = true,
			["Recover"] = true,
			["Restore Life"] = true,
			["Heal"] = true,
			["Curing Shot"] = true,
			["Leaves of Fire"] = true,
			["Urgent Heal"] = true,
			["Heavy Shelling"] = true,
			["Dark Healing"] = true,
							}	

	local subList = {
			["Sharp Slash"] = true, -- 1st Boss DOD
			["Conjure Energy"] = true, -- 4th boss GC HM AOE
			["Cat Claw Whirlwind"] = true,  --1st boss RT AOE
			["Void Fire"] = true, --2nd boss RT AOE
							}
	
						
	arrowTime = 0
	SlotRWB = 16 --Action Bar Slot # for Rune War Bow
	SlotMNB = 17 --Action Bar Slot # for your Main Bow
	local g_lastaction = ""
	local g_cnt = 0
	--Determine Class-Combo
	mainClass, subClass = UnitClassToken( "player" )
	--main, second = UnitClass("player")

	-- Player and target status.
--	GENERAL
	local combat = GetPlayerCombatState()
	local playerself = (UnitIsUnit("player", "target"))
	local playerLevel = UnitLevel('player')
	local enemy = UnitCanAttack("player","target")
	local EnergyBar1 = UnitMana("player")
	local EnergyBar2 = UnitSkill("player")
	local pctEB1 = PctM("player")
	local pctEB2 = PctS("player")
	local tbuffs = BuffList("target")
	local ttbuffs = BuffList("targettarget")
	local pbuffs = BuffList("player")
	local tDead = UnitIsDeadOrGhost("target")
	local behind = (not UnitIsUnit("player", "targettarget"))
	local melee = GetActionUsable(13) -- # is your melee range spell slot number
	local a1,a2,a3,a4,a5,ASon = GetActionInfo(14)  -- # is your Autoshot slot number
	local ammo = (GetEquipSlotInfo(10) ~= nil)
	local _,_,_,_,RWB,_ = GetActionInfo( SlotRWB )
	local _,_,_,_,MNB,_ = GetActionInfo( SlotMNB )
	local phealth = PctH("player")
	local thealth = PctH("target")
	local LockedOn = UnitExists("target")
	local boss = UnitSex("target") > 2
	local ttboss = UnitSex("targettarget") > 2
	local elite = UnitSex("target") == 2
	local ttelite = UnitSex("targettarget") == 2
	local party = GetNumPartyMembers() >= 2
	local PsiPoints, PsiStatus = GetSoulPoint()
	local zoneid = (GetZoneID() % 1000)
	local SeigeWar = (zoneid == 402) -- The "Seige War" Zone
	local countProjectiles = _getCountProjectiles() or 0

	--Silence Logic
	local tSpell,tTime,tElapsed = UnitCastingTime("target")
	local ttSpell,ttTime,ttElapsed = UnitCastingTime("targettarget")
	local silenceThis = tSpell and silenceList[tSpell] and ((tTime - tElapsed) > 0.1)
	local ttsilenceThis = ttSpell and silenceList[ttSpell] and ((ttTime - ttElapsed) > 0.1)
	
	--Substitute Logic (for R/S combo)
	local subThis = tSpell and subList[tSpell] and ((tTime - tElapsed) > 0.1)
	
	--Potion & Food Checks
	healthpot = healthpot or 0
	manapot = manapot or 0
	speedpot = speedpot or 0
	foodslot = foodslot or 0
	
	--	WARDEN CC STUFF
	if mainClass == "WARDEN" or subClass == "WARDEN" then
		--	Charged Chop Weave for all wardens and /wardens
		ccNotYetYready = not CD("Charged Chop")
		ccMana			= EnergyBar2
		ccNotAvailable = (not ccNotYetYready and not GetActionUsable(17)) or (ccNotYetYready) or (ccMana <= 160)
		-- Charged Chop info end. Paste this to every warden, and on their skills put: ccpriority
	end

	--Equipment and Pet Protection
	if phealth <= .04 then
			--SwapEquipmentItem()		--Note: Remove the first double dash to re-enable equipment protection.
		for i=1,6 do
			if (IsPetSummoned(i) == true) then
				ReturnPet(i);
			end
		end		
	end
	
	--Check for level 1 mobs, if it is, drop target and acquire a new one.
	if (enemy and LockedOn and (UnitLevel("target") < 2)) then
		TargetNearestEnemy()
		return
	end
	
	--Check for level 1 mobs, if it is, drop target and acquire a new one.
	if (enemy and LockedOn and tdead) then
		return
	end
	
	
--	debug count			
	if combat and DIYCEVars["debugCount"] then
		TimerStart()
	end
	if not combat and DIYCEVars["debugCount"] then
		TimerStop()
	end
	
--Begin Player Skill Sequences

-- Champion = PSYRON
-- Druid = DRUID
-- Knight = KNIGHT 
-- Mage = MAGE
-- Priest = AUGUR
-- Rogue = THIEF
-- Scout = RANGER
-- Warden = WARDEN
-- Warlock = HARPSYN
-- Warrior = WARRIOR
				
--Class: Druid/Scout =========================================================================================================================
			if mainClass == "DRUID" and subClass == "RANGER" then
				--	item set skills:
					-- Soul Soothe 65	50 MP	Instant	1 minute, 30 seconds	250	Makes your target no longer be afraid, removing any fear effects on it. Extract from the Annelia set from Grafu Castle.
					-- Nature's Force Field	70	300 MP, 5% MP	Instant	60 seconds	200	Turns a friendly target into a magnet for natural energy. They accumulate ambient natural energy for 4.0 seconds, then cause 1100.0 Earth Damage to multiple targets within a radius of 80. It also restores 1500.0 HP to all friendly targets within a radius of 80. (This skill's damage and recovery are determined by the friendly target's attributes.) Extract from the Cursed Face set from Tomb of the Seven Heroes.
				if party then
					sickestPartyMember = _getSickestPartyMember()
					sickestPartyMemberbuffs = BuffList(sickestPartyMember)
					sickestPartyMemberHP = PctH(sickestPartyMember)
					sickPartyMemberPoison = _getDebuffedPartyMember(6)	--	Antidote
					sickPartyMemberCurse = _getDebuffedPartyMember(9)		--	Purify
					targetedForSavageBlessing = _getUnbuffedPartyMember('Savage Blessing')
					targetedForBlossomingLife = _getUnbuffedPartyMember('Blossoming Life')
					targetedForRecover = _getUnbuffedPartyMember('Recover')
					targetedForConcentrationPrayer = _getUnbuffedPartyMember('Concentration Prayer')
				end
			
				Skill = {
				--	urgent
					{ name = "Rock Protection",				use = (phealth <= .20 and (boss or elite)) },
					{ name = "Mother Earth's Protection",	use = (phealth <= .40 and (boss or elite)),target='player' },
					{ name = "Group Exorcism",				use = (UnitIsSick('player', 10)) },	--	harmful effects, group spell
				
				--	party
					{ name = "Mother Earth's Protection",	use = (party and thealth <= .40 and (ttboss or ttelite)) },
					{ name = "Curing Seed",					use = (party and combat and ttboss and (not tbuffs['Curing Seed']) and (not tbuffs['Healing Salve'])) },
					{ name = "Body Vitalization",			use = (party and combat and (ttboss or ttelite) and (not tbuffs['Body Vitalization'])) },
					{ name = "Mother Earth's Fountain",		use = (party and sickestPartyMemberHP < 0.9) },
					{ name = "Blossoming Life",				use = (party and combat and targetedForBlossomingLife),target=targetedForBlossomingLife },
					{ name = "Recover",						use = (party and combat and targetedForRecover),target=targetedForRecover },
					{ name = "Antidote",					use = (party and sickPartyMemberPoison), target=sickPartyMemberPoison },
					{ name = "Concentration Prayer",		use = (party and targetedForConcentrationPrayer) },
					{ name = "Savage Blessing",				use = (party and targetedForSavageBlessing), target=targetedForSavageBlessing },
				
				--	alone and targeted a friendly
					{ name = "Mother Earth's Protection",	use = (not party and LockedOn and not enemy and not playerself and thealth <= .40 and (ttboss or ttelite)) },
					{ name = "Savage Blessing",				use = (not party and LockedOn and not enemy and not playerself and not tbuffs['Savage Blessing']) },
					{ name = "Recover",						use = (not party and LockedOn and not enemy and not playerself and not tbuffs['Recover']) },
					{ name = "Blossoming Life",				use = (not party and LockedOn and not enemy and not playerself and not tbuffs['Blossoming Life']) },
					{ name = "Antidote",					use = (not party and LockedOn and not enemy and not playerself and UnitIsSick('target', 6)) },
					
				--	alone, target enemy or self
					{ name = "Recover",						use = (phealth < .6),target='player' },
					{ name = "Antidote",					use = (UnitIsSick('player', 6)),target='player' },
					{ name = "Savage Blessing",				use = (not pbuffs['Savage Blessing']),target='player' },
					{ name = "Recover",						use = (phealth < .8 and not pbuffs['Recover']),target='player' },
					{ name = "Blossoming Life",				use = (phealth < .8 and not pbuffs['Blossoming Life']),target='player' },
					{ name = "Mother Earth's Blessing",		use = (phealth < .8 and (elite or boss) and combat) },
					{ name = "Camellia Flower",				use = (phealth < .8 and ((_countBuff('player',"Camellia Flower") < 3) or (BuffTimeLeft('player', "Camellia Flower") < 1 ))),target='player'},
					{ name = "Concentration Prayer",		use = (not pbuffs['Concentration Prayer']) },
					--	nothing to do, restore nature points
					{ name = "Restore Life",				use = ((_countBuff('player',"Nature's Power") < 15) and (not combat))},
					
				}
				
			if combat and party and (not UnitIsDeadOrGhost('targettarget')) then
				Skill2 = {
					{ name = "Binding Silence",			use = ((ttboss or ttelite) and ttsilenceThis),target='targettarget' },
					{ name = "Withering Seed",			use = ((ttboss or ttelite) ),target='targettarget' },
					{ name = "Weakening Seed",			use = ((ttboss or ttelite) ),target='targettarget' },
					{ name = "Earth Arrow",				use = (true),target='targettarget' },
				}
			end

			if enemy and (not party) and not tdead then
				Skill2 = {
					{ name = "Throat Attack",			use = ((melee or melee2) and silenceThis and EnergyBar2 >= 15) },
					{ name = "Briar Entwinement",		use = (not tbuffs['Briar Entwinement']) },
					{ name = "Vampire Arrows",			use = (EnergyBar2 >= 50 and not tbuffs['Vampire Arrows']) },
					{ name = "Binding Silence",			use = (silenceThis and EnergyBar1 >= .05) },
					{ name = "Mother Nature's Wrath",	use = (not tbuffs["Mother Nature's Wrath"]) },
					{ name = "Rockslide",				use = (true) },
					{ name = "Earth Pulse",				use = (combat and (melee or melee2)) },
					{ name = "Wrist Attack",			use = ((melee or melee2) and not tbuffs['Wrist Attack'] and EnergyBar2 >= 50) },
					{ name = "Joint Blow",				use = ((melee or melee2) and not tbuffs['Joint Blow'] and EnergyBar2 >= 50) },
				}
			end
				
--Class: Mage/Rogue =========================================================================================================================
			elseif mainClass == "MAGE" and subClass == "THIEF" then
				if (arg1=="tosh") then
					tosh = true
				end
					
				--Potions and Buffs
				Skill = {
					{ name = "Item: Potion: Unbridled Enthusiasm", use = ((not pbuffs['Unbridled Enthusiasm']) and (not pbuffs['Thunder Force']) and (not pbuffs['Sprint']) and (IsBagItemUsable("Potion: Unbridled Enthusiasm"))) },
					{ name = "Item: Potion: Lucky Target",	use = ((not pbuffs['Turn of Luck Powder Dust']) and (IsBagItemUsable("Potion: Lucky Target"))) },
					{ name = "Item: Potion: Clear Thought",	use = ((not pbuffs['Clear Thought']) and (IsBagItemUsable("Potion: Clear Thought"))) },
					{ name = "Fang Ritual",					use = (not pbuffs["Fang Ritual"]) and (EnergyBar1 >= 500) },
					{ name = "Shadow Protection",			use = (not pbuffs["Shadow Protection"]) and (EnergyBar1 >= 500) },
				--	shortbuffs
					{ name = "Intensification",				use = (boss and not pbuffs["Intensification"]) and (EnergyBar1 >= 500) },
					{ name = "Elemental Catalysis",			use = (boss and not pbuffs["Elemental Catalysis"]) and (EnergyBar1 >= 500) },
				}
									
				
				--Combat
					if enemy and not tdead then
					local lowtarget = (UnitLevel('player') - UnitLevel('target')) > 5
					Skill2 = {
						{ name = "Flame",						use = (not tosh and not combat and EnergyBar1 >= 30) },
						{ name = "Cursed Fangs",				use = (playerLevel >= 15 and not tbuffs['Cursed Fangs'])},
						{ name = "Fireball",					use = (playerLevel >= 4)},
						{ name = "Flame",						use = (not tosh and EnergyBar1 >= 30) },
								}
					end
				
--Class: Mage/Warden =========================================================================================================================
			elseif mainClass == "MAGE" and subClass == "WARDEN" then
					
				--Potions and Buffs
				Skill = {
					{ name = "Item: Potion: Unbridled Enthusiasm", use = ((not pbuffs['Unbridled Enthusiasm']) and (not pbuffs['Thunder Force']) and (not pbuffs['Sprint']) and (IsBagItemUsable("Potion: Unbridled Enthusiasm"))) },
					{ name = "Item: Potion: Lucky Target",	use = (not pbuffs['Turn of Luck Powder Dust'] and (IsBagItemUsable("Potion: Lucky Target"))) },
					{ name = "Item: Potion: Clear Thought",	use = (not pbuffs['Clear Thought'] and (IsBagItemUsable("Potion: Clear Thought"))) },
					{ name = "Briar Shield",				use = (not pbuffs["Briar Shield"]) and (EnergyBar1 >= 500) },
					{ name = "Earth Scepter",				use = (not pbuffs["Earth Scepter"]) and (EnergyBar1 >= 500) },
				--	shortbuffs
					{ name = "Savage Power",				use = (boss and not pbuffs["Savage Power"]) and (EnergyBar1 >= 500) },
					{ name = "Elven Amulet",				use = (boss and not pbuffs["Elven Amulet"]) and (EnergyBar1 >= 500) },
					{ name = "Intensification",				use = (boss and not pbuffs["Intensification"]) and (EnergyBar1 >= 500) },
					{ name = "Elemental Catalysis",			use = (boss and not pbuffs["Elemental Catalysis"]) and (EnergyBar1 >= 500) },
				}
									
				
				--Combat
					if enemy and not tdead then
					local lowtarget = (UnitLevel('player') - UnitLevel('target')) > 5
					Skill2 = {
						{ name = "Flame",						use = (not combat and EnergyBar1 >= 30) },
						{ name = "Earth Surge",					use = (playerLevel >= 15)},
						{ name = "Fireball",					use = (playerLevel >= 4)},
						{ name = "Flame",						use = (EnergyBar1 >= 30) },
								}
					end
				
-- Class: Priest/Knight 2.22 =========================================================================================================================
			elseif mainClass == "AUGUR" and subClass == "KNIGHT" then
			
				CreateDIYCETimer("GHeal", 5.2)	--	it triggers at skill start so we must include the casting time
				local FairyExists = UnitExists("playerpet")
				if pbuffs['Last Prayer'] or FairyExists then
					PriestFairySequence()
				end
				if party then
					sickestPartyMember = _getSickestPartyMember()
					sickestPartyMemberbuffs = BuffList(sickestPartyMember)
					sickestPartyMemberHP = PctH(sickestPartyMember)
					sickPartyMemberHarmfulEffect = _getDebuffedPartyMember(10)	--	Cleanse
					sickPartyMemberFear = _getDebuffedPartyMember(15)	--	Calm Heart
					targetedForAmplifiedAttack = _getUnbuffedPartyMember('Amplified Attack')
					targetedForRegenerate = _getUnbuffedPartyMember('Regenerate')
					targetedForGraceOfLife = _getUnbuffedPartyMember('Enhanced Grace of Life')
					targetedForMagicBarrier = _getUnbuffedPartyMember('Magic Barrier')
					targetedForBlessedSpringWater = _getUnbuffedPartyMember('Blessed Spring Water')
				end
				
				if not enemy then
					Skill = {
						{ name = "Last Prayer",				use = ((not FairyExists)) },
					--	urgent
						{ name = "Regenerate",				use = (FairyExists and PctH("playerpet") < .8),target="playerpet" },
						{ name = "Holy Aura",				use = (phealth <= .3) },
						{ name = "Soul Source",				use = (phealth < .3) },
						
					--	party
						{ name = "Soul Source",				use = (party and sickestPartyMemberHP < 0.3) },
						{ name = "Group Heal",				use = (party and sickestPartyMemberHP < 0.8 ),timer='GHeal' },
						{ name = "Urgent Heal",				use = (party and sickestPartyMemberHP < 0.8),target=sickestPartyMember },
						{ name = "Healing Salve",			use = (party and combat and (not enemy) and ttboss and (not tbuffs['Healing Salve']) and (not tbuffs['Curing Seed']) ) },
						{ name = "Calm Heart",				use = (party and sickPartyMemberFear and (playerLevel > 17)),target=sickPartyMemberFear },
						{ name = "Cleanse",					use = (party and sickPartyMemberHarmfulEffect and (playerLevel > 17)),target=sickPartyMemberHarmfulEffect },
						{ name = "Grace of Life",			use = (party and (targetedForGraceOfLife)) },
						{ name = "Magic Barrier",			use = (party and (targetedForMagicBarrier)) },
						{ name = "Blessed Spring Water",	use = (party and (targetedForBlessedSpringWater)) },
						{ name = "Amplified Attack",		use = (party and targetedForAmplifiedAttack),target=targetedForAmplifiedAttack },
						{ name = "Divine Incarnation",		use = (party and (not pbuffs['Divine Incarnation'])) },
						{ name = "Regenerate",				use = (party and combat and targetedForRegenerate),target=targetedForRegenerate },
						
					--	alone
						{ name = "Urgent Heal",				use = (not party and LockedOn and not enemy and not playerself and thealth < .8) },
						{ name = "Amplified Attack",		use = (not party and LockedOn and not enemy and not playerself and (not tbuffs['Amplified Attack'])) },
						{ name = "Wave Armor",				use = (not party and LockedOn and not enemy and not playerself and (not tbuffs['Wave Armor'])) },
						{ name = "Regenerate",				use = (not party and LockedOn and not enemy and not playerself and (not tbuffs['Regenerate'])) },
						
					--	common
						{ name = "Urgent Heal",				use = (phealth < .8),target='player' },
						{ name = "Wave Armor",				use = (phealth < .9 and combat and (not tbuffs['Wave Armor'])),target='player' },
						{ name = "Grace of Life",			use = (not pbuffs['Enhanced Grace of Life']) },
						{ name = "Magic Barrier",			use = (not pbuffs['Magic Barrier']) },
						{ name = "Blessed Spring Water",	use = (not pbuffs['Blessed Spring Water']) },
						{ name = "Enhanced Armor",			use = (not pbuffs['Enhanced Armor']) },
						{ name = "Divine Incarnation",		use = (not pbuffs['Divine Incarnation']) },
						{ name = "Soul Bond",				use = (not pbuffs['Soul Bond']),target='player' },
						{ name = "Amplified Attack",		use = (not pbuffs['Amplified Attack']),target='player' },
						
						
					}
				end

					
				-- Combat
			if combat and party and (not UnitIsDeadOrGhost('targettarget')) then
				Skill2 = {
					{ name = "Ice Fog",				use = (not ttbuffs['Ice Fog']),target='targettarget' },
					{ name = "Bone Chill",			use = (not ttbuffs['Bone Chill']),target='targettarget' },
					{ name = "Rising Tide",			use = true,target='targettarget' },
				}
			end
			
			if enemy and not tdead then
				Skill2 = {
				{ name = "Bone Chill",			use = (not tbuffs['Bone Chill']) },
				{ name = "Ice Fog",				use = (not tbuffs['Ice Fog']) },
				{ name = "Rising Tide",			use = true },
				}
	
			end
				
--Class: Rogue/Mage =========================================================================================================================
			elseif mainClass == "THIEF" and subClass == "MAGE" then
				local tbleed = (tbuffs[500654] or tbuffs[620313])
				local twounded = (tbuffs[620314])
				local slotYawakasBlessing = 16	--	Yawaka's Blessing action slot
				
				--Timers for this class
					CreateDIYCETimer("SSBleed", 8.8) --Change the value between 6 -> 7.5 depending on your lag.
					CreateDIYCETimer("LBBleed", 8.8) --Change the value between 7 ->  8.5 depending on your lag.
					
				--Potions and Buffs
				Skill = {
					{ name = "Enchanted Throw",				use = (not pbuffs["Enchanted Throw"]) and (EnergyBar2 >= 25) },
					{ name = "Item: Potion: Unbridled Enthusiasm", use = ((not pbuffs['Unbridled Enthusiasm']) and (not pbuffs['Thunder Force']) and (not pbuffs['Sprint']) and (IsBagItemUsable("Potion: Unbridled Enthusiasm"))) },
					{ name = "Item: Potion: Lucky Target",	use = ((not pbuffs['Turn of Luck Powder Dust']) and (IsBagItemUsable("Potion: Lucky Target"))) },
				--	shortbuffs
					{ name = "Fervent Attack",				use = (boss) and (not pbuffs['Strong Stimulant']) and (not pbuffs['Fervent Attack']) },	--	rogue primary	30s
					{ name = "Item: Strong Stimulant",		use = (boss and(not pbuffs['Strong Stimulant']) and (not pbuffs['Fervent Attack']) and (IsBagItemUsable("Potion: Clear Thought"))) },	--	potion	30s
					{ name = "Evasion",						use = (boss and combat and phealth < .8) },	--	rogue primary	10s
					{ name = "Assassins Rage",				use = (boss) },	--	rogue primary	15s
					{ name = "Premeditation",				use = (boss and (not combat) and not pbuffs["Premeditation"]) and (EnergyBar1 >= 20) },	--	rogue primary
				}
									
				
				--Combat
					if enemy and not tdead then
					local lowtarget = (UnitLevel('player') - UnitLevel('target')) > 5
					Skill2 = {
						{ name = "Wound Attack",				use = (EnergyBar1 >= 35) and (tbleed) and twounded },
						{ name = "Low Blow",					use = (EnergyBar1 >= 30) and (tbleed) and (not twounded) },
						{ name = "Shadowstab",					use = (EnergyBar1 >= 20) and (not tbleed) },
						{ name = "Low Blow",					use = (EnergyBar1 >= 30) },
								}
					end
				
--Class: Rogue/Scout =========================================================================================================================
			elseif mainClass == "THIEF" and subClass == "RANGER" then
				local tbleed = (tbuffs[500654] or tbuffs[620313])
				local twounded = (tbuffs[620314])
				--Timers for this class
					CreateDIYCETimer("SSBleed", 8.8) --Change the value between 6 -> 7.5 depending on your lag.
					CreateDIYCETimer("LBBleed", 8.8) --Change the value between 7 ->  8.5 depending on your lag.
					
				--Potions and Buffs
				Skill = {
					{ name = "Combat Master",				use = ((not pbuffs["Combat Master"]) or (pbuffs["Combat Master"].time <= 45)) and (EnergyBar2 >= 30) },
					{ name = "Item: Potion: Unbridled Enthusiasm", use = ((not pbuffs['Unbridled Enthusiasm']) and (not pbuffs['Thunder Force']) and (not pbuffs['Sprint']) and (IsBagItemUsable("Potion: Unbridled Enthusiasm"))) },
					{ name = "Item: Potion: Lucky Target",	use = ((not pbuffs['Turn of Luck Powder Dust']) and (IsBagItemUsable("Potion: Lucky Target"))) },
					{ name = "Item: Potion: Clear Thought",	use = ((not pbuffs['Clear Thought']) and (IsBagItemUsable("Potion: Clear Thought"))) },
					{ name = "Energy Thief",				use = ((EnergyBar1 < 25) and (boss) and (not tDead)) },
					{ name = "Fervent Attack",				use = (boss) and (not pbuffs['Strong Stimulant']) and (not pbuffs['Fervent Attack']) and (pbuffs["Energy Thief"]) },	--	rogue primary	30s
					{ name = "Item: Strong Stimulant",		use = (boss and(not pbuffs['Strong Stimulant']) and (not pbuffs['Fervent Attack']) and (IsBagItemUsable("Potion: Clear Thought"))) },	--	potion	30s
					{ name = "Evasion",						use = (boss and combat and phealth < .8) },	--	rogue primary	10s
					{ name = "Assassins Rage",				use = (boss) },	--	rogue primary	15s
					{ name = "Premeditation",				use = (not combat) and boss and (EnergyBar1 >= 50) and (not pbuffs["Premeditation"]) },
					{ name = "Substitute",					use = subThis and (EnergyBar2 >= 30) },
				}
									
				
				--Combat
					if enemy and not tdead then
					Skill2 = {
						{ name = "Throat Attack",				use = melee and (silenceThis) },
						{ name = "Wrist Attack",				use = (EnergyBar2 >= 35) and boss },
						{ name = "Sneak Attack",				use = (EnergyBar1 >= 20) and boss and behind and party and (not combat) },
						{ name = "Blind Spot",					use = (EnergyBar1 >= 20) and boss and behind and party },
						
						{ name = "Vampire Arrows",				use = (not melee) and (EnergyBar2 >= 20) },
						{ name = "Wound Attack",				use = (EnergyBar1 >= 35) and (tbleed) and twounded },
						{ name = "Low Blow",					use = (EnergyBar1 >= 25) and (tbleed) and (not twounded) },
						{ name = "Shadowstab",					use = (EnergyBar1 >= 20) and (not tbleed) },
						{ name = "Low Blow",					use = (EnergyBar1 >= 25) },	
						{ name = "Vampire Arrows",				use = (EnergyBar2 >= 20) },
						{ name = "Shot",						use = true },				
						{ name = "Attack",						use = (thealth == 1) },					
								}
					end
				
--Class: Rogue/Warden =========================================================================================================================
			elseif mainClass == "THIEF" and subClass == "WARDEN" then
				local tbleed = (tbuffs[500654] or tbuffs[620313])
				local twounded = (tbuffs[620314])
				local slotYawakasBlessing = 16	--	Yawaka's Blessing action slot
				
				--Timers for this class
					CreateDIYCETimer("SSBleed", 8.8)	--Change the value between 6 -> 7.5 depending on your lag.
					CreateDIYCETimer("LBBleed", 8.8)	--Change the value between 7 ->  8.5 depending on your lag.
					CreateDIYCETimer("WSG", 21)			--Wood Spirit's Grasp
					
				--Potions and Buffs
				Skill = {
					{ name = "Briar Shield",				use = (not pbuffs["Briar Shield"]) and (EnergyBar2 >= 500) },
					{ name = "Wound Patch",					use = (not pbuffs["Wound Patch"]) and (EnergyBar1 >= 50) },
					{ name = "Item: Potion: Unbridled Enthusiasm", use = ((not pbuffs['Unbridled Enthusiasm']) and (not pbuffs['Thunder Force']) and (not pbuffs['Sprint']) and (IsBagItemUsable("Potion: Unbridled Enthusiasm"))) },
					{ name = "Item: Potion: Lucky Target",	use = ((not pbuffs['Turn of Luck Powder Dust']) and (IsBagItemUsable("Potion: Lucky Target"))) },
				--	shortbuffs
					{ name = "Savage Power",				use = (boss and not pbuffs["Savage Power"]) and (EnergyBar2 >= 500) },	--	warden general	30s
					{ name = "Fervent Attack",				use = (boss) and (not pbuffs['Strong Stimulant']) and (not pbuffs['Fervent Attack']) },	--	rogue primary	30s
					{ name = "Item: Strong Stimulant",		use = (boss and(not pbuffs['Strong Stimulant']) and (not pbuffs['Fervent Attack']) and (IsBagItemUsable("Strong Stimulant"))) },	--	potion	30s
					{ name = "Evasion",						use = (boss and combat and phealth < .8) },	--	rogue primary	10s
					{ name = "Assassins Rage",				use = (boss) },	--	rogue primary	15s
					{ name = "Elven Amulet",				use = (boss and not pbuffs["Elven Amulet"]) and (EnergyBar2 >= 500) },	--	warden general	10s
					--{ name = "Premeditation",				use = (boss and (not combat) and not pbuffs["Premeditation"]) and (EnergyBar1 >= 20) },	--	rogue primary
				}
									
				
				--Combat
					if enemy and not tdead then
					local lowtarget = (UnitLevel('player') - UnitLevel('target')) > 5
					Skill2 = {
						{ name = "Power of the Wood Spirit",	use = (boss),timer='WSG'},
						{ name = "Charged Chop",				use = (true)},
						{ name = "Wound Attack",				use = (EnergyBar1 >= 35) and (tbleed) and twounded and ccNotAvailable },
						{ name = "Low Blow",					use = (EnergyBar1 >= 30) and (tbleed) and (not twounded) and ccNotAvailable },
						{ name = "Shadowstab",					use = (EnergyBar1 >= 20) and (not tbleed) and ccNotAvailable },
						{ name = "Throw",						use = (boss and countProjectiles > 0 and ccNotAvailable) },
						{ name = "Phantom Blade",				use = (boss and pctEB2 >= .1 and ccNotAvailable) },
						--	fillers
						{ name = "Low Blow",					use = (EnergyBar1 >= 65) and ccNotAvailable },
						{ name = "Bloodthirsty Blade",			use = (pctEB2 >= .1) and ccNotAvailable },
						{ name = "Weak Point Strike",			use = (EnergyBar2 >= 300 and boss and ccNotAvailable) },
								}
					end
				
--Class: Warden/Rogue =========================================================================================================================
			elseif mainClass == "WARDEN"  and subClass == "THIEF" then
			-- Msg("Subclassy: " .. subClass);
				local slotTranquilWave = 16
				local SpiritOfTheOakActive = UnitExists("pet") and (UnitName("pet") == "Spirit of the Oak")
				local NatureCrystalActive = UnitExists("pet") and (UnitName("pet") == "Nature Crystal")
			
			--Potions and Buffs
			Skill = {
				{ name = "Item: Potion: Unbridled Enthusiasm", use = ((not pbuffs['Unbridled Enthusiasm']) and (not pbuffs['Thunder Force']) and (not pbuffs['Sprint']) and (IsBagItemUsable("Potion: Unbridled Enthusiasm"))) },
				{ name = "Item: Potion: Lucky Target",	use = ((not pbuffs['Turn of Luck Powder Dust']) and (IsBagItemUsable("Potion: Lucky Target"))) },
				{ name = "Item: Potion: Clear Thought",	use = ((not pbuffs['Clear Thought']) and (IsBagItemUsable("Potion: Clear Thought"))) },
			--	shortbuffs
				{ name = "Briar Shield",				use = (pctEB1 >= .05) and ((not pbuffs["Briar Shield"]))},
				{ name = "Action:"..slotTranquilWave,	use = (pctEB1 >= .05) and ((not pbuffs["Tranquil Wave"]))},			--	900
				{ name = "Protection of Nature",		use = (pctEB1 >= .05) and ((not pbuffs["Protection of Nature"]))},
				{ name = "Savage Power",				use = (boss and not pbuffs["Savage Power"]) and (EnergyBar2 >= 500) },
				{ name = "Elven Amulet",				use = (boss and not pbuffs["Elven Amulet"]) and (EnergyBar2 >= 500) },
				-- { name = "Summon Spirit of the Oak",	use = (not combat and not pbuffs["Heart of the Oak"]) and (not SpiritOfTheOakActive) and (pctEB1 >= .15) },
			}
					
			--Combat
				if enemy and not tdead then
					local lowtarget = (UnitLevel('player') - UnitLevel('target')) > 5
					Skill2 = {
						{ name = "Shadowstab",					use = (EnergyBar1 >= 30) and lowtarget },
						{ name = "Charged Chop",				use = (EnergyBar1 >= 70)},
						{ name = "Shadowstab",					use = (EnergyBar1 >= 20) and ccNotAvailable },
					}
				end
				
--Class: Warden/Scout =========================================================================================================================
			elseif mainClass == "WARDEN"  and subClass == "RANGER" then
			-- Msg("Subclassy: " .. subClass);
				
				local SpiritOfTheOakActive = UnitExists("pet") and (UnitName("pet") == "Spirit of the Oak")
				local NatureCrystalActive = UnitExists("pet") and (UnitName("pet") == "Nature Crystal")
			
			--Potions and Buffs
			Skill = {
				{ name = "Item: Potion: Unbridled Enthusiasm", use = ((not pbuffs['Unbridled Enthusiasm']) and (not pbuffs['Thunder Force']) and (not pbuffs['Sprint']) and (IsBagItemUsable("Potion: Unbridled Enthusiasm"))) },
				{ name = "Item: Potion: Lucky Target",	use = ((not pbuffs['Turn of Luck Powder Dust']) and (IsBagItemUsable("Potion: Lucky Target"))) },
				{ name = "Item: Potion: Clear Thought",	use = ((not pbuffs['Clear Thought']) and (IsBagItemUsable("Potion: Clear Thought"))) },
			--	shortbuffs
				{ name = "Briar Shield",				use = (pctEB1 >= .05) and ((not pbuffs["Briar Shield"]))},			--	900
				{ name = "Protection of Nature",		use = (pctEB1 >= .05) and ((not pbuffs["Protection of Nature"]))},	--	300
				{ name = "Power of the Oak",			use = (boss and EnergyBar2 >= 500) },	--	30
				{ name = "Savage Power",				use = (boss and EnergyBar2 >= 500) },	--	30
				{ name = "Elven Amulet",				use = (boss and EnergyBar2 >= 500) },	--	10
				{ name = "Immortal Power",				use = (boss and(not pbuffs["Immortal Power"]) and EnergyBar2 >= 500) },	--	10
			}
					
			--Combat
				if enemy and not tdead then
					local lowtarget = (UnitLevel('player') - UnitLevel('target')) > 5
					Skill2 = {
						{ name = "Double Chop",				use = (EnergyBar1 >= 60) and lowtarget },
						{ name = "Charged Chop",			use = (EnergyBar1 >= 120)},
						{ name = "Frantic Briar",			use = (EnergyBar1 >= 420 and ccNotAvailable)},
						{ name = "Cross Chop",				use = (EnergyBar1 >= 245 and ccNotAvailable)},
					}
				end
				
--Class: Warden/Warrior =========================================================================================================================
			elseif mainClass == "WARDEN"  and subClass == "WARRIOR" then
			-- Msg("Subclassy: " .. subClass);
				
				local slotTranquilWave = 16
				local SpiritOfTheOakActive = UnitExists("pet") and (UnitName("pet") == "Spirit of the Oak")
				local NatureCrystalActive = UnitExists("pet") and (UnitName("pet") == "Nature Crystal")
			
			--Potions and Buffs
			Skill = {
				{ name = "Item: Potion: Unbridled Enthusiasm", use = ((not pbuffs['Unbridled Enthusiasm']) and (not pbuffs['Thunder Force']) and (not pbuffs['Sprint']) and (IsBagItemUsable("Potion: Unbridled Enthusiasm"))) },
				{ name = "Item: Potion: Lucky Target",	use = ((not pbuffs['Turn of Luck Powder Dust']) and (IsBagItemUsable("Potion: Lucky Target"))) },
				{ name = "Item: Potion: Clear Thought",	use = ((not pbuffs['Clear Thought']) and (IsBagItemUsable("Potion: Clear Thought"))) },
			--	shortbuffs
				{ name = "Briar Shield",				use = (pctEB1 >= .05) and ((not pbuffs["Briar Shield"]))},			--	900
				{ name = "Action:"..slotTranquilWave,	use = (pctEB1 >= .05) and ((not pbuffs["Tranquil Wave"]))},			--	900
				{ name = "Protection of Nature",		use = (pctEB1 >= .05) and ((not pbuffs["Protection of Nature"]))},	--	300
				{ name = "Berserk",						use = (boss and pctEB2 >= 25)},			--	30
				{ name = "Power of the Oak",			use = (boss and EnergyBar2 >= 500) },	--	30
				{ name = "Savage Power",				use = (boss and EnergyBar2 >= 500) },	--	30
				{ name = "Elven Amulet",				use = (boss and EnergyBar2 >= 500) },	--	10
				{ name = "Immortal Power",				use = (boss and(not pbuffs["Immortal Power"]) and EnergyBar2 >= 500) },	--	10
			}
					
			--Combat
				if enemy and not tdead then
					local lowtarget = (UnitLevel('player') - UnitLevel('target')) > 5
					Skill2 = {
						{ name = "Enraged",					use = (combat) },
						{ name = "Double Chop",				use = (EnergyBar1 >= 60) and lowtarget },
						{ name = "Charged Chop",			use = (EnergyBar1 >= 120)},
						{ name = "Pulse Mastery",			use = (EnergyBar2 >= 20 and tbuffs[620690] and ccNotAvailable) },
						{ name = "Beast Chop",				use = (EnergyBar2 >= 20 and ccNotAvailable) },
						{ name = "Double Chop",				use = (EnergyBar1 >= 420 and ccNotAvailable)},
						{ name = "Slash",					use = (EnergyBar2 >= 25 and ccNotAvailable) },
						{ name = "Frantic Briar",			use = (EnergyBar1 >= 420 and ccNotAvailable)},
						{ name = "Cross Chop",				use = (EnergyBar1 >= 245 and ccNotAvailable)},
					}
				end
			
			--ADD MORE CLASS COMBOS ABOVE THIS LINE. 
			--USE AN "ELSEIF" TO CONTINUE WITH MORE CLASS COMBOS.
			--THE NEXT "END" STATEMENT IS THE END OF THE CLASS COMBOS STATEMENTS.
			--DO NOT ADD ANYTHING BELOW THE FOLLOWING "END" STATEMENT!
		end
	--End Player Skill Sequences ========================================================================================================================= =========================================================================================================================
	
	if (arg1=="debugskills") then		--Used for printing the skill table, and true/false usability
		DIYCE_DebugSkills(Skill)
		DIYCE_DebugSkills(Skill2)
	elseif (arg1=="debugpbuffs") then	--Used for printing your buff names, and buffID
		DIYCE_DebugBuffList(pbuffs)
	elseif (arg1=="debugtbuffs") then	--Used for printing target buff names, and buffID
		DIYCE_DebugBuffList(tbuffs)
	elseif (arg1=="debugall") then		--Used for printing all of the above at the same time
		DIYCE_DebugSkills(Skill)
		DIYCE_DebugSkills(Skill2)
		DIYCE_DebugBuffList(pbuffs)
		DIYCE_DebugBuffList(tbuffs)
	end
	
	if (not MyCombat(Skill, arg1)) then
		MyCombat(Skill2, arg1)
	end
		
	--Select Next Enemy
	-- if (tDead) then
		-- TargetUnit("")
		-- g_lastaction = ""
		-- return
	-- end
	
	if SeigeWar then
		if (not LockedOn) or (not enemy) then
			for i=1,10 do
				if UnitIsPlayer("target") then
					break
				end
				TargetNearestEnemy()
					StopDIYCETimer("LBBleed")
					StopDIYCETimer("SSBleed")
				return
			end
		end
	
	elseif (not SeigeWar) then
		-- if mainClass == "RANGER" and (not party) then		--To keep scouts from pulling mobs without meaning to.
			-- if (not LockedOn) or (not enemy) then
				-- TargetNearestEnemy()
						-- g_lastaction = ""
					-- StopDIYCETimer("LBBleed")
					-- StopDIYCETimer("SSBleed")
				-- return
			-- end
		-- elseif mainClass ~= "RANGER" then					--Let all other classes auto target.
			-- if (not LockedOn) or (not enemy) then
				-- TargetNearestEnemy()
						-- g_lastaction = ""
					-- StopDIYCETimer("LBBleed")
					-- StopDIYCETimer("SSBleed")
				-- return
			-- end
		-- end
	end
end