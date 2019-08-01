/*
 *  Copyright (c) 2018 Zendesk. All rights reserved.
 *
 *  By downloading or using the Zendesk Mobile SDK, You agree to the Zendesk Master
 *  Subscription Agreement https://www.zendesk.com/company/customers-partners/master-subscription-agreement and Application Developer and API License
 *  Agreement https://www.zendesk.com/company/customers-partners/application-developer-api-license-agreement and
 *  acknowledge that such terms govern Your use of and access to the Mobile SDK.
 *
 */

import UIKit
import ZendeskConnect

class ViewController: UIViewController {
    
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var selectedKeyLabel: UILabel!
    @IBAction func unwind(segue:UIStoryboardSegue) { }
    private var keyStorage: ZendeskKeyStorage = ZendeskKeyStorage.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        useSelectedKey()
    }
    
    private func useSelectedKey() {
        guard let selectedKey = keyStorage.selectedZendeskKey else {
            return
        }
        
        Connect.instance.initialize(privateKey: selectedKey.keyID)
        selectedKeyLabel.text = "\(selectedKey.name) (\(selectedKey.environmentType))"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let user = Connect.instance.user {
            userLabel.text = user.firstName ?? user.userId
        }
    }

    @IBAction func login() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginController = storyboard.instantiateViewController(withIdentifier: "login-controller") as? LoginViewController else {
            return
        }
        loginController.delegate = self
        self.present(loginController, animated: true, completion: nil)
    }
    
    @IBAction func logout() {
        userLabel.text = ""
        Connect.instance.disablePushToken()
        Connect.instance.logoutUser()
    }
    
    @IBAction func alias() {
        guard let user = Connect.instance.user else { return }
        Connect.instance.identifyUser(user.aliased(aliasId:"\(arc4random())"))
    }
    
    @IBAction func track() {
        let event = EventFactory.createEvent(event: "testEvent", properties: ["foo": "bar"])
        Connect.instance.trackEvent(event)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "KeySegue", let viewController = segue.destination as? KeyViewController {
            viewController.delegate = self
        }
    }
}

extension ViewController: LoginDelegate {
    func loginController(_ loginController: LoginViewController, didLogin user: String, with userDetails: UserDetails) {
        userLabel.text = user
        guard let userId = userDetails["user_id"] else {return}
        Connect.instance.disablePushToken()
        Connect.instance.logoutUser()

        let user = User(firstName: userDetails["first_name"],
                        lastName: userDetails["last_name"],
                        email: userDetails["email"],
                        userId: userId,
                        phoneNumber: userDetails["phone_number"])

        Connect.instance.identifyUser(user)
    }
}

extension ViewController: KeyViewControllerDelegate {
    
    func didSelectKey(key: ZendeskKey, from viewController: UIViewController) {
        navigationController?.popViewController(animated: true)
        keyStorage.selectedZendeskKey = key
        useSelectedKey()
    }
}

