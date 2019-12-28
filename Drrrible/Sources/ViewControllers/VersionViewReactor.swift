//
//  VersionViewReactor.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 19/04/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import ReactorKit
import RxSwift

final class VersionViewReactor: Reactor {
    enum Action {
        case checkForUpdates
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setLatestVersion(String?)
    }
    
    struct State {
        #if DEBUG
        var sections: [VersionCellSection]
        var isLoading: Bool = false
        var latestVersion: String?
        #else
        
        var isLoading: Bool = false
        var currentVersion: String = Bundle.main.version ?? "0.0.0"
        var latestVersion: String?
        #endif
    }
    
    fileprivate let appStoreService: AppStoreServiceType
    #if DEBUG
    let initialState: State
    #else
    let initialState = State()
    
    #endif
    
    init(appStoreService: AppStoreServiceType) {
        self.appStoreService = appStoreService
        
        #if DEBUG
        let section = VersionCellSection.versions([
            .currentVersion(VersionCellReactor(title: "currentVersion", detail: Bundle.main.version ?? "0.0.0", isLoading: false)),
            .latestVersion(VersionCellReactor(title: "latestVersion", detail: nil, isLoading: true))
        ])
        initialState = State(sections: [section])
        #endif
        
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
            #if DEBUG
            guard let index = state.sections.firstIndex(where: { (section) -> Bool in
                if case .versions = section {
                    return true
                } else {
                    return false
                }
            })
                else {
                    return state
            }
            let section = state.sections[index]
            guard let latestVersionIndex = section.items.firstIndex(where: { (item) -> Bool in
                if case .latestVersion = item {
                    return true
                } else {
                    return false
                }
            })
                else {
                    return state
            }
            var items = section.items
            items[latestVersionIndex] = .latestVersion(VersionCellReactor(title: "latestVersion", detail: currentState.latestVersion, isLoading: isLoading))
            var newSections = state.sections
            newSections[index] = VersionCellSection.versions(items)
            state.sections = newSections
            state.isLoading = isLoading
            #else
            state.isLoading = isLoading
            #endif
            return state
            
        case let .setLatestVersion(latestVersion):
            #if DEBUG
            guard let index = state.sections.firstIndex(where: { (section) -> Bool in
                if case .versions = section {
                    return true
                } else {
                    return false
                }
            })
                else {
                    return state
            }
            let section = state.sections[index]
            guard let latestVersionIndex = section.items.firstIndex(where: { (item) -> Bool in
                if case .latestVersion = item {
                    return true
                } else {
                    return false
                }
            })
                else {
                    return state
            }
            var items = section.items
            items[latestVersionIndex] = .latestVersion(VersionCellReactor(title: "latestVersion", detail: latestVersion, isLoading: currentState.isLoading))
            var newSections = state.sections
            newSections[index] = VersionCellSection.versions(items)
            state.sections = newSections
            state.latestVersion = latestVersion
            #else
            state.latestVersion = latestVersion
            #endif
            return state
        }
    }
}
