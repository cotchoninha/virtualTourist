//
//  GCDBlackBox.swift
//  virtualTourist
//
//  Created by Marcela Ceneviva Auslenter on 03/08/2018.
//  Copyright © 2018 Marcela Ceneviva Auslenter. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
