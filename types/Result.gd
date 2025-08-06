## A result type which can have an integer error code or a Variant return type.
class_name Result

var _return_value: Variant
var _error: int

## Creates a successful Result with the return value provided.
static func ok(return_value: Variant) -> Result:
	var result := Result.new()
	result._return_value = return_value
	return result

## Creates an unsuccessful Result with the error code provided. It is recommended to use an Enum for error codes.
static func err(error: int) -> Result:
	var result := Result.new()
	result._error = error
	return result

## Returns if the Result was unsuccessful.
func is_err() -> bool:
	return _error != null

## Returns if the Result was successful.
func is_ok() -> bool:
	return _return_value != null

## The value of the Result, if there is one.
func val() -> Variant:
	if is_ok():
		return _return_value
	return null

## The error code of the Result, if there is one.
func err_code() -> Variant:
	if is_err():
		return _error
	return null
