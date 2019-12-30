//
//  ShotViewReactionButtonViewReactor.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 12/03/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import ReactorKit
import RxSwift

class ShotViewReactionButtonViewReactor: Reactor {
    enum Action {
        case toggleReaction // 触发反应
    }
    
    enum Mutation {
        case setReacted(Bool) // 设置反应
        case setCanToggleReaction(Bool)
        case setCount(Int)
    }
    
    struct State {
        let shotID: Int
        var isReacted: Bool?
        var canToggleReaction: Bool
        var count: Int?
    }
    
    let initialState: State
    var shotID: Int {
        return self.currentState.shotID
    }
    
    init(initialState: State) {
        self.initialState = initialState
        _ = self.state
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        return .empty()
    }
    
    #warning("""
    现在是合并 Mutation
    能够合并 Action 呢？
    
    如果合并 Action，Shot.event 发出 increaseLikeCount 需要转化到此 Reactor 的 Action 上
    也就是说，此 Reactor 的 Action 上应该有一个 increaseLikeCount 的事件，
    但是此 Reactor 上不应该发出 increaseLikeCount 的事件。
    increaseLikeCount 事件应该由 Shot.event 控制，此 Reactor 只应该负责触发事件。
    所以只能在 Mutation 上进行合并。
    
    """)
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let fromShotEvent = Shot.event.flatMap { [weak self] event in
            self?.mutation(from: event) ?? .empty()
        }
        return Observable.of(mutation, fromShotEvent).merge()
    }
    
    func mutation(from event: Shot.Event) -> Observable<Mutation> {
        return .empty()
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .setReacted(isReacted):
            state.isReacted = isReacted
            return state
            
        case let .setCanToggleReaction(canToggleReaction):
            state.canToggleReaction = canToggleReaction
            return state
            
        case let .setCount(count):
            state.count = count
            return state
        }
    }
}
