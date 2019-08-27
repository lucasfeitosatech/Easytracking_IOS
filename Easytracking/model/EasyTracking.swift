//
//  EasyTracking.swift
//  Easytracking
//
//  Created by Lucas Freitas on 26/08/19.
//  Copyright © 2019 First Decision. All rights reserved.
//

import Foundation

class EasyTracking: NSObject {
    
    var x = 0;
    var t = 0;
    var padY = 0;
    var padRS = 0;
    var padQR = 0;
    var padC = 0;
    var k = 0;
    var n = 0;
    var y = 0;
    var c = 0;
    var bytesQR = 0;
    
    
    init(from x:Int) {
        super.init()
        self.x = x
        self.calculateVariables()
        print("x: \(x) y:\(y) k:\(k) n:\(n) t:\(t) QR:\(bytesQR)")
    }
    
    private func calculateVariables(){
        let mod = (7 * x) % 8;
        if x <= 388 {
            if (mod != 0) {
                padY = 8 - mod;
                y = (7 * x + 8 - mod) / 8;
            } else {
                y = 7 * x / 8;
            }
            
            let mod2 = (2 * y) % 8;
            if (mod2 != 0) {
                padRS = 8 - mod2;
                k = (2 * y + 8 - mod2) / 8;
                
            } else {
                k = 2 * y / 8;
            }
            
            n = 3 * k;
            
            t = (n - k) / 2;
            
            
            if ((4 * y) % 8 != 0) {
                padC = (8 * (n - k)) % (4 * y);
                c = (4 * y + (8 * (n - k)) % (4 * y)) / 8;
                
            } else {
                c = 4 * y / 8;
            }
            
            if ((6 * y) % 8 != 0) {
                padQR = 8 - (6 * y) % 8;
                bytesQR = (6 * y + 8 - (6 * y) % 8 + 64 * 4) / 8;
                
            } else {
                bytesQR = 6 * y / 8;
            }
        }
        
    }
    
}
