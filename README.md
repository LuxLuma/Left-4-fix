# Left-4-fix

#### Fixes for gamebreaking bugs and stupid stuff valve did for left 4 dead 1/2


# [Defib fix](https://forums.alliedmods.net/showthread.php?t=315483)
Fixes defib getting wrong targets and reviving alive players, this is semiport of [extension](https://github.com/Satanic-Spirit/defib-fix).
This exists because of issues with current fix with extension, https://forums.alliedmods.net/showpost.php?p=2635893&postcount=13


# Charger
### [Charger Collision patch](https://forums.alliedmods.net/showthread.php?t=315482)

##### Extra Requirements
 - [  Source Scramble (memory patching and allocation natives)](https://forums.alliedmods.net/showthread.php?p=2657347)
#### with patch preview
![](https://raw.githubusercontent.com/LuxLuma/Left-4-fix/master/left%204%20fix/charger/Charger_Collision_patch/with_patch.gif)
#### without patch preview
![](https://raw.githubusercontent.com/LuxLuma/Left-4-fix/master/left%204%20fix/charger/Charger_Collision_patch/without_patch.gif)

Link below on why it's different vs original extension fix.
https://forums.alliedmods.net/showpost.php?p=2649772&postcount=11


# [Witch fixes](https://forums.alliedmods.net/showthread.php?p=2647014)
General fixes for witch.
 
 ## Witch_Double_Startle_Fix
 Fixes witch when wandering playing startle twice by forcing the NextThink to end the startle.
 
 ## witch_allow_in_safezone
 Allows witches to chase victims into safezones.

## witch_prevent_target_loss

Prevents the witch from randomly loosing target.

## witch_target_patch

Fixes witch going after wrong clone survivor


# [Hunter_pounce_alignment_fix](https://forums.alliedmods.net/showthread.php?p=2711955#)
Fixes hunter alignment and issue with shoving a pounced survivor hunter from not being shoved off very early in pounce.


# [l4d2_changelevel](https://forums.alliedmods.net/showthread.php?p=2669850)

Creates a clean way to change maps, sm_map causes leaks and other spooky stuff causing server perf to be worse over time.
Because l4d2's vscript system is the best!


 # [physics_object_pushfix](https://forums.alliedmods.net/showthread.php?p=2705656#post2705656)

alternative to https://forums.alliedmods.net/showthread.php?p=1706053 that does not modify collision rules.


 # [survivor_afk_fix](https://forums.alliedmods.net/showthread.php?p=2714236)

This afk fix includes no commands since it fixes the game function.


# [stop_air_revive](https://forums.alliedmods.net/showthread.php?t=341999)

Block allowing to survivor to revive to while not on floor prevent fall damage exploit fix.


# [witch_pipebomb_exploit_fix_&_death_optmizer](https://forums.alliedmods.net/showthread.php?t=342000)


Fixes exploit throwing pipebomb at witch with horde because z_fatal_blast_max_ragdolls & z_fatal_blast_min_ragdolls function casts for Infected class which the witch shares and can outright delete her if her index is high enough to trigger valve's death optmizer after quite a few zombie deaths,
also optimize's infected deaths to not send info to players out of PVS which can be 1000s of units away behind buildings pretty pointless.

##### Left 4 Fix is a repo of stuff valve should fix for left 4 dead1/2 but have not, why this exists.