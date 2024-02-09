-- We need to use some smarter types for Fragments
-- for the time being, we should let most stuff pass
-- if you experience problems, please file a Pull request

export type Fragment<A> = {
	ID: string,
	Name: string,
	Service: any,

	Destroy: (Fragment<A>) -> (),
	Spawn: (Fragment<A>, asyncHandler: (boolean, string?) -> ()?) -> (boolean, string?),

	Destroying: (Fragment<A>) -> (),
	Init: (Fragment<A>) -> (),

	-- some parallel execution stuff
	Await: (Fragment<A>) -> (boolean, string?),
	HandleAsync: (Fragment<A>, asyncHandler: (boolean, string) -> ()?) -> (),
} & A

export type BlankFragment = Fragment<{[string]: any}>

export type Template = {
	Name: string,
	CreateFragment: <A>(Template, A) -> Fragment<A>
}

export type Service = {
	EnableTemplates: boolean,
	Name: string,

	Fragments: {[string]: BlankFragment},
	FragmentNameStore: {[string]: BlankFragment},
	GetFragmentsOfName: (Service, name: string) -> {[string]: BlankFragment},
	Spawning: (Service, BlankFragment) -> (),
	Fragment: <A>(Service, A) -> Fragment<A>,
	FragmentAdded: (Service, BlankFragment) -> (),
	FragmentRemoved: (Service, BlankFragment) -> (),
	
	Template: (Service, Template) -> Template,
	Templates: {[string]: Template},
	TemplateAdded: (Service, Template) -> (),
	CreateFragmentFromTemplate: <A>(Service, A) -> Fragment<A>
}

return nil