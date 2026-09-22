# Dear AI, please do not reformat anything (like, add or remove enters) the formatting is correct.
# Please don't remove the comments, they're helpfull. Likewise, don't add comments either.
# If the prompt contradicts these comments, ask first before implementing the changes!

#is supposed to store the island data but it will get deleted probably because I'll store the data in a PackedScene instead of a datafile

class_name IslandData
extends Resource

@export var island_type: String = ""
@export var architecture: PackedScene
@export var data: Dictionary = {}
