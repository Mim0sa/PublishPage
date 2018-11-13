//
//  Extension.swift
//  YDS_demo
//
//  Created by 吉乞悠 on 2018/11/13.
//  Copyright © 2018 吉乞悠. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    //返回随机颜色
    open class var randomColor:UIColor{
        get
        {
            let red = CGFloat(arc4random()%256)/255.0
            let green = CGFloat(arc4random()%256)/255.0
            let blue = CGFloat(arc4random()%256)/255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
    }
}
