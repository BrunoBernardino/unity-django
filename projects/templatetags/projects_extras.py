from django import template

register = template.Library()

@register.filter
def truncatechars_start( value, arg ):
	"""Truncates a string, but in the start"""

	try:
		length = int(arg)
		string = str(value)
	except ValueError:
		return value

	if length > 0:
		length *= -1

	if len(string) > abs(length):
		return '...' + string[length:]
	else:
		return string[length:]