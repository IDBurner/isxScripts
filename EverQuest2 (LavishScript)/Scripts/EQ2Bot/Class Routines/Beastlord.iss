;*************************************************************
;Beastlord.iss
;version 20111211a
;alpha
;by Pygar
;
;*************************************************************
#ifndef _Eq2Botlib_
	#include "${LavishScript.HomeDirectory}/Scripts/${Script.Filename}/Class Routines/EQ2BotLib.iss"
#endif

; this script is the suck, someone port monk please (pygar)
function Class_Declaration()
{
  ;;;; When Updating Version, be sure to also set the corresponding version variable at the top of EQ2Bot.iss ;;;;
  declare ClassFileVersion int script 20111211a
  ;;;;

	declare PetType int script
	declare StanceType int script 1
	declare AoEMode bool script FALSE
	declare PBAoEMode bool script FALSE
	declare PetMode bool script 1

	call EQ2BotLib_Init

	PetType:Set[${CharacterSet.FindSet[${Me.SubClass}].FindSetting[Pet Type,3]}]
	AoEMode:Set[${CharacterSet.FindSet[${Me.SubClass}].FindSetting[Cast AoE Spells,FALSE]}]
	PBAoEMode:Set[${CharacterSet.FindSet[${Me.SubClass}].FindSetting[Cast PBAoE Spells,FALSE]}]
	PetMode:Set[${CharacterSet.FindSet[${Me.SubClass}].FindSetting[Use Pets,TRUE]}]

}

