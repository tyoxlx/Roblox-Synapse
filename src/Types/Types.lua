-- We need to use some smarter types for Objects
-- for the time being, we should let most stuff pass
-- if you experience problems, please file a Pull request

export type Object<A> = {
	Name: string,
	GetID: (Object<A>, full: boolean?) -> string,

	Destroy: (Object<A>) -> (),
	Spawn: (
		Object<A>,
		xpcallHandler: ((string?) -> string)?,
		asyncHandler: (boolean, string?) -> ()?
	) -> (boolean, string?),
	
	Update: (Object<A>, dt: number) -> ()?,
	Destroying: (Object<A>) -> (),
	Init: (Object<A>) -> (),

	-- some parallel execution stuff
	Await: (Object<A>) -> (boolean, string?),
	HandleAsync: (Object<A>, asyncHandler: (boolean, string) -> ()?) -> (),
} & A

export type BlankObject = Object<{[string]: any}>

export type Class = {
	Name: string,
	Service: Service,
	CreateObject: <A>(A) -> Object<A>,
}

export type Service = {
	Name: string,
	Object: <A>(Service, A) -> Object<A>,
	
	Class: (Service, name: string, createObject: (BlankObject) -> ()) -> Class,
	CreateObjectFromClass: (Service, Class, initParams: {[string]: any}?) -> BlankObject,

	Spawning: (Service, BlankObject) -> (),
	Updating: (Service, BlankObject, dt: number) -> (),
	CreateObject: <A>(Service, A) -> (),
	ObjectAdded: (Service, BlankObject) -> (),
	ObjectRemoved: (Service, BlankObject) -> (),
	ClassAdded: (Service, Class) -> ()
}

export type ServiceCtorParams = {
	Name: string,

	EnableUpdating: boolean?,
	EnableClasses: boolean?,

	Spawning: (Service, BlankObject) -> ()?,
	Updating: (Service, BlankObject, dt: number) -> ()?,
	CreateObject: (<A>(Service, A) -> Object<A>)?,
	ObjectAdded: (Service, BlankObject) -> ()?,
	ObjectRemoved: (Service, BlankObject) -> ()?,
	ClassAdded: (Service, Class) -> ()?,

	[string]: any
}

return nil