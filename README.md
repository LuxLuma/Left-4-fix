# Left-4-fix

#### Fixes for gamebreaking bugs and stupid stuff valve did for left 4 dead 1/2


# [Defib fix](https://forums.alliedmods.net/showthread.php?t=315483)
Fixes defib getting wrong targets and reviving alive players, this is semiport of [extension](https://github.com/Satanic-Spirit/defib-fix).
This exists because of issues with current fix with extension, https://forums.alliedmods.net/showpost.php?p=2635893&postcount=13
 ##### Extra Requirements

 - [DHooks (Experimental Dynamic Detour support)](https://forums.alliedmods.net/showthread.php?p=2588686#post2588686)

# Charger
### [Charger Collision patch](https://forums.alliedmods.net/showthread.php?t=315482)
Better Charger Collision patch.

Link below on why it's different vs extension fix.
https://forums.alliedmods.net/showpost.php?p=2649772&postcount=11

# [Witch fixes](https://forums.alliedmods.net/showthread.php?p=2647014)
General fixes for witch.
 
 ## Witch_Double_Startle_Fix
 Fixes witch when wandering playing startle twice by forcing the NextThink to end the startle.
 
 ## witch_allow_in_safezone
 Allows witches to chase victims into safezones.
 ##### Extra Requirements

 - [DHooks (Experimental Dynamic Detour support)](https://forums.alliedmods.net/showthread.php?p=2588686#post2588686)

## witch_prevent_target_loss

Prevents the witch from randomly loosing target.

## witch_target_patch

Fixes witch going after wrong clone survivor

# Hunter_pounce_alignment_fix
Fixes hunter alignment and issue with shoving a pounced survivor hunter from not being shoved off very early in pounce.
#### Extra Requirements
-   [Source Scramble (memory patching and allocation natives)](https://forums.alliedmods.net/showpost.php?s=afcc4e2813b2d4593c91fe25b8dbc3e8&p=2657347&postcount=1)

# [l4d2_changelevel](https://forums.alliedmods.net/showthread.php?p=2669850)

Creates a clean way to change maps, sm_map causes leaks and other spooky stuff causing server perf to be worse over time.
Because l4d2's vscript system is the best!


##### Left 4 Fix is a repo of stuff valve should fix for left 4 dead1/2 but have not, why this exists.