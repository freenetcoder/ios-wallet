//
//  AddressCell.swift
//  BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

class AddressCell: UITableViewCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var arrowImage: UIImageView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var idLabel: UILabel!
    @IBOutlet weak private var expiredLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

    }
}

extension AddressCell: Configurable {
    
    func configure(with options: (row: Int, address:BMAddress, single:Bool)) {
        if options.row % 2 == 0 {
            mainView.backgroundColor = UIColor.main.marineTwo
        }
        else{
            mainView.backgroundColor = UIColor.main.marine
        }
        
        arrowImage.isHidden = options.single
        
        idLabel.text = options.address.walletId
        
        if options.address.createTime == 0 {
            expiredLabel.text = ""
        }
        else{
            if options.address.isExpired() {
                expiredLabel.text = "Expired: " + options.address.formattedDate()
            }
            else{
                expiredLabel.text = "Expires: " + options.address.formattedDate()
            }
        }
        
        if options.address.label.isEmpty {
            nameLabel.text = " "
        }
        else{
            nameLabel.text = options.address.label
        }
        
        if options.single {
            self.selectionStyle = .none
        }
        else{
            let selectedView = UIView()
            selectedView.backgroundColor = mainView.backgroundColor?.withAlphaComponent(0.9)
            self.selectedBackgroundView = selectedView
        }
    }
}
