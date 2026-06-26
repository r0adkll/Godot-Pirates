extends Node
## A Global Singleton for common time/perf utils

var logging_enabled: bool = true

## Get a mark in time, in microseconds
func mark() -> int:
	return Time.get_ticks_usec()

## Print the elapsed time since a 'mark' in a human-readable format 
## with a provided label
func print_time(start: int, label: String, in_millis: bool = false) -> void:
	if !logging_enabled: return
	
	var elapsed = Time.get_ticks_usec() - start
	var time_suffix = "µs"
	if in_millis:
		elapsed = elapsed / 1000.0
		time_suffix = "ms"
	print("{0} [{1} {2}]".format([label, elapsed, time_suffix]))

## Lambda wrapper for measuring function calls
func measure(label: String, block: Callable) -> Variant:
	var start = mark()
	var result = block.call()
	print_time(start, label)
	return result
