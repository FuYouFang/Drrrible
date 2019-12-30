//
//  ShotViewReactionLikeButtonViewReactor.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 12/03/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import ReactorKit
import RxSwift

// Like Button 的 Reactor
final class ShotViewReactionLikeButtonViewReactor: ShotViewReactionButtonViewReactor {
    fileprivate let shotService: ShotServiceType
    fileprivate let analytics: DrrribleAnalytics
    
    private var shot: Shot?
    init(
        shot: Shot,
        shotService: ShotServiceType,
        analytics: DrrribleAnalytics
    ) {
        self.shot = shot
        self.shotService = shotService
        self.analytics = analytics
        let initialState = State(
            shotID: shot.id,
            isReacted: shot.isLiked,
            canToggleReaction: shot.isLiked != nil,
            count: shot.likeCount
        )
        super.init(initialState: initialState)
    }
    
    #warning("""
    点击按钮并不发出任何修改 state 的事件，它只通知对应的 service，
    service 对 reacted 的状态进行修改。
    """)
    override func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .toggleReaction:
            if self.currentState.isReacted != true {
                #warning("""
                subscribe 是否是必须的？
                """)
                _ = self.shotService.like(shotID: self.shotID).subscribe()
                self.analytics.log(.likeShot(shotID: self.shotID))
            } else {
                _ = self.shotService.unlike(shotID: self.shotID).subscribe()
                self.analytics.log(.unlikeShot(shotID: self.shotID))
            }
            return .empty()
        }
    }
    
    override func mutation(from event: Shot.Event) -> Observable<Mutation> {
        switch event {
        case let .updateLiked(id, isLiked):
            guard id == self.shotID else { return .empty() }
            #warning("Observable.from 的使用")
            return Observable.from([.setReacted(isLiked), .setCanToggleReaction(true)])
            
        case let .increaseLikeCount(id):
            guard id == self.shotID else { return .empty() }
            return .just(.setCount((self.currentState.count ?? 0) + 1))
            
        case let .decreaseLikeCount(id):
            guard id == self.shotID else { return .empty() }
            return .just(.setCount((self.currentState.count ?? 0) - 1))
        }
    }
}
