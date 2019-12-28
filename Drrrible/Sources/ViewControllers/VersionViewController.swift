//
//  VersionViewController.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 19/04/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import UIKit
import RxDataSources
import ReactorKit
import ReusableKit

final class VersionViewController: BaseViewController, View {
    
    // MARK: Constants
    
    fileprivate struct Reusable {
        static let cell = ReusableCell<VersionCell>()
    }
    
    fileprivate struct Metric {
        static let iconViewTop = 35.f
        static let iconViewSize = 100.f
        static let iconViewBottom = 0.f
    }
    
    // MARK: Properties
    #if DEBUG
    private let dataSource: RxTableViewSectionedReloadDataSource<VersionCellSection>
    
    #endif
    
    
    // MARK: UI
    
    fileprivate let iconView = UIImageView(image: #imageLiteral(resourceName: "Icon512")).then {
        $0.layer.borderColor = UIColor.db_border.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = Metric.iconViewSize * 13.5 / 60
        #warning("minificationFilter 的作用是什么？")
        $0.layer.minificationFilter = CALayerContentsFilter.trilinear
        $0.clipsToBounds = true
    }
    
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.register(Reusable.cell)
    }
    
    // MARK: Initializing
    
    init(reactor: VersionViewReactor) {
        defer { self.reactor = reactor }
        #if DEBUG
        dataSource = type(of: self).dataSourceFactory()
        #endif
        super.init()
        self.title = "version".localized
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .db_background
        #if !DEBUG
        tableView.dataSource = self
        #endif
        tableView.contentInset.top = Metric.iconViewTop + Metric.iconViewSize + Metric.iconViewBottom
        tableView.addSubview(iconView)
        view.addSubview(self.tableView)
        
    }
    
    override func setupConstraints() {
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.iconView.snp.makeConstraints { make in
            make.top.equalTo(Metric.iconViewTop - self.tableView.contentInset.top)
            make.centerX.equalToSuperview()
            make.size.equalTo(Metric.iconViewSize)
        }
    }
    
    
    // MARK: Binding
    
    func bind(reactor: VersionViewReactor) {
        // Action
        self.rx.viewWillAppear
            .map { _ in Reactor.Action.checkForUpdates }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // State
        #if DEBUG
        
        reactor.state
            .map { $0.sections }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        #else
        
        reactor.state
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: self.disposeBag)
        #endif
    }
    
    private static func dataSourceFactory() -> RxTableViewSectionedReloadDataSource<VersionCellSection> {
        return .init(configureCell: { dataSource, tableView, indexPath, item -> UITableViewCell in
            let cell = tableView.dequeue(Reusable.cell, for: indexPath)
            cell.reactor = item.reactor
            return cell
        })
    }
}
#if DEBUG

#else
extension VersionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(Reusable.cell, for: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = "current_version".localized
            cell.detailTextLabel?.text = self.reactor?.currentState.currentVersion
            cell.isLoading = false
        } else {
            cell.textLabel?.text = "latest_version".localized
            cell.detailTextLabel?.text = self.reactor?.currentState.latestVersion
            cell.isLoading = self.reactor?.currentState.isLoading ?? false
        }
        return cell
    }
    
}
#endif

#if DEBUG

enum VersionCellSection {
    case versions([VersionCellSectionItem])
}

extension VersionCellSection: SectionModelType {
    var items: [VersionCellSectionItem] {
        switch self {
        case .versions(let sections):
            return sections
        }
    }
    
    init(original: Self, items: [VersionCellSectionItem]) {
        switch original {
        case .versions(let sections):
            self = .versions(sections)
        }
    }
}

enum VersionCellSectionItem {
    case currentVersion(VersionCellReactor)
    case latestVersion(VersionCellReactor)
    
    var reactor: VersionCellReactor {
        switch self {
        case .currentVersion(let reactor):
            return reactor
        case .latestVersion(let reactor):
            return reactor
        }
    }
}
 
class VersionCellReactor: Reactor {
    typealias Action = NoAction
    
    
    struct State {
        let title: String
        let detail: String?
        let isLoading: Bool
    }
    
    let initialState: State
    
    init(title: String, detail: String?, isLoading: Bool) {
        initialState = State(title: title, detail: detail, isLoading: isLoading)
    }
    
}

private final class VersionCell: BaseTableViewCell, View {
    fileprivate let activityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    override var accessoryView: UIView? {
        didSet {
            if self.accessoryView === self.activityIndicatorView {
                self.activityIndicatorView.startAnimating()
            } else {
                self.activityIndicatorView.stopAnimating()
            }
        }
    }
    
    var isLoading: Bool {
        get { return self.activityIndicatorView.isAnimating }
        set { self.accessoryView = newValue ? self.activityIndicatorView : nil }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:
    func bind(reactor: VersionCellReactor) {
        reactor.state
            .subscribe(onNext: { [weak self] (state) in
                self?.textLabel?.text = state.title
                self?.detailTextLabel?.text = state.detail
                self?.isLoading = state.isLoading
            })
            .disposed(by: disposeBag)
    }
}

#else

private final class VersionCell: UITableViewCell {
    fileprivate let activityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    override var accessoryView: UIView? {
        didSet {
            if self.accessoryView === self.activityIndicatorView {
                self.activityIndicatorView.startAnimating()
            } else {
                self.activityIndicatorView.stopAnimating()
            }
        }
    }
    
    var isLoading: Bool {
        get { return self.activityIndicatorView.isAnimating }
        set { self.accessoryView = newValue ? self.activityIndicatorView : nil }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
