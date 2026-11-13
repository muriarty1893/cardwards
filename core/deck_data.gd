class_name DeckData
extends Resource
## A pre-made deck: 4 lands in lane order and 30 cards.

@export var id: StringName = &""
@export var display_name: String = ""
@export var lands: Array[int] = []
@export var cards: Array[CardData] = []
