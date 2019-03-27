//
//  AddressesViewController.swift
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

class AddressesViewController: BaseViewController {
    enum AddressesSelectedState: Int {
        case active = 0
        case expired = 1
        case contacts = 2
    }
    
    private var selectedState: AddressesSelectedState = .active
    private var addresses = [BMAddress]()

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Addresses"
        
        AppModel.sharedManager().walletAddresses = AppModel.sharedManager().getWalletAddresses()

        tableView.register(AddressCell.self)
        
        filterAddresses()
        
        AppModel.sharedManager().addDelegate(self)
    }
    

    private func filterAddresses() {
        if let addresses = AppModel.sharedManager().walletAddresses {
            self.addresses = addresses as! [BMAddress]
        }
        
        switch selectedState {
        case .active:
            self.addresses = self.addresses.filter { $0.isExpired() == false}
        case .expired:
            self.addresses = self.addresses.filter { $0.isExpired() == true}
        case .contacts:
            self.addresses.removeAll()
        }
    }
    
    //MARK: -IBActions
    
    @IBAction func onStatus(sender : UISegmentedControl) {
        selectedState = AddressesViewController.AddressesSelectedState(rawValue: sender.selectedSegmentIndex) ?? .active
        
        filterAddresses()
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
    }
}

extension AddressesViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 95
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = AddressViewController(address: addresses[indexPath.row])
        vc.hidesBottomBarWhenPushed = true
        pushViewController(vc: vc)
    }
}

extension AddressesViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: AddressCell.self, for: indexPath)
            .configured(with: (row: indexPath.row, address: addresses[indexPath.row], single:false))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return headerView
        }
        
        return nil
    }
}

extension AddressesViewController : WalletModelDelegate {
    func onWalletAddresses(_ walletAddresses: [BMAddress]) {
        DispatchQueue.main.async {
            self.filterAddresses()
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
}