//
//  MenuController.swift
//  OpalImagePicker
//
//  Created by Sina on 11/26/19.
//  Copyright © 2019 Opal Orange LLC. All rights reserved.
//

import Foundation
import UIKit


/// MenuItem available variables
struct menuItem{
    var title:String!
    var image:UIImage!
    var description:String!
    var id: Int!
}

/// MenuDelegate which contains didSelectItem for sending selectedItem's index and title to delegate.
protocol MenuDelegate:AnyObject {
    func didSelectItem(index:Int,title:String)
}
class Menu:UIView,UITableViewDataSource,UITableViewDelegate {
    
    /// Menue's frame
    private var _frame :CGRect!
    
    /// Menu's current viewController
    private weak var _viewController : UIViewController!
    
    /// Menu's table
    private var _table : UITableView!
    
    /// Menu's itmes
    private var _items = [menuItem]()
    
    /// Delegate of menu
    weak var delegate:MenuDelegate?
    
    private var selectedItem = IndexPath(row: 0, section: 0)
    /// Menu's current state
    ///
    /// - open: If menu is open
    /// - close: If menu is closed
    enum menuState {
        case open
        case close
    }
    
     /// Current state of menu
     var state = menuState.close
    
    
    /// This init create's and add's MenuView to given viewController's navigationBar.
    ///
    /// - Parameters:
    ///   - viewController: A viewController to add menu to it's navigation bar.
    ///   - items: Items of menu
    init(viewController:UIViewController,items:[menuItem]){
        _viewController = viewController
//        _frame = CGRect(x: _viewController.view.frame.width-_viewController.view.frame.width, y: 50, width: UIScreen.main.bounds.width, height: CGFloat(items.count*90))
        _frame = CGRect(x: 0, y: 0, width: _viewController.view.frame.width, height: _viewController.view.frame.height)
        super.init(frame: _frame)
        _viewController.view.addSubview(self)
        constraintBuilder(view: self, parent: _viewController.view)
        self.alpha = 0
        _items = items
        configs()
    }
    
    // MARK: Constraints
    private func constraintBuilder(view:UIView,parent:UIView,heightConst:CGFloat=0){
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: parent, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: parent, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: parent, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: parent, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: heightConst).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// This function configure menu
    private func configs(){
        self.backgroundColor = UIColor.white
        
        configTable()
    }
    
    /// This function configure menu's table.
    private func configTable(){
        _table = UITableView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height) , style: UITableView.Style.plain)
        _table.delegate = self
        _table.dataSource = self
        self.addSubview(_table)
        let topBarHeight = UIApplication.shared.statusBarFrame.size.height +
            (_viewController.navigationController?.navigationBar.frame.height ?? 0.0)
        constraintBuilder(view: _table,parent:self,heightConst:-topBarHeight)
        _table.estimatedRowHeight = 90
//        _table.isScrollEnabled = false
        _table.register(UINib(nibName: "MenuCell", bundle: Bundle.main), forCellReuseIdentifier: "cell")
    }
    
    /// This function add's shadow to menu view.
    func show(){
        if state == .close {
            open()
        }
        else {
            close()
        }
    }
    
    /// This function open's up menu with appear animation
    private func open(){
        UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: {
            self.alpha = 1
        }) { (success) in
            self.state = .open
        }
    }
    
    /// This function close's menu with disolve animation
    private func close(){
        UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: {
            self.alpha = 0
        }) { (success) in
            self.state = .close
        }
    }
    
    /// Number of sections in table
    ///
    /// - Parameter tableView: UITableView
    /// - Returns: Number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// Number of rows in section of a table which is number of items in menu
    ///
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - section: SectionId
    /// - Returns: Number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _items.count
    }
    
    /// Each cell of a table is inherited from 'MenuCell' with 'cell' identifier
    ///
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: UITableViewCell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = _table.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MenuCell
        if selectedItem == indexPath {
            cell.selectedIcon.isHidden = false
        }
        else {
            cell.selectedIcon.isHidden = true
        }
        cell.selectionStyle = .none
        cell.cellTitle.text = _items[indexPath.row].title
//        cell.cellLabel.font = UIFont(name: Fonts.mainFont, size: 15)
        cell.cellDescription.text = _items[indexPath.row].description
        cell.cellImage.image = _items[indexPath.row].image
        
        return cell
    }
    
    /// Height for rows at indexPath which depends on number of items in menu.
    ///
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: Height of each cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return self.frame.height/CGFloat(_items.count)
        return 90
    }
    
    /// Checks if user picked an item in menu and send its value via delegate.
    ///
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItem = indexPath
        tableView.reloadData()
        self.delegate?.didSelectItem(index: indexPath.row, title: _items[indexPath.row].title)
    }
}
