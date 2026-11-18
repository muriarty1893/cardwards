class_name EffectData
extends Resource
## One step of a card's ability (spec 5.1): when it runs, what it does, how much, and to whom.

## on_play, on_boop, on_destroyed, after_damage, start_of_turn, end_of_turn, aura, on_level_up;
## field spells: field_aura, field_start, field_end
@export var when: StringName = &""
@export var op: StringName = &""
@export var amount: int = 0
## Second number (HP for buff).
@export var amount2: int = 0
@export var who: StringName = &"own_hero"
## For give_keyword and lane_keyword.
@export var keyword: StringName = &""
## Dream Up filters: CardData.Kind / CardData.Land, or -1 for any.
@export var filter_kind: int = -1
@export var filter_land: int = -1
## Runs only if its owner already played another card this turn.
@export var combo: bool = false
## Runs only if its owner controls at least `need` other creatures of `tribe`.
@export var tribe: StringName = &""
@export var need: int = 0
