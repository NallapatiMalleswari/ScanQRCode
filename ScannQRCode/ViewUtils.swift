//
//  ViewUtils.swift
//  DhyanaGenric
//
//  Created by Hari Keerthipati on 11/07/18.
//  Copyright © 2018 AVANTARI. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    
    var width: CGFloat {
        return frame.width
    }
    
    var height: CGFloat {
        return frame.height
    }
    
    var x: CGFloat {
        return frame.origin.x
    }
    
    var y: CGFloat {
        
        set {
            frame.origin.y = y
        }
        get {
            return frame.origin.y
        }
    }
    
    var bottom: CGFloat
    {
        return frame.origin.y + frame.size.height
    }
    
    var right: CGFloat
    {
        return frame.origin.x + frame.size.width
    }
    
    var midX: CGFloat {
        return frame.midX
    }
    
    var minX: CGFloat {
        return frame.minX
    }
    
    var minY: CGFloat {
        return frame.minY
    }
    
    var midY: CGFloat {
        return frame.midY
    }
    
    var maxX: CGFloat {
        return frame.maxX
    }
    
    var maxY: CGFloat {
        return frame.maxY
    }
    
    var window: UIWindow
    {
        if let window = UIApplication.shared.keyWindow
        {
            return window
        }
        else
        {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            return (appDelegate?.window)!
        }
    }
}
