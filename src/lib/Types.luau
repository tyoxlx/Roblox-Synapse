-- We need to use some smarter types for Objects
-- for the time being, we should let most stuff pass
-- if you experience problems, please file a Pull request

export type MetakeyWellKnown = "AwaitFor" | "EnableClasses" | "EnableUpdating" | "PluginMetadata" | "TimeoutDisabled"

export type Metakey<A> = typeof(setmetatable(
	{} :: {
		Key: A,
	},
	{} :: {
		__tostring: (Metakey<A>) -> string,
	}
))

type ObjectState = "dead" | "pending" | "spawned"
export type Object<A> = {
	Name: string,
	GetID: (Object<A>, full: boolean?) -> string,
	GetState: (Object<A>) -> ObjectState,

	Destroy: (Object<A>) -> (),
	Update: (Object<A>, dt: number) -> number?,
	Destroying: (Object<A>) -> (),
	Init: (Object<A>) -> (),

	-- some parallel execution stuff
	Await: (Object<A>) -> (boolean, string?),
	HandleAsync: (Object<A>, asyncHandler: (boolean, string) -> ()?) -> (),
} & A

export type BlankObject = Object<{ [string]: any }>

export type Class<A> = {
	Name: string,
	Service: any,
	CreateObject: (Object<A>) -> Object<A>,
}

export type Service = {
	Name: string,
	Object: <A>(Service, A) -> Object<A>,

	Class: <A>(Service, name: string, createObject: (Object<A>) -> ()) -> Class<A>,
	CreateObjectFromClass: <A, B>(Service, Class<A>, initParams: B?) -> Object<A & B>,

	SpawnObject: (
		Service,
		BlankObject,
		xpcallHandler: ((string?) -> string)?,
		asyncHandler: (boolean, string?) -> ()?
	) -> (boolean, string?),

	StartService: (Service) -> (),
	Spawning: (Service, BlankObject) -> (),
	Updating: (Service, BlankObject, dt: number) -> number?,
	CreateObject: <A>(Service, A) -> (),
	ObjectAdded: (Service, BlankObject) -> (),
	ObjectRemoved: (Service, BlankObject) -> (),
	ClassAdded: <A>(Service, Class<A>) -> (),
}

export type ServiceCtorParams = {
	Name: string,

	StartService: (Service) -> ()?,
	Spawning: (Service, BlankObject) -> ()?,
	Updating: ((Service, BlankObject, dt: number) -> number?)?,
	CreateObject: (<A>(Service, A) -> Object<A>)?,
	ObjectAdded: (Service, BlankObject) -> ()?,
	ObjectRemoved: (Service, BlankObject) -> ()?,
	ClassAdded: <A>(Service, Class<A>) -> ()?,

	[string | Metakey<any>]: any,
}

return nil
