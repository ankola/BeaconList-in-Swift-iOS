//
//  BeaconTblViewDelegateDataSource.swift
//  NWM
//
//  Created by Dhruv Patel on 30/06/21.
//

import UIKit

class BeaconTblViewDelegateDataSource: NSObject {
    //MARK:- Variables
    //Private
    fileprivate var arrSource: [BeaconListModel]
    fileprivate let tblView: UITableView
    fileprivate let delegate: TblViewDelegate
    
    //MARK:- Initializer
    init(arrData: [BeaconListModel], tbl: UITableView, delegate: TblViewDelegate) {
        arrSource = arrData
        tblView = tbl
        self.delegate = delegate
        super.init()
        setUp()
    }
    
    //MARK:- Private Methods
    fileprivate func setUp() {
        setUpColView()
    }
    
    fileprivate func setUpColView() {
        registerCell()
        tblView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        tblView.delegate = self
        tblView.dataSource = self
        self.setUpBackgroundView()
    }
    
    fileprivate func registerCell() {
        tblView.register(cellType: beaconListTableViewCell.self)
    }
    
    //MARK:- Public Methods
    func reloadData(arrData: [BeaconListModel]) {
        arrSource = arrData
        tblView.reloadData()
        self.setUpBackgroundView()
    }
    
    private func setUpBackgroundView() {
        if (self.arrSource.count > 0) {
            self.tblView.backgroundView = nil
        } else {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                self.tblView.backgroundView = UIView.makeNoRecordFoundView(frame: self.tblView.bounds, msg: "no_record_found")
//            }
        }
    }
}

//MARK:- UITableViewDelegate Methods
extension BeaconTblViewDelegateDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        delegate.willDisplay?(tbl: tableView, atIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate.didSelect?(tbl: tableView, indexPath: indexPath)
    }
}

//MARK:- UITableViewDataSource Methods
extension BeaconTblViewDelegateDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: beaconListTableViewCell.self, for: indexPath)
        cell.configureCell(data: arrSource[indexPath.row])
        return cell
    }
}


extension BeaconTblViewDelegateDataSource:UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate.tbldidScroll?(scrollView: scrollView)
    }
}






public protocol ClassNameProtocol {
    static var className: String { get }
    var className: String { get }
}

public extension ClassNameProtocol {
    static var className: String {
        return String(describing: self)
    }
    
    var className: String {
        return type(of: self).className
    }
}

extension NSObject: ClassNameProtocol {}

public extension UITableView {
    func register<T: UITableViewCell>(cellType: T.Type) {
        let className = cellType.className
        let nib = UINib(nibName: className, bundle: nil)
        register(nib, forCellReuseIdentifier: className)
    }
    
    func register<T: UITableViewCell>(cellTypes: [T.Type]) {
        cellTypes.forEach { register(cellType: $0) }
    }
    
    func dequeueReusableCell<T: UITableViewCell>(with type: T.Type, for indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withIdentifier: type.className, for: indexPath) as! T
    }
    
    func registerHeaderFooter<T: UITableViewHeaderFooterView>(HeaderFooterType: T.Type) {
        let className = HeaderFooterType.className
        let nib = UINib(nibName: className, bundle: nil)
        register(nib, forHeaderFooterViewReuseIdentifier: className)
    }
    
    func registerHeaderFooter<T: UITableViewHeaderFooterView>(HeaderFooterTypes: [T.Type]) {
        HeaderFooterTypes.forEach { registerHeaderFooter(HeaderFooterType: $0) }
    }
    
    func dynamicHeightTableHeaderViewCalling() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self,
                  let headerView = self.tableHeaderView else { return }
            var newFrame = headerView.frame
            let size = headerView.systemLayoutSizeFitting(.init(width: self.frame.width, height: 600), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
            newFrame.size = size
            headerView.frame = newFrame
            self.tableHeaderView = headerView
        }
    }
    
    func dynamicHeightTableFooterViewCalling() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self,
                  let headerView = self.tableFooterView else { return }
            var newFrame = headerView.frame
            let size = headerView.systemLayoutSizeFitting(.init(width: self.frame.width, height: 600), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
            newFrame.size = size
            headerView.frame = newFrame
            self.tableFooterView = headerView
        }
    }
}
