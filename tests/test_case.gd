class_name TestCase
extends RefCounted
## Base class for test files. Each test is a method named test_* that returns true on its last line.

var passed: int = 0
var failed: int = 0
var current: String = ""


func assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if typeof(actual) == typeof(expected) and actual == expected:
		passed += 1
	elif (typeof(actual) in [TYPE_INT, TYPE_FLOAT]) and (typeof(expected) in [TYPE_INT, TYPE_FLOAT]) and actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s / %s: expected %s, got %s" % [current, label, str(expected), str(actual)])


func assert_true(cond: bool, label: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s / %s: expected true" % [current, label])
