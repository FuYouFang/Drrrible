//
//  CollectionBorderedBackgroundView.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 21/08/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import UIKit

final class CollectionBorderedBackgroundView: UICollectionReusableView {
    #warning("""
    通过 layerClass 直接更换掉 layer
    """)
    override class var layerClass: AnyClass {
        return BorderedLayer.self
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        self.layer.frame.size = self.bounds.size
    }
}
