//
//  ShotViewReactor.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 12/03/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import ReactorKit
import RxCocoa
import RxSwift

#warning("""
ShotViewReactor 的 state 有 shotSectionReactor 的属性


ShotViewReactor 中 state 的 sections 中
由 ShotSectionReactor 提供：
1. ShotViewImageCellReactor
2. ShotViewTitleCellReactor
3. ShotViewTextCellReactor
4. ShotViewReactionCellReactor
本身还会负责创建
1. ShotViewCommentCellReactor
        

""")
final class ShotViewReactor: Reactor {
    enum Action {
        case refresh
    }
    
    enum Mutation {
        case setRefreshing(Bool)
        case setShot(Shot)
        case setComments([Comment])
    }
    
    struct State {
        let shotID: Int
        var isRefreshing: Bool = false
        var shotSectionReactor: ShotSectionReactor
        var commentSectionItems: [ShotViewSectionItem] = [.activityIndicator]
        
        // 将 .shot 和 .comment 类型的 cell 进行了合并
        var sections: [ShotViewSection] {
            let sections: [ShotViewSection] = [
                .shot(shotSectionReactor.currentState.sectionItems.map(ShotViewSectionItem.shot)),
                .comment(self.commentSectionItems),
            ]
            return sections.filter { !$0.items.isEmpty }
        }
        
        init(shotID: Int, shotSectionReactor: ShotSectionReactor) {
            self.shotID = shotID
            self.shotSectionReactor = shotSectionReactor
        }
    }
    
    let initialState: State
    fileprivate var shotID: Int {
        return self.currentState.shotID
    }
    
    fileprivate let shotService: ShotServiceType
    
    init(
        shotID: Int,
        shot initialShot: Shot? = nil,
        shotService: ShotServiceType,
        shotSectionReactorFactory: (Int, Shot?) -> ShotSectionReactor
    ) {
        self.initialState = State(
            shotID: shotID,
            shotSectionReactor: shotSectionReactorFactory(shotID, initialShot)
        )
        self.shotService = shotService
        _ = self.state
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .refresh:
            guard !self.currentState.isRefreshing else { return .empty() }
            return Observable.concat([
                Observable.just(.setRefreshing(true)),
                self.shotService.shot(id: self.shotID).asObservable().map(Mutation.setShot),
                Observable.just(.setRefreshing(false)),
                Observable.concat([
                    self.shotService.isLiked(shotID: self.shotID).asObservable().flatMap { _ in Observable.empty() },
                    self.shotService.comments(shotID: self.shotID).asObservable().map { Mutation.setComments($0.items) },
                ]),
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .setRefreshing(isRefreshing):
            state.isRefreshing = isRefreshing
            return state
            
        case let .setShot(shot):
            state.shotSectionReactor.action.onNext(.updateShot(shot))
            return state
            
        case let .setComments(comments):
            state.commentSectionItems = comments
                .map(ShotViewCommentCellReactor.init)
                .map(ShotViewSectionItem.comment)
            return state
        }
    }
    
    func transform(state: Observable<State>) -> Observable<State> {
        return state.with(section: \.shotSectionReactor)
    }
}