function Pulse()
{
	;;;;;;;;;;;;
	;; Note:  This function will be called every pulse, so intensive routines may cause lag.  Therefore, the variable 'ClassPulseTimer' is
	;;        provided to assist with this.  An example is provided.
	;
	;			if (${Script.RunningTime} >= ${Math.Calc64[${ClassPulseTimer}+2000]})
	;			{
	;				Debug:Echo["Anything within this bracket will be called every two seconds.
	;			}
	;
	;         Also, do not forget that a 'pulse' of EQ2Bot may take as long as 2000 ms.  So, even if you use a lower value, it may not be called
	;         that often (though, if the number is lower than a typical pulse duration, then it would automatically be called on the next pulse.)
	;;;;;;;;;;;;

	;; check this at least every 0.5 seconds
	if (${Script.RunningTime} >= ${Math.Calc64[${ClassPulseTimer}+500]})
	{
		;check if we have a pet or a hydromancy not up
		if !${Me.ToActor.Pet(exists)} && !${Me.Maintained[${SpellType[379]}](exists)} && ${PetMode}
		{
			call SummonPet
			waitframe
		}

		call CheckHeals
		call RefreshPower

		;; This has to be set WITHIN any 'if' block that uses the timer.
		ClassPulseTimer:Set[${Script.RunningTime}]
	}
}

function Class_Shutdown()
{
}

function Buff_Init()
{
	PreAction[1]:Set[Pathfinding]
	PreSpellRange[1,1]:Set[302]

	PreAction[2]:Set[Offensive_Stance]
	PreSpellRange[2,1]:Set[290]

}

function Combat_Init()
{

}

function PostCombat_Init()
{

}

function Buff_Routine(int xAction)
{
	declare tempvar int local
	declare Counter int local
	declare BuffMember string local
	declare BuffTarget string local

	;check if we have a pet or a hydromancy not up
	if !${Me.ToActor.Pet(exists)} && ${PetMode}
		call SummonPet

	; Pass out feathers on initial script startup
	if !${InitialBuffsDone}
	{
		if (${Me.GroupCount} > 1)
			call CastSpellRange 402
		InitialBuffsDone:Set[TRUE]
	}

	call CheckHeals
	call RefreshPower

	switch ${PreAction[${xAction}]}
	{
		case Pathfinding
			if !${Me.Maintained[${SpellType[${PreSpellRange[${xAction},1]}]}](exists)}
			{
				call CastSpellRange ${PreSpellRange[${xAction},1]}
			}
			break
		case Offensive_Stance
			if ${StanceType}==1
			if !${Me.Maintained[${SpellType[${PreSpellRange[${xAction},1]}]}](exists)}
			{
				call CastSpellRange ${PreSpellRange[${xAction},1]}
			}
			break
		Default
			return Buff Complete
			break
	}
}

function Combat_Routine(int xAction)
{
	declare spellsused int local
	declare spellthreshold int local

	spellsused:Set[0]
	spellthreshold:Set[1]

	if (!${RetainAutoFollowInCombat} && ${Me.ToActor.WhoFollowing(exists)})
	{
		EQ2Execute /stopfollow
		AutoFollowingMA:Set[FALSE]
		wait 3
	}

	if ${Me.Pet(exists)} && !${Me.Pet.InCombatMode}
		call PetAttack	

	if !${Me.ToActor.Pet(exists)} && ${PetMode}
		call SummonPet
	
	;;;; Buff Ralissj's Insight
	if ${Me.Ability[${SpellType[392]}].IsReady} && ${spellsused}<=${spellthreshold} && !${Me.Maintained[${SpellType[392]}](exists)}
	{
		call CastSpellRange 392	
		spellsused:Inc
	}

	;;;;PBAOE
	if ${spellsused}<=${spellthreshold} && ${Mob.Count}>1 && ${Me.Ability[${SpellType[394]}].IsReady} 
	{
		call CastSpellRange 394 0 0 0 ${KillTarget}
		spellsused:Inc
	}

	;;;;Rush
	if ${spellsused}<=${spellthreshold} && ${Me.Ability[${SpellType[151]}].IsReady} 
	{
		call CastSpellRange 151 0 0 0 ${KillTarget}
		spellsused:Inc
	}			

	if ${Me.Ability[Sinister Strike].IsReady} && ${Actor[${KillTarget}](exists)} && !${InvalidMasteryTargets.Element[${Actor[${KillTarget}].ID}](exists)} && (${Actor[${KillTarget}].Target.ID}!=${Me.ID} || !${Actor[${KillTarget}].CanTurn})
	{
		Target ${KillTarget}
		call CheckPosition 1 1 ${KillTarget}
		Me.Ability[Sinister Strike]:Use
		wait 4
	}

	;;;;Sharpened Claws
	if ${spellsused}<=${spellthreshold} && ${Me.Ability[${SpellType[153]}].IsReady} 
	{
		call CastSpellRange 153 0 0 0 ${KillTarget}
		spellsused:Inc
	}	

	;;;;Spinechiller Blood
	if ${spellsused}<=${spellthreshold} && ${Me.Ability[${SpellType[152]}].IsReady} 
	{
		call CastSpellRange 152 0 0 0 ${KillTarget}
		spellsused:Inc
	}	

	;;;;Quick Swipe
	if ${spellsused}<=${spellthreshold} && ${Me.Ability[${SpellType[150]}].IsReady} 
	{
		call CastSpellRange 150 0 0 0 ${KillTarget}
		spellsused:Inc
	}	
		
}

function Post_Combat_Routine(int xAction)
{
	TellTank:Set[FALSE]

	switch ${PostAction[${xAction}]}
	{
		default
			return PostCombatRoutineComplete
			break
	}
}

function Have_Aggro()
{
	echo Aggro from ${aggroid}
	KillTaget:Set[${aggroid}]
	if !${TellTank} && ${WarnTankWhenAggro}
	{
		eq2execute /tell ${MainTank}  ${Actor[${aggroid}].Name} On Me!
		TellTank:Set[TRUE]
	}

	if !${MainTank}
		call CastSpellRange 185 0 0 0 ${aggroid}

}

function Lost_Aggro(int mobid)
{
}

function MA_Lost_Aggro()
{
}

function Cancel_Root()
{
}

function RefreshPower()
{
	if ${Me.Power}<10 && ${Me.Inventory[${Manastone}](exists)} && ${Me.Inventory[${Manastone}].IsReady}
		Me.Inventory[${Manastone}]:Use

	if ${ShardMode}
		call Shard 10
}

function CheckHeals()
{

	if ${Me.ToActor.Pet.Health}<70 && ${Me.ToActor.Pet(exists)}
		call CastSpellRange 391

	call CommonHeals 70

}

function SummonPet()
{
;1=bear,2=feline
	PetEngage:Set[FALSE]

	if ${PetMode}
	{
		switch ${PetType}
		{
			case 1
				call CastSpellRange 330
				break

			case 2
				call CastSpellRange 331
				break

			case default
				call CastSpellRange 331
				break
		}
	}
}

function PostDeathRoutine()
{
	;; This function is called after a character has either revived or been rezzed
	return
}
