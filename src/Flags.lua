--[=[
	@class Flags

	Flags are used to control how Catwork behaves internally, they're intended
	for narrowing down particularly nasty bugs that Catwork may create in other
	parts of code. When releasing, all flags should be disabled, as some flags
	may intentionally break parts of Catwork to help you find bugs.
]=]
local Flags = {}

--[=[
	@prop DONT_ASSIGN_OBJECT_MT boolean
	@within Flags

	This flag states if Catwork should wrap its objects inside a `__tostring`
	metamethod, which is done to make prints in the output cleaner. (instead
	of showing `table 0x123456789`, it shows, for example,
	`CatworkService<catwork>`)

	This flag can be enabled if, for example, you're trying to debug the shape
	of a Fragment created by a Template or Service, since Roblox will disable
	its table pretty-printing on tables with a `__tostring` metamethod
]=]--
Flags.DONT_ASSIGN_OBJECT_MT = false

return Flags