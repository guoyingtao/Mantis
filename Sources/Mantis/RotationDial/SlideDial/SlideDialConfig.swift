//
//  SlideDialConfig.swift
//  Mantis
//
//  Created by Yingtao Guo on 6/19/23.
//

import Foundation

struct SlideDialConfig {
    var lengthRatio: CGFloat = 0.8
    var limitation: CGFloat = 45
    
    var scaleBarNumber = 41
    var majorScaleBarNumber = 5
    
    var scaleColor = UIColor.gray
    var majorScaleColor = UIColor.white
    
    var positiveIndicatorColor = UIColor.yellow
    var notPositiveIndicatorColor = UIColor.white
    
    var indicatorSize = CGSize(width: 40, height: 40)
    var slideRulerHeight: CGFloat = 50
}
