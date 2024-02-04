-- We need to use some smarter types for Fragments
-- for the time being, we should let most stuff pass
-- if you experience problems, please file a Pull request

export type ServiceUnion = Service|TemplateService

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
	EnableTemplates: false,
	Name: string,

	Fragments: {[string]: BlankFragment},
	FragmentNameStore: {[string]: {[string]: BlankFragment}},

	Fragment: <A>(Service, A) -> Fragment<A>,
	GetFragmentsOfName: (Service, name: string) -> {[string]: BlankFragment},

	FragmentAdded: (Service, BlankFragment) -> (),
	FragmentRemoved: (Service, BlankFragment) -> (),
	Spawning: (Service, BlankFragment) -> (),
}

export type TemplateService = {
	EnableTemplates: true,

	Fragments: {[string]: BlankFragment},
	FragmentNameStore: {[string]: BlankFragment},
	GetFragmentsOfName: (TemplateService, name: string) -> {[string]: BlankFragment},
	Spawning: (TemplateService, BlankFragment) -> (),
	Fragment: <A>(TemplateService, A) -> Fragment<A>,
	FragmentAdded: (TemplateService, BlankFragment) -> (),
	FragmentRemoved: (TemplateService, BlankFragment) -> (),
	
	Template: (TemplateService, Template) -> Template,
	Templates: {[string]: Template},
	TemplateAdded: (TemplateService, Template) -> (),
	CreateFragmentFromTemplate: <A>(TemplateService, A) -> Fragment<A>
}

return nil