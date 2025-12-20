//
//  YCHenAIBloodPressureViewController.swift
//  SwiftDemo
//
//  Created by YuChen on 2025/5/29.
//
import YCProductSDK
var macAdrees : String = "2B:7F:7C:7E:93:E2"
class YCHenAIBloodPressureViewController : BaseViewController {
    // 设置选项
    
    private lazy var items = [
        "init",
        "automatic",
        "start",
        "stop",
        "calibration",
        "getModel",
        "delModel",
        ]
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "HenAI BloodPressure"
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            // 初始化
            henaiInit()
        } else if indexPath.row == 1{
            // 自动测量
            automaticMeasurement()
        }else if indexPath.row == 2{
            // 手动开启
            startHenAIBPMeasure()
        }else if indexPath.row == 3{
            // 手动停止 60s
            stopHenAIBPMeasure()
        }else if indexPath.row == 4{
            // 自动校准
            henAIBloodPressureCalibration()
        }else if indexPath.row == 5{
            // 自动测量
            gethenAIBloodPressureModel()
        }else if indexPath.row == 6{
            // 自动测量
            delBPModel()
        }
    }
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        
//        if section == 0 {
//            return "init"
//        }
//        
//        return "start"
//    }
    func numberOfSections(in: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self))
        cell?.textLabel?.text = items[indexPath.row]
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 20)
        return cell!
    }
}
// 实现初始化 自动测量 手动测量和停止 自动校准 获取数据模型 删除数据模型的方法
extension YCHenAIBloodPressureViewController {
    func henaiInit() {
        YCProduct.initHenAIBP(account: "", password:"", name: "", gender: 1, macAddress: macAdrees, deviceName: "rh303", deviceHAModel: "YC127", description: "ceshi", birthday: "2000-01-12", height: 170, weight: 55) { state, response in
            print("res == \(String(describing: response))")
        }
    }
    func automaticMeasurement() {
        YCProduct.startHenAIAutomaticMeasurement(macAddress: macAdrees) { state, response in
            print("自动测量结果===  \(String(describing: response))")
        }
    }
    func henAIBloodPressureCalibration() {
        YCProduct.henAIBloodPressureCalibration(systolicBloodPressure: 130, diastolicBloodPressure: 60) { state, response in
            print("自动校准结果===  \(String(describing: response))")
        }
    }
    func startHenAIBPMeasure() {
        YCProduct.startHenAIBPMeasure(mac: macAdrees)
    }
    func stopHenAIBPMeasure() {
        YCProduct.stopHenAIBPMeasure { state, response in
            print("state === \(state)  response === \(String(describing: response))")
        }
    }
    func gethenAIBloodPressureModel() {
        YCProduct.gethenAIBloodPressureModel(macAddress: macAdrees) { state, response in
            print("获取恒爱血压模型结果===  \(String(describing: response))")
        }
    }
    func delBPModel() {
        YCProduct.delBPModel(mac: macAdrees) { status, message, data in
            print("删除恒爱血压模型结果===  \(data)")
        }
    }
}
