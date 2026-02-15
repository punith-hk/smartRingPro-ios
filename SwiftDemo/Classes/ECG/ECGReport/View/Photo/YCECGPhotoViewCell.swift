//
//  YCECGPhotoViewCell.swift
//  SmartHealthPro
//
//  Created by yc on 2020/12/2.
//  Copyright © 2020 yc. All rights reserved.
//

import UIKit
import YCProductSDK

class YCECGPhotoViewCell: UITableViewCell {
    
    /// ECG的数据信息
    var ecgInfo = YCHealthLocalECGInfo() {
        
        didSet {
            
            setupECGInfo()
        }
    }
    
    var ecgPicture: UIImage? {
        
        didSet {
            
            iconView.image = reSizeImage(ecgPicture, toSize: iconView.bounds.size)
        }
    }
    
    /// 显示行高
    static var rowHeight: CGFloat {
        
        return 110 + 160
    }
    
    
    @IBOutlet weak var iconView: UIImageView!
    
    @IBOutlet weak var ageLabel: UILabel!
    

    @IBOutlet weak var genderLabel: UILabel!
    
    
    @IBOutlet weak var bloodPressureLabel: UILabel!
    
    
 
    @IBOutlet weak var userInfoView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        
    }
    
    /// 点击查看大图
    @objc private func showBigPictureAction() {
        
        guard let image = ecgPicture else {
            return
        }
        
        let bigPictureView =
            YCECGReportBigPictureView(frame: UIScreen.main.bounds)
        
        UIApplication.shared.keyWindow?.addSubview(bigPictureView)
        
        bigPictureView.showBigPicture(image)
    }
  
    /// 设置ecg的信息
    private func setupECGInfo() {
        
        // Use actual user age or default to "--"
        let ageText = ecgInfo.age > 0 ? "\(ecgInfo.age)" : "--"
        ageLabel.text = "Age" + ": " + ageText
        
        // Use actual user gender or default to "--"
        let genderText = !ecgInfo.gender.isEmpty ? ecgInfo.gender : "--"
        genderLabel.text = "Gender" + ": " + genderText
        
        // Blood pressure display
        if ecgInfo.systolicBloodPressure == 0 ||
            ecgInfo.diastolicBloodPressure == 0 {
            
            bloodPressureLabel.text =
                "Blood pressure" + ": " + "--/--"
            
        } else {
        
            bloodPressureLabel.text =
                "Blood pressure" + ": " +
                "\(ecgInfo.systolicBloodPressure)/\(ecgInfo.diastolicBloodPressure)"
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        // Configure labels to prevent text truncation
        ageLabel.adjustsFontSizeToFitWidth = true
        ageLabel.minimumScaleFactor = 0.7
        genderLabel.adjustsFontSizeToFitWidth = true
        genderLabel.minimumScaleFactor = 0.7
        bloodPressureLabel.adjustsFontSizeToFitWidth = true
        bloodPressureLabel.minimumScaleFactor = 0.7
        bloodPressureLabel.numberOfLines = 1
        
        let tap =
            UITapGestureRecognizer(
                target: self,
                action: #selector(showBigPictureAction)
            )
        
        iconView.addGestureRecognizer(tap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func reSizeImage(_ image: UIImage?, toSize: CGSize) -> UIImage? {
        
        UIGraphicsBeginImageContext(CGSize(width: toSize.width, height: toSize.height))
        
        image?.draw(in: CGRect(x: 0, y: 0, width: toSize.width, height: toSize.height))
        
        let reSizeImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return reSizeImage
    }
    
}
