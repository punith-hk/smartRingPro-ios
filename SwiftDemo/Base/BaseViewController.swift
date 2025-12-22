//
//  BaseViewController.swift
//  YCSDKDemo
//
//  Created by YuChen on 2025/4/28.
//

import UIKit
class BaseViewController : UIViewController,UITableViewDataSource,UITableViewDelegate{
    
    
    var listView : UITableView!
    var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化显示内容的视图
        textView = UITextView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300))
        textView.backgroundColor = .white
        textView.text = "我是textView"
        view.addSubview(textView)
        // 初始化表格视图
        let tableViewY = textView.frame.origin.y + textView.frame.height
        listView = UITableView(frame: CGRect(x: 0, y: tableViewY, width: self.view.frame.width, height: self.view.frame.height - tableViewY), style: .plain)
        listView.dataSource = self
        listView.delegate = self
        listView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        view.addSubview(listView)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 49
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self))
        return cell!
    }
}
