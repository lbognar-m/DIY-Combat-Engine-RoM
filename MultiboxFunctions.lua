--[[

20. melee check
19. range check friend
18. range cjeck enemy
17. charged chop / something else thatn has no GCD

1.	ATTACK button

2.	Target unit by name (if not party, it doesn't do anything):
	_targetUnitByName("charactername",'target')
	
3.	follow unit by name
	FollowUnit(_targetUnitByName(name))
	
4. mount
	
5.	auto accept and turn quests (1 - not accepted, 2 - accepted, not completed, 3 - completed). can be used for loot also
/cast Attack
/script OnClick_QuestListButton(1, 1)
/script OnClick_QuestListButton(3, 1)
/script AcceptQuest()
/script CompleteQuest()
	
6. autofight
/script _targetUnitByName("charactername",'target')
/script KillSequence()
	
7. autofight tank target
/script _targetUnitByName("charactername",'target')
/script TargetUnit('targettarget')
/script KillSequence()
	
8. auto accept and agree trades, ride mounts, party invite, duel and resurrect
/script AgreeTrade()
/script AcceptTrade("")
/script AcceptRideMount()
/script AcceptGroup()
/script AcceptDuel()
/script AcceptResurrect()

9. manual ohshit skill (group) -> holy candle

0. manual ohshit skill per member: holy aura, rock protection, substitute ...

-. unsummon pet?

==================================
leaderfunctions

1.	create party
	/invite name1
	/invite name1
	/invite name1

2. destroy party (needs helperfunctions)
	/script _destroyGroup()

==================================
rutinfunctions

/script Houses_AddFriend("Roxike");
/script Houses_AddFriend("Melgana");
/script Houses_AddFriend("Lucylle");
/script Houses_AddFriend("Nerayne");
/script Houses_AddFriend("Babszem");
/script Houses_AddFriend("Szürkegém");

/script AddFriend("Friend", "Roxike");
/script AddFriend("Friend", "Melgana");
/script AddFriend("Friend", "Lucylle");
/script AddFriend("Friend", "Nerayne");
/script AddFriend("Friend", "Babszem");
/script AddFriend("Friend", "Szürkegém");

Napicsibe

]]--



--	item preview target
/script ItemPreviewFrame:Show(); ItemPreviewFrame:SetSize(260*2, 350*2); ItemPreviewFrameModel:SetUnit("target", 1)

SummonPet(1);
--Summons the pet in egg slot 1.

--Send item to character "Twink" with COD amount of 1000 gold.
PickupBagItem(index); -- bag index of the item
ClickSendMailItemButton();
SetSendMailCOD(1000, 0);
SendMail("Twink", "Your requested item", "Have fun with it, and thanks for buying.");

--	cast thunderstorm
/script CastSpellByName("Thunderstorm")
/wait 0.15
/script CastSpellByName("Thunderstorm")
/script SpellTargetUnit()

--Switches party to raid
SwitchToRaid();

--Verifies if a given unit is dead or waiting for resurrection.
UnitIsDeadOrGhost(UnitId)

--Get the class tokens of a unit.
mainClass, subClass = UnitClassToken( unit )

--measure casting time TEST
local name, maxValue, currValue = UnitCastingTime("target") 

--Targets nearest friend in line of sight.
TargetNearestFriend(bool previous)

--Can be used to target the nearest enemy in line of sight.
--Is called twice (or more) target next enemy (allways in line of sight).
 TargetNearestEnemy(bool previous)
 
UsePetAction(x,[true])
-- Arguments
-- x - Pet Actionbar 1-10 
-- [true] - optional argument that serves as RightMouseButton

-- Completes the quest when the NPC quest window is opened. This is like pressing the Complete quest button.
CompleteQuest();

-- Closes all current opened windows
CloseAllWindows()

-- Accepts a trade request from another player
AgreeTrade();

-- Accepts a pending trade request. Use this after you've agreed to trade.
AcceptTrade(player or "");

--I guess its for the upcoming 2-Person mounts. It accepts the invitation.
AcceptRideMount()


-- Unit ID

-- These are the various unit identifiers that are used by functions requiring a UnitId argument.
-- UnitId	 Description	 Format	 Example
-- "player"	 current player		
-- "pet"	 current pet of player		
-- "target"	 current target		
-- "mouseover"	 current item under mouse cursor		
-- "focus<N>"	 current focus	<N> = 1 to 12	 "focus12"
-- "party<N>"	 current party member	<N> = 1 to 5	 "party3"
-- "raid<N>"	 current raid member	<N> = 1 to 36	 "raid22"
-- [edit]Combined Unit ID
-- It is valid to combine unit identifiers to reference an other type of unit. Add target after any of the above to find their target. E.g. "playertargettargettarget" returns the Target of the Target of the Target that the Player is targeting. (please add more if you know them):
-- Combined UnitId	 Description	 Format	 Example
-- "<primaryID>target"	 current <primaryID> target	<primaryID> = UnitId	 "party3target"
-- "<primaryID>pet"	 current <primaryID> pet	<primaryID> = UnitId	 "focus8pet"
-- Swaps equipment to a second slot to preserve durability loss when death is imminent. Also returns pet. 
/run SwapEquipmentItem(-1)
/wait .5
/run ReturnPet(1)


-- Will use a simple repair hammer on any piece of gear that has fallen below 101 durability. 
/run for i = 0 , 16, 1 do local dV, dM, iN, dVF, dMF = GetInventoryItemDurable("player",i) if(dV < dM and dV < 101 and dM >= 102) then UseItemByName("Simple Repair Hammer"); PickupEquipmentItem(i); SendSystemChat("Hammered " .. iN); break; end end

-- Siege target macro (+ says class name in red system text [ty Gamja])
/run for i=1,10 do TargetNearestEnemy(IsShiftKeyD­own()) if UnitIsPlayer("target") then break end end
/run if not UnitIsPlayer("target") then TargetUnit("") end
/run primary,secondary = UnitClass("target")
/run﻿ SendWarningMsg(primary.."/"..s­econdary)

--move FPS&PING to top of screen “Donatfisch”
/script FramerateText:ClearAllAnchors(); FramerateText:SetAnchor("TOPLEFT", "TOPLEFT", WorldFrame, 1110, 655); FramerateText:Show();

-- pvp glove macro
/script UseItemByName("Gloves of Assassination");
/wait .1
/script UseEquipmentItem(1)
/wait .1
/script UseItemByName("Leather Gloves of Vigilance");
/wait 60
/wait 60
/w Bleedingblak PVPGLOVS

-- Siege Target macro (only targets enemy players)
/run for i=1,10 do TargetNearestEnemy(IsShiftKeyDown()) if UnitIsPlayer("target") then break end end
/run if not UnitIsPlayer("target") then TargetUnit("") end

-- Fire Training
/run SetTitleRequest(530467);
/wait .2
/cast Fire Training
/wait 20
/s ReCast Fire Training
/s ReCast Fire Training
/p ReCast Fire Training
/p ReCast Fire Training
/wait 40
/wait 60
/wait 60
/wait 60
/w Bleedingblak FT ready

-- Macro Name : ISS Quickselect
-- Description : Equips an ISS from your list.
-- Usage : Set "X" as the tab # that your class is, and set "Y" as the # of the skill going down the list. Ex: 1st skill on 2nd tab would be: x=2, y=1. I use this to quickly switch out to preset ISS combinations. NOTE: you cannot switch ISS during combat! NOTE2: This takes a bit of manual setup and testing to work properly and make sure the right ISS is kicked when you equip the new one.
/script JOBINDEX=X SKILLINDEX=Y SkillSuitFrame_GetSkill_OnClick()

-- Removes everyone from your Nemesis List.
/script while GetFriendCount("HateFriend") > 0 do DelFriend("HateFriend", GetFriendInfo("HateFriend", 1)); end

-- Quick Feed Pet Macro
/script for i = 1, 99, 1 do FeedPet(1) end

-- Description : allows you to inspect any target, including npc's and mobs, however npc's and mobs will never have gear on.
/run InspectUnit("target")

-- Description : gets title Id number for further use in creating title swap macros.
/run DEFAULT_CHAT_FRAME:AddMessage("Title Number = "..GetCurrentTitle())

-- Description: Target specific npcs and nothing else.
-- Usage: Replace X,y,z,etc. with "unitname" (ex. "Plague Ball"). Such as targetting only Plague Balls on last boss bethomia or Quest related npcs. Replace "TargetNearestFriend()" with "TargetNearestEnemy()" if checking for enemies.
/run for i=1,20 do local name=UnitName("target") if name == X or name == Y or name== Z then break else TargetNearestFriend() end end if not (name == X or name == Y or name == Z) then TargetUnit("") end

-- Heffner quick daily macro Ern a Reputation
-- Macro Name : Ern a Reputation daily
-- Description: Target npcs related to the daily( Quest giver and Unconfortable ) and interact with them. Daily notes is needed, and Ern a Reputation daily has to be marked on auto accept/turn in.
-- Use: Stay near the npcs and use the macro. Might need to increase the waiting timer after the /cast attack, if you use the macro a little far from the npc, so it has enough time to walk up to him before start talking.
/run for i=1,15 do local x=UnitName("target") if not (x == "Hugope" or x== "Uncomfortable Adventurer") then TargetNearestFriend() else break end end
/cast Attack
/wait .2
/cast Attack
/run ChoiceOption(1)
/wait .3
/run ChoiceOption(1)
/wait 2
/run TargetUnit("")

-- Macro Name : Quick Scrutinizer reset
-- Description : reset scrutinizer without confirmation
/run scrutinizer:Reset()

-- Coat of Arms (Pet) - Warden Warrior
-- Put your current target into focus, targets pet, casts Coat of arms on it, re-targets your original target, then clears focused target.
/run FocusUnit(12,"target")
/run TargetUnit("pet")
/run CastSpellByName("Coat of Arms")
/run TargetUnit("focus12")
/run FocusUnit(12,"nil")