# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

# manages ALL THE ENTITIES. This includes the Player, NPCs, Verlet ropes, whatever. It doesn't include minor 
# stuff like grass or particles or whatever. NOTHING ELSE manages the spawning/despawning or creation/deletion
# of NPCs. However, other code functions might call certain functions in entity_manager.gd, but
# entity_manager must maintain a complete overview of the state.

extends Node

# Upon start, it should load all suspended entities load the Player (if he doesn't exist). This is done by spawning a entity.tscn. 
# Entity.tscn is always provided this information:
#  - Name # The name of the entity. Unique.
#  - data_index # entity.tscn is a plain node. It loads itself from a preset (ie., player, rope, ...). Each such preset has an ID.
#  - init_info # .tres, various weird structures depending on preset entity is expected to load, could include health or color or anything else specific for a certain type of entity.
#  - spawn_position # Where the entity is spawned.

# The prior spawning is done via a helper function spawn_entity(name, dataindex, ...)
# Additionally, entity.tscn can say that 'it wants to be suspended until it enters the player's visibility range, or until a timeout is reached.
# When this happens, entity_manager must pack the entire entity.tscn and all its children. It remembers its Name.
# If time is exceeded, it deletes the node entirely with all its history. If it reaches the player's
# visibility range (some constant) it will be unsuspended and let again into the scene tree.

# Importantly, player is just another entity. Do *not* include checks that assume stuff, like, if there's a player
# already in existence, don't spawn another one. There can be multiple players, and many other weird things.

# To Codex: Inspire yourself by island_manager.gd. It is a way bigger script that this one is going to be, but it should have a simmilliar structure to this one approximately.

# Do not consider anything else. Only do this script and entity.tscn. Do NOT modify anything else or do anything other than what is specified here. That'll be done later.
# If it seems that this script is missing something, please ask for clarification so in the terminal and await further instructions. There should be no ambiguity.
