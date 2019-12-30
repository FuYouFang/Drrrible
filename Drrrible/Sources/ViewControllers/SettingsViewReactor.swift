//
//  SettingsViewReactor.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 10/03/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import ReactorKit
import RxCocoa
import RxSwift

#warning("""
SettingsViewController 对应 Reactor 为 SettingsViewReactor。
在 SettingsViewReactor 中 state 的 sections 中有一个用于表示登录状态的项，即 logout。
SettingsViewController 中的 username 需要根据当前登录的用户信息进行改变，同时也需要会根据 Reactor 中的 Action 进行改变。

在 SettingsViewReactor 中将自己的 Action 的 Observable 和 userService.currentUser 的 Observable 进行了合并，使用的方法时：
```

```

SettingsViewReactor 的 state 在初始化时，只负责将 username 设置为了 nil，userService.currentUser 的 Observable 负责发出 username 的更改的事件。

""")

final class SettingsViewReactor: Reactor {
    
    enum Action {
        case updateCurrentUsername(String?)
        case logout
    }
    
    enum Mutation {
        case updateLogoutSection(SettingsViewSection)
        case setLoggedOut
    }
    
    struct State {
        var sections: [SettingsViewSection] = []
        var isLoggedOut: Bool = false
        
        init(sections: [SettingsViewSection]) {
            self.sections = sections
        }
    }
    
    fileprivate let userService: UserServiceType
    let initialState: State
    
    init(userService: UserServiceType) {
        self.userService = userService
        let aboutSection = SettingsViewSection.about([
            .version(SettingItemCellReactor(
                text: "version".localized,
                detailText: Bundle.main.version
            )),
            .github(SettingItemCellReactor(text: "view_on_github".localized, detailText: "devxoul/Drrrible")),
            .icons(SettingItemCellReactor(text: "icons_from".localized, detailText: "icons8.com")),
            .openSource(SettingItemCellReactor(text: "open_source_license".localized, detailText: nil)),
        ])
        
        let logoutSection = SettingsViewSection.logout([
            .logout(SettingItemCellReactor(text: "logout".localized, detailText: nil))
        ])
        
        let sections = [aboutSection] + [logoutSection]
        self.initialState = State(sections: sections)
        _ = self.state
    }
    
    /*
    SettingsViewReactor 不仅要提供自身的 action 的状态 Observable，
     还需要结合 userService 的 currentUser 的状态 Observable。
     所以在 ReactorKit 框架的 transform 方法中，将两个数据流进行了合并。
    */
    func transform(action: Observable<Action>) -> Observable<Action> {
        let updateCurrentUsername = self.userService.currentUser
            .map {
                Action.updateCurrentUsername($0?.name)
            }
        // 将自身的 action Observable，和由 currentUser 转化而来的 Observable 进行了合并
        return Observable.of(action, updateCurrentUsername).merge()
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .updateCurrentUsername(name):
            let section = SettingsViewSection.logout([
                .logout(SettingItemCellReactor(text: "logout".localized, detailText: name))
            ])
            return .just(.updateLogoutSection(section))
            
        case .logout:
            return .just(.setLoggedOut)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .updateLogoutSection(newSection):
            guard let index = state.sections.firstIndex(where: { section in
                if case (.logout, .logout) = (section, newSection) {
                    return true
                } else {
                    return false
                }
            })
                else { return state }
            state.sections[index] = newSection
            return state
        case .setLoggedOut:
            state.isLoggedOut = true
            return state
        }
    }
    
}
