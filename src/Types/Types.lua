-- We need to use some smarter types for Fragments
-- for the time being, we should let most stuff pass
-- if you experience problems, please file a Pull request

export type Fragment<A> = {
	GetID: (Fragment<A>, full: boolean?) -> string,
	GetName: (Fragment<A>) -> string,

	Destroy: (Fragment<A>) -> (),
	Spawn: (
		Fragment<A>,
		xpcallHandler: ((string?) -> string)?,
		asyncHandler: (boolean, string?) -> ()?
	) -> (boolean, string?),
	
	Update: (Fragment<A>, dt: number) -> ()?,
	Destroying: (Fragment<A>) -> (),
	Init: (Fragment<A>) -> (),

	-- some parallel execution stuff
	Await: (Fragment<A>) -> (boolean, string?),
	HandleAsync: (Fragment<A>, asyncHandler: (boolean, string) -> ()?) -> (),
} & A

export type BlankFragment = Fragment<{[string]: any}>

export type Template = {
	Name: string,
	CreateFragment: <A>(A) -> Fragment<A>,
}

export type Service = {
	EnableTemplates: boolean,
	Name: string,

	Fragment: <A>(Service, A) -> Fragment<A>,
	
	Template: (Service, name: string, createFragment: <A>(A) -> A) -> Template,
	CreateFragmentFromTemplate: <A>(Service, A) -> Fragment<A>,

	Spawning: (Service, BlankFragment) -> (),
	Updating: (Service, BlankFragment, dt: number) -> (),
	CreateFragment: <A>(Service, A) -> (),
	FragmentAdded: (Service, BlankFragment) -> (),
	FragmentRemoved: (Service, BlankFragment) -> (),
	TemplateAdded: (Service, Template) -> ()
}

export type ServiceCtorParams = {
	Name: string,

	EnableTemplates: boolean?,

	Spawning: (Service, BlankFragment) -> ()?,
	Updating: (Service, BlankFragment, dt: number) -> ()?,
	CreateFragment: (<A>(Service, A) -> Fragment<A>)?,
	FragmentAdded: (Service, BlankFragment) -> ()?,
	FragmentRemoved: (Service, BlankFragment) -> ()?,
	TemplateAdded: (Service, Template) -> ()?,

	[string]: any
}

return nil