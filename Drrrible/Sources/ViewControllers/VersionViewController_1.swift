//
//  VersionViewController_1.swift
//  Drrrible
//
//  Created by fuyoufang on 2019/12/29.
//  Copyright © 2019 Suyeol Jeon. All rights reserved.
//

import Foundation
import UIKit
import RxDataSources
import ReactorKit
import ReusableKit

final class VersionViewController_1: BaseViewController, View {
    
    // MARK: Constants
    
    fileprivate struct Reusable {
        static let cell = ReusableCell<VersionCell_1>()
    }
    
    fileprivate struct Metric {
        static let iconViewTop = 35.f
        static let iconViewSize = 100.f
        static let iconViewBottom = 0.f
    }
    
    // MARK: Properties
    private let dataSource: RxTableViewSectionedReloadDataSource<VersionCellSection_1>
    
    
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
    
    init(reactor: VersionViewReactor_1) {
        defer { self.reactor = reactor }
        dataSource = type(of: self).dataSourceFactory()
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
    
    func bind(reactor: VersionViewReactor_1) {
        // Action
        self.rx.viewWillAppear
            .map { _ in Reactor.Action.checkForUpdates }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // State
        reactor.state
            .map { $0.sections }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private static func dataSourceFactory() -> RxTableViewSectionedReloadDataSource<VersionCellSection_1> {
        return .init(configureCell: { dataSource, tableView, indexPath, item -> UITableViewCell in
            let cell = tableView.dequeue(Reusable.cell, for: indexPath)
            cell.reactor = item.reactor
            return cell
        })
    }
}

private final class VersionCell_1: BaseTableViewCell, View {
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
    func bind(reactor: VersionCellReactor_1) {
        reactor.state
            .subscribe(onNext: { [weak self] (state) in
                self?.textLabel?.text = state.title
                self?.detailTextLabel?.text = state.detail
                self?.isLoading = state.isLoading
            })
            .disposed(by: disposeBag)
    }
}


enum VersionCellSection_1 {
    case versions([VersionCellSectionItem_1])
}

extension VersionCellSection_1: SectionModelType {
    var items: [VersionCellSectionItem_1] {
        switch self {
        case .versions(let sections):
            return sections
        }
    }
    
    init(original: Self, items: [VersionCellSectionItem_1]) {
        switch original {
        case .versions(let sections):
            self = .versions(sections)
        }
    }
}

enum VersionCellSectionItem_1 {
    case currentVersion(VersionCellReactor_1)
    case latestVersion(VersionCellReactor_1)
    
    var reactor: VersionCellReactor_1 {
        switch self {
        case .currentVersion(let reactor):
            return reactor
        case .latestVersion(let reactor):
            return reactor
        }
    }
}
 
class VersionCellReactor_1: Reactor {
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
