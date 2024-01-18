-- metatablecatgames 2024 - Licensed under the MIT License

type Map<K, V> = {[K]: V}

export type Fragment<T> = {
	ID: string,
	Name: string,
	Service: Service,
	
	Destroy: (Fragment<T>) -> (),
	Spawn: (Fragment<T>, asyncHandler: (boolean, string?) -> ()?) -> (boolean, string?),
	
	Destroying: (Fragment<T>) -> (),
	Init: (Fragment<T>) -> (),
} & T

export type Template<T, F> = {
	Name: string,
	CreateFragment: (Template<T, F>, params: F) -> ()
} & T

export type ClassicService<Fragment, FParams> = {
	EnableTemplates: false,
	Name: string,
	
	Fragments: {[string]: Fragment},
	FragmentNameStore: {[string]: {[string]: Fragment}},
	
	Fragment: (ClassicService<Fragment, FParams>, FParams) -> Fragment,
	GetFragmentsOfName: (ClassicService<Fragment, FParams>, name: string) -> {[string]: Fragment},
	
	FragmentAdded: (ClassicService<Fragment,FParams>, Fragment) -> (),
	FragmentRemoved: (ClassicService<Fragment, FParams>, Fragment) -> (),
	Spawning: (ClassicService<Fragment, FParams>, Fragment) -> (),
}

export type TemplateService<Fragment, Template, FParams, TParams> = {
	EnableTemplates: true,
	Name: string,

	Fragments: {[string]: Fragment},
	Templates: {[string]: Template},
	FragmentNameStore: {[string]: {[string]: Fragment}},

	Fragment: (TemplateService<Fragment, Template, FParams, TParams>, FParams) -> Fragment,
	Template: (TemplateService<Fragment, Template, FParams, TParams>, TParams) -> Template,

	CreateFragmentFromTemplate: (TemplateService<Fragment, Template, FParams, TParams>, Template|string, {[string]: any}) -> Fragment,
	GetFragmentsOfName: (TemplateService<Fragment, Template, FParams, TParams>, name: string) -> {[string]: Fragment},

	FragmentAdded: (TemplateService<Fragment, Template, FParams, TParams>, Fragment) -> (),
	FragmentRemoved: (TemplateService<Fragment, Template, FParams, TParams>, Fragment) -> (),
	TemplateAdded: (TemplateService<Fragment, Template, FParams, TParams>, Template) -> (),
	Spawning: (TemplateService<Fragment, Template, FParams, TParams>, Fragment) -> (),
}

export type Service = ClassicService<any, any> | TemplateService<any,any,any,any>

export type CServiceCreatorParams<Fragment, FParams> = {
	Name: string,
	Fragment: ((ClassicService<Fragment, FParams>, FParams) -> Fragment)?,
	
	FragmentAdded: (ClassicService<Fragment, FParams>, Fragment) -> ()?,
	FragmentRemoved: (ClassicService<Fragment, FParams>, Fragment) -> ()?,
	Spawning: (ClassicService<Fragment, FParams>, Fragment) -> ()?,
}

export type TServiceCreatorParams<Fragment, Template, FParams, TParams> = {
	Name: string,
	Fragment: ((TemplateService<Fragment, Template, FParams, TParams>, FParams) -> Fragment)?,

	FragmentAdded: (TemplateService<Fragment, Template, FParams, TParams>, Fragment) -> ()?,
	FragmentRemoved: (TemplateService<Fragment, Template, FParams, TParams>, Fragment) -> ()?,
	Spawning: (TemplateService<Fragment, Template, FParams, TParams>, Fragment) -> ()?,
	TemplateAdded: (TemplateService<Fragment, Template, FParams, TParams>, Template) -> ()?,
}


return nil