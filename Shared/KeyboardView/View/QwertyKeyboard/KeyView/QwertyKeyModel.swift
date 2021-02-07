//
//  QwertyKeyModel.swift
//  Keyboard
//
//  Created by β α on 2020/09/18.
//  Copyright © 2020 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

struct QwertyKeyModel: QwertyKeyModelProtocol{
    var variableSection = QwertyKeyModelVariableSection()
    
    let pressActions: [ActionType]
    var longPressActions: [KeyLongPressActionType]

    let labelType: KeyLabelType
    let needSuggestView: Bool
    let variationsModel: VariationsModel

    private let scale: (normalCount: Int, forCount: Int)
    
    var keySize: CGSize {
        CGSize(width: Design.shared.qwertyScaledKeyWidth(normal: scale.normalCount, for: scale.forCount), height: Design.shared.keyViewSize.height)
    }

    init(labelType: KeyLabelType, pressActions: [ActionType], longPressActions: [KeyLongPressActionType] = [], variationsModel: VariationsModel = VariationsModel([]),  needSuggestView: Bool = true, for scale: (normalCount: Int, forCount: Int) = (1, 1)){
        self.labelType = labelType
        self.pressActions = pressActions
        self.longPressActions = longPressActions
        self.needSuggestView = needSuggestView
        self.scale = scale
        self.variationsModel = variationsModel
    }

    func label(states: VariableStates) -> KeyLabel {
        KeyLabel(self.labelType, width: keySize.width)
    }

    func sound(){
        self.pressActions.first?.sound()
    }
}