//
//  ViewController.swift
//  Happy
//
//  Created by k on 03/11/2016.
//  Copyright © 2016 egg. All rights reserved.
//

import UIKit
import Blessing

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        Blessing.shared.debug = true

        Blessing.shared.query("apple.com") { result in
            switch result {
            case .success(let record):
                print(record)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }

        print(Blessing.shared.query("apple.com", on: .qcloud))

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        print(Blessing.shared.query("apple.com", on: .qcloud))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        Blessing.shared.query("apple.com") { result in
            switch result {
            case .success(let record):
                print(record)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }

        print(Blessing.shared.query("apple.com", on: .qcloud).value?.ips)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

