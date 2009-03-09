/************************************************
**Created by HotShot**
*Verison 1.03*
*Date: 03/08/09
 
 
**Commands**
run SpellExport		**Exports ALL spells, including Tradeskills/Abilities/Spells/Combat Arts
	Args:	HELP	**Displays these options
		NT	**No Tradeskill abilities
		TO	**Tradeskill abilities only
		Settings**Exports using Settings instead of Attributes **DO NOT USE**
 
Verison 1.02 updates:
Changed int to int64
Changed from GetAbilities (used int) to NumAbilities
Added repeat for NULL abilities
**/
 
function main(string Args)
{
	if ${Args.Find[help]}
	{
		echo **Commands**
		echo run SpellExport		**Exports ALL spells, including Tradeskills/Abilities/Spells/Combat Arts
		echo	Args:	NT	**No Tradeskill abilities
		echo		TO	**Tradeskill abilities only
		echo		Settings**Exports using Settings instead of Attributes **DO NOT USE**
		return
	}
 
	variable string ConfigFile="${Script.CurrentDirectory}/${Me.SubClass}_SpellExport.xml"
 
	;Clear then Load LavishSettings to make sure it's clean.
	LavishSettings[SpellInformation]:Clear
	LavishSettings:AddSet[SpellInformation]
	LavishSettings[SpellInformation]:AddSet[${Me.SubClass}]
	variable settingsetref setSpell
	setSpell:Set[${LavishSettings[SpellInformation].FindSet[${Me.SubClass}]}]
 
	;variable index:ability SpellStorage
	echo Counting Spells in spell book... ${Me.NumAbilities}
 
	variable int SpellCounter=0
	variable int64 CurrentSpellID
	variable string CurrentSpellName
	variable int NULLsSkipped=0
	variable string WhatToReturn
	variable int aa
	variable int64 LastSpellID=0
 
	while ${SpellCounter:Inc}<=${Me.NumAbilities}
	{
		CurrentSpellID:Set[${Me.Ability[${SpellCounter}].ID}]
		LastSpellID:Set[${CurrentSpellID}]
 
		;Avoid spamming the server... Only 1 spell per second
		wait 10
 
		CurrentSpellName:Set[${Me.Ability[id,${CurrentSpellID}].Name}]
 
		if ${Args.Find[NT]} && ${Me.Ability[id,${CurrentSpellID}].SpellBookType}==3
		{
			echo Skipping Tradeskill ability: ${CurrentSpellName} - ID: ${CurrentSpellID}
			continue
		}
 
		if ${Args.Find[TO]} && ${Me.Ability[id,${CurrentSpellID}].SpellBookType}!=3
		{
			echo Skipping non-Tradeskill ability: ${CurrentSpellName} - ID: ${CurrentSpellID}
			continue
		}
 
		if ${CurrentSpellName.Equal[NULL]} || !${Me.Ability[id,${CurrentSpellID}](exists)}
		{
			NULLsSkipped:Inc
			echo Repeating NULL Ability: #${SpellCounter}/${Me.NumAbilities}... Coming up as:${CurrentSpellName} - ID: ${CurrentSpellID}
			SpellCounter:Dec
			continue
		}
		echo Adding Ability#: ${SpellCounter}/${Me.NumAbilities}... ${CurrentSpellName} - ID: ${CurrentSpellID}
 
		if !${Args.Find[Settings]}
		{
			setSpell:AddSetting[${CurrentSpellName},${CurrentSpellName}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[ID,${CurrentSpellID}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[Description,${Me.Ability[id,${CurrentSpellID}].Description}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[HealthCost,${Me.Ability[id,${CurrentSpellID}].HealthCost}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[PowerCost,${Me.Ability[id,${CurrentSpellID}].PowerCost}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[ConcentrationCost,${Me.Ability[id,${CurrentSpellID}].ConcentrationCost}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[MainIconID,${Me.Ability[id,${CurrentSpellID}].MainIconID}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[CastingTime,${Me.Ability[id,${CurrentSpellID}].CastingTime}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[RecoveryTime,${Me.Ability[id,${CurrentSpellID}].RecoveryTime}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[RecastTime,${Me.Ability[id,${CurrentSpellID}].RecastTime}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[MaxDuration,${Me.Ability[id,${CurrentSpellID}].MaxDuration}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[NumClasses,${Me.Ability[id,${CurrentSpellID}].NumClasses}]
 
			aa:Set[0]
			WhatToReturn:Set[]
			while ${aa:Inc}<=${Me.Ability[id,${CurrentSpellID}].NumEffects}
			{
				;Adding each Description line
				setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[EffectDesc${aa},${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc}]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[Flanking or behind](exists)}
					WhatToReturn:Set[${WhatToReturn}FLANKING*]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[you must be sneaking](exists)} || ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[you must be in stealth](exists)} || ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[you must be stealthed to use this](exists)}
					WhatToReturn:Set[${WhatToReturn}SNEAKING*]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[must be behind](exists)}
					WhatToReturn:Set[${WhatToReturn}BEHIND*]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[does not affect epic](exists)}
					WhatToReturn:Set[${WhatToReturn}NOEPIC*]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[if weapon equipped in ranged](exists)}
					WhatToReturn:Set[${WhatToReturn}RANGED*]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[if shield equipped in secondary](exists)}
					WhatToReturn:Set[${WhatToReturn}SHIELD*]
			}
			;Adding a new line which can be read by scripts instead of cycling the descriptions. If it doesn't exist, it means there are none of the restrictions from above
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[DescRestrictions,${WhatToReturn}]
 
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[Class,${Me.Ability[id,${CurrentSpellID}].Class}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[NumEffects,${Me.Ability[id,${CurrentSpellID}].NumEffects}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[BackDropIconID,${Me.Ability[id,${CurrentSpellID}].BackDropIconID}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[HealthCostPerTick,${Me.Ability[id,${CurrentSpellID}].HealthCostPerTick}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[PowerCostPerTick,${Me.Ability[id,${CurrentSpellID}].PowerCostPerTick}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[MaxAOETargets,${Me.Ability[id,${CurrentSpellID}].MaxAOETargets}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[DoesNotExpire,${Me.Ability[id,${CurrentSpellID}].DoesNotExpire}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[GroupRestricted,${Me.Ability[id,${CurrentSpellID}].GroupRestricted}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[AllowRaid,${Me.Ability[id,${CurrentSpellID}].AllowRaid}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[EffectRadius,${Me.Ability[id,${CurrentSpellID}].EffectRadius}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[TargetType,${Me.Ability[id,${CurrentSpellID}].TargetType}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[SpellBookType,${Me.Ability[id,${CurrentSpellID}].SpellBookType}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[MinRange,${Me.Ability[id,${CurrentSpellID}].MinRange}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[MaxRange,${Me.Ability[id,${CurrentSpellID}].MaxRange}]
			setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[Range,${Me.Ability[id,${CurrentSpellID}].Range}]
			;setSpell.FindSetting[${CurrentSpellName}]:AddAttribute[]
 
		}
		elseif ${Args.Find[Settings]}
		{
			setSpell:AddSet[${CurrentSpellName}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[ID,${CurrentSpellID}]
			;setSpell.FindSet[${CurrentSpellName}]:SetAttribute[1,abc]
			;setSpell:SetAttribute[2,def]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[Description,${Me.Ability[id,${CurrentSpellID}].Description}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[Tier,${Me.Ability[id,${CurrentSpellID}].Tier}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[HealthCost,${Me.Ability[id,${CurrentSpellID}].HealthCost}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[PowerCost,${Me.Ability[id,${CurrentSpellID}].PowerCost}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[ConcentrationCost,${Me.Ability[id,${CurrentSpellID}].ConcentrationCost}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[MainIconID,${Me.Ability[id,${CurrentSpellID}].MainIconID}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[CastingTime,${Me.Ability[id,${CurrentSpellID}].CastingTime}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[RecoveryTime,${Me.Ability[id,${CurrentSpellID}].RecoveryTime}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[RecastTime,${Me.Ability[id,${CurrentSpellID}].RecastTime}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[MaxDuration,${Me.Ability[id,${CurrentSpellID}].MaxDuration}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[NumClasses,${Me.Ability[id,${CurrentSpellID}].NumClasses}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[Class,${Me.Ability[id,${CurrentSpellID}].Class}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[NumEffects,${Me.Ability[id,${CurrentSpellID}].NumEffects}]
			WhatToReturn:Set[]
			aa:Set[0]
			while ${aa:Inc}<=${Me.Ability[id,${CurrentSpellID}].NumEffects}
			{
				;Adding each Description line
				setSpell.FindSet[${CurrentSpellName}]:AddSetting[EffectDesc${aa},${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc}]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[Flanking or behind](exists)}
					WhatToReturn:Set[${WhatToReturn}FLANKING*]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[you must be sneaking](exists)} || ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[you must be in stealth](exists)} || ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[you must be stealthed to use this](exists)}
					WhatToReturn:Set[${WhatToReturn}SNEAKING*]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[must be behind](exists)}
					WhatToReturn:Set[${WhatToReturn}BEHIND*]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[does not affect epic](exists)}
					WhatToReturn:Set[${WhatToReturn}NOEPIC*]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[if weapon equipped in ranged](exists)}
					WhatToReturn:Set[${WhatToReturn}RANGED*]
				if ${Me.Ability[id,${CurrentSpellID}].Effect[${aa}].Desc.Find[if shield equipped in secondary](exists)}
					WhatToReturn:Set[${WhatToReturn}SHIELD*]
			}
			;Adding a new line which can be read by scripts instead of cycling the descriptions. If it doesn't exist, it means there are none of the restrictions from above
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[DescRestrictions,${WhatToReturn}]
 
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[BackDropIconID,${Me.Ability[id,${CurrentSpellID}].BackDropIconID}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[HealthCostPerTick,${Me.Ability[id,${CurrentSpellID}].HealthCostPerTick}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[PowerCostPerTick,${Me.Ability[id,${CurrentSpellID}].PowerCostPerTick}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[MaxAOETargets,${Me.Ability[id,${CurrentSpellID}].MaxAOETargets}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[DoesNotExpire,${Me.Ability[id,${CurrentSpellID}].DoesNotExpire}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[GroupRestricted,${Me.Ability[id,${CurrentSpellID}].GroupRestricted}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[AllowRaid,${Me.Ability[id,${CurrentSpellID}].AllowRaid}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[EffectRadius,${Me.Ability[id,${CurrentSpellID}].EffectRadius}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[TargetType,${Me.Ability[id,${CurrentSpellID}].TargetType}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[SpellBookType,${Me.Ability[id,${CurrentSpellID}].SpellBookType}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[MinRange,${Me.Ability[id,${CurrentSpellID}].MinRange}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[MaxRange,${Me.Ability[id,${CurrentSpellID}].MaxRange}]
			setSpell.FindSet[${CurrentSpellName}]:AddSetting[Range,${Me.Ability[id,${CurrentSpellID}].Range}]
			;setSpell.FindSet[${CurrentSpellName}]:AddSetting[,${Me.Ability[id,${CurrentSpellID}].}]
		}
	}
	if ${NULLsSkipped}==${Me.NumAbilities}
	{
		echo All abilities came up as NULL. Re-run script
		return
	}
	if ${NULLsSkipped}>0
		echo Skipped ${NULLsSkipped} NULLs. Open your spell book and go through it one page at a time then re-run script.
	LavishSettings[SpellInformation]:Export["${ConfigFile}"]
	LavishSettings[SpellInformation]:Clear
	echo Save completed to file: ${ConfigFile}	
}