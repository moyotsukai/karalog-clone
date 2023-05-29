//
//  ShareCell.swift
//  Karalog
//
//  Created by 伊藤汰海 on 2023/05/25.
//

import UIKit

protocol ShareCellDelegate {
    func reloadCell(indexPath: IndexPath)
}

class ShareCell: UICollectionViewCell {
    
    var delegate: ShareCellDelegate?
    var indexPath: IndexPath!
    
    @IBOutlet var musicImage: UIButton!
    @IBOutlet var musicName: UIButton!
    @IBOutlet var artistName: UIButton!
    @IBOutlet var content: UILabel!
    @IBOutlet var goodBtn: UIButton!
    @IBOutlet var userName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    
    @IBAction func touchGoodBtn(_ sender: Any) {

        print(2222222222)
        delegate?.reloadCell(indexPath: indexPath)
    }
    
}
