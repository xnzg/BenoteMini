import ComposableArchitecture

@usableFromInline
struct _OnChangeOf<Value: Equatable, Child: ReducerProtocol>: ReducerProtocol {
    @usableFromInline
    typealias State = Child.State
    @usableFromInline
    typealias Action = Child.Action

    @usableFromInline
    let child: Child
    @usableFromInline
    let getValue: (State) -> Value
    @usableFromInline
    let onChange: (Value, Value) -> Effect<Action, Never>

    @inlinable
    init(
        child: Child,
        getValue: @escaping (State) -> Value,
        onChange: @escaping (Value, Value) -> Effect<Action, Never>
    ) {
        self.child = child
        self.getValue = getValue
        self.onChange = onChange
    }

    @inlinable
    func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
        let oldValue = getValue(state)
        let effect = child.reduce(into: &state, action: action)
        let newValue = getValue(state)
        guard oldValue != newValue else { return effect }
        return onChange(oldValue, newValue).merge(with: effect)
    }
}

extension ReducerProtocol {
    @inlinable
    public func onChange<Value: Equatable>(
        of getValue: @escaping @Sendable (State) -> Value,
        perform action: @escaping @Sendable (Value, Value) -> Effect<Action, Never>
    ) -> some ReducerProtocol<State, Action>
    {
        _OnChangeOf(child: self, getValue: getValue, onChange: action)
    }
}

extension ReducerProtocol where State: Equatable {
    @inlinable
    public func onChange(
        perform action: @escaping @Sendable (State, State) -> Effect<Action, Never>
    ) -> some ReducerProtocol<State, Action>
    {
        onChange(of: { x in x }, perform: action)
    }
}
