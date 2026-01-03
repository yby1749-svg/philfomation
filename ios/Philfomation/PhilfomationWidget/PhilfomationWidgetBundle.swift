//
//  PhilfomationWidgetBundle.swift
//  PhilfomationWidget
//

import WidgetKit
import SwiftUI

@main
struct PhilfomationWidgetBundle: WidgetBundle {
    var body: some Widget {
        CommunityWidget()
        ExchangeRateWidget()
        BusinessWidget()
    }
}
