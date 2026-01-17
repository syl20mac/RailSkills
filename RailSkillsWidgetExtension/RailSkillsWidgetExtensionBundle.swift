//
//  RailSkillsWidgetExtensionBundle.swift
//  RailSkillsWidgetExtension
//
//  Created by Sylvain gallon on 14/12/2025.
//

import WidgetKit
import SwiftUI

@main
struct RailSkillsWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        RailSkillsWidgetExtension()
        RailSkillsWidgetExtensionControl()
        RailSkillsWidgetExtensionLiveActivity()
    }
}
