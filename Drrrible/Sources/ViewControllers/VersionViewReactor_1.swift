//
//  VersionViewReactor_1.swift
//  Drrrible
//
//  Created by fuyoufang on 2019/12/29.
//  Copyright © 2019 Suyeol Jeon. All rights reserved.
//

import ReactorKit
import RxSwift

final class VersionViewReactor_1: Reactor {
    enum Action {
        case checkForUpdates
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setLatestVersion(String?)
    }
    
    var isLoading: Bool = false
    var latestVersion: String?
    var currentVersion: String = Bundle.main.version ?? "0.0.0"
    
    struct State {
        var sections: [VersionCellSection_1]
    }
    
    fileprivate let appStoreService: AppStoreServiceType
    let initialState: State
    
    init(appStoreService: AppStoreServiceType) {
        self.appStoreService = appStoreService
        
        let sections = type(of: self).createSections(currentVersion: currentVersion, latestVersion: latestVersion, isLoading: isLoading)
        initialState = State(sections: sections)
        
        _ = self.state
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .checkForUpdates:
            let startLoading: Observable<Mutation> = .just(.setLoading(true))
            let clearLatestVersion: Observable<Mutation> = .just(.setLatestVersion(nil))
            let setLatestVersion: Observable<Mutation> = self.appStoreService.latestVersion()
                .asObservable()
                .map { $0 ?? "⚠️" }
                .map(Mutation.setLatestVersion)
            let stopLoading: Observable<Mutation> = .just(.setLoading(false))
            return Observable.concat([startLoading, clearLatestVersion, setLatestVersion, stopLoading])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .setLoading(isLoading):
            self.isLoading = isLoading
            state.sections = type(of: self).createSections(currentVersion: currentVersion, latestVersion: latestVersion, isLoading: isLoading)
            return state
            
        case let .setLatestVersion(latestVersion):
            self.latestVersion = latestVersion
            state.sections = type(of: self).createSections(currentVersion: currentVersion, latestVersion: latestVersion, isLoading: isLoading)
            return state
        }
    }
    
    fileprivate static func createSections(currentVersion: String?,
                                           latestVersion: String?,
                                           isLoading: Bool) -> [VersionCellSection_1] {
        let section = VersionCellSection_1.versions([
            .currentVersion(VersionCellReactor_1(title: "currentVersion", detail: currentVersion, isLoading: false)),
            .latestVersion(VersionCellReactor_1(title: "latestVersion", detail: latestVersion, isLoading: isLoading))
        ])
        return [section]
    }
}

