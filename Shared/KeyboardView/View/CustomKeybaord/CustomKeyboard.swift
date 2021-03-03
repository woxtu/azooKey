//
//  VerticalCustomKeyboard.swift
//  KanaKanjier
//
//  Created by β α on 2021/02/18.
//  Copyright © 2021 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

fileprivate extension CustardKeyLabelStyle{
    var keyLabelType: KeyLabelType {
        switch self{
        case let .text(value):
            return .text(value)
        case let .systemImage(value):
            return .image(value)
        }
    }
}

fileprivate extension CustardInterfaceLayoutScrollValue{
    var scrollDirection: Axis.Set {
        switch self.direction {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
}

fileprivate extension CustardInterfaceStyle{
    var keyboardLayout: KeyboardLayout {
        switch self{
        case .flick:
            return .flick
        case .qwerty:
            return .qwerty
        }
    }
}

fileprivate extension CustardInterface{
    var tabDesign: TabDependentDesign {
        switch self.key_layout{
        case let .gridFit(value):
            return TabDependentDesign(width: value.width, height: value.height, layout: key_style.keyboardLayout, orientation: VariableStates.shared.keyboardOrientation)
        case let .gridScroll(value):
            switch value.direction{
            case .vertical:
                return TabDependentDesign(width: CGFloat(value.columnKeyCount), height: CGFloat(value.screenRowKeyCount), layout: .flick, orientation: VariableStates.shared.keyboardOrientation)
            case .horizontal:
                return TabDependentDesign(width: CGFloat(value.screenRowKeyCount), height: CGFloat(value.columnKeyCount), layout: .flick, orientation: VariableStates.shared.keyboardOrientation)
            }
        }
    }

    var flickKeyModels: [CustardKeyPositionSpecifier: FlickKeyModelProtocol] {
        self.keys.mapValues{
            $0.flickKeyModel
        }
    }

    var qwertyKeyModels: [CustardKeyPositionSpecifier: QwertyKeyModelProtocol] {
        self.keys.mapValues{
            $0.qwertyKeyModel(layout: self.key_layout)
        }
    }
}

fileprivate extension CustardKeyDesign.ColorType{
    var flickKeyColorType: FlickKeyColorType {
        switch self{
        case .normal:
            return .normal
        case .special:
            return .tabkey
        }
    }

    var qwertyKeyColorType: QwertyUnpressedKeyColorType {
        switch self{
        case .normal:
            return .normal
        case .special:
            return .special
        }
    }

    var simpleKeyColorType: SimpleUnpressedKeyColorType {
        switch self{
        case .normal:
            return .normal
        case .special:
            return .special
        }
    }

}

fileprivate extension CustardInterfaceKey {
    var flickKeyModel: FlickKeyModelProtocol {
        switch self {
        case let .system(value):
            switch value {
            case .change_keyboard:
                return FlickChangeKeyboardModel.shared
            case let .enter(count):
                return FlickEnterKeyModel(keySizeType: .enter(count))
            case .flick_kogaki:
                return FlickKogakiKeyModel.shared
            case .flick_kutoten:
                return FlickKanaSymbolsKeyModel.shared
            case .flick_hira_tab:
                return FlickTabKeyModel.hiraTabKeyModel
            case .flick_abc_tab:
                return FlickTabKeyModel.abcTabKeyModel
            case .flick_star123_tab:
                return FlickTabKeyModel.numberTabKeyModel
            }
        case let .custom(value):
            let flickKeyModels: [FlickDirection: FlickedKeyModel] = value.variation.reduce(into: [:]){dictionary, variation in
                switch variation.type{
                case let .flick(direction):
                    dictionary[direction] = FlickedKeyModel(
                        labelType: variation.key.label.keyLabelType,
                        pressActions: variation.key.press_action.map{$0.actionType},
                        longPressActions: variation.key.longpress_action.map{$0.longpressActionType}
                    )
                case .variations:
                    break
                }
            }
            let model = FlickKeyModel(
                labelType: value.design.label.keyLabelType,
                pressActions: value.press_action.map{$0.actionType},
                longPressActions: value.longpress_action.map{$0.longpressActionType},
                flickKeys: flickKeyModels,
                needSuggestView: value.longpress_action.isEmpty && !value.variation.isEmpty,
                keycolorType: value.design.color.flickKeyColorType
            )
            return model
        }
    }

    private func convertToQwertyKeyModel(model: FlickKeyModelProtocol) -> QwertyKeyModelProtocol {
        let variations = VariationsModel([model.flickKeys[.left], model.flickKeys[.top], model.flickKeys[.right], model.flickKeys[.bottom]].compactMap{$0}.map{(label: $0.labelType, actions: $0.pressActions)})
        return QwertyKeyModel(labelType: .text("小ﾞﾟ"), pressActions: [.changeCharacterType], longPressActions: [], variationsModel: variations, keyColorType: .normal, needSuggestView: false, for: (1, 1))
    }

    func qwertyKeyModel(layout: CustardInterfaceLayout) -> QwertyKeyModelProtocol {
        switch self {
        case let .system(value):
            switch value {
            case .change_keyboard:
                return QwertyChangeKeyboardKeyModel(keySizeType: .normal(of: 1, for: 1))
            case let .enter(count):
                return QwertyEnterKeyModel(keySizeType: .enter(.count(count)))
            case .flick_kogaki:
                return  convertToQwertyKeyModel(model: FlickKogakiKeyModel.shared)
            case .flick_kutoten:
                return convertToQwertyKeyModel(model: FlickKanaSymbolsKeyModel.shared)
            case .flick_hira_tab:
                return convertToQwertyKeyModel(model: FlickTabKeyModel.hiraTabKeyModel)
            case .flick_abc_tab:
                return convertToQwertyKeyModel(model: FlickTabKeyModel.abcTabKeyModel)
            case .flick_star123_tab:
                return convertToQwertyKeyModel(model: FlickTabKeyModel.numberTabKeyModel)
            }
        case let .custom(value):
            let variations: [(label: KeyLabelType, actions: [ActionType])] = value.variation.reduce(into: []){array, variation in
                switch variation.type{
                case .flick:
                    break
                case .variations:
                    array.append((variation.key.label.keyLabelType, variation.key.press_action.map{$0.actionType}))
                }
            }

            let model = QwertyKeyModel(
                labelType: value.design.label.keyLabelType,
                pressActions: value.press_action.map{$0.actionType},
                longPressActions: value.longpress_action.map{$0.longpressActionType},
                variationsModel: VariationsModel(variations),
                keyColorType: value.design.color.qwertyKeyColorType,
                needSuggestView: value.longpress_action.isEmpty,
                for: (1,1)
            )
            return model
        }
    }

    var simpleKeyModel: SimpleKeyModelProtocol {
        switch self {
        case let .system(value):
            switch value{
            case .change_keyboard:
                return SimpleChangeKeyboardKeyModel()
            case .enter:
                return SimpleEnterKeyModel()
            case .flick_kogaki:
                return SimpleKeyModel(keyType: .functional, keyLabelType: .text("小ﾞﾟ"), unpressedKeyColorType: .special, pressActions: [.changeCharacterType], longPressActions: [])
            case .flick_kutoten:
                return SimpleKeyModel(keyType: .functional, keyLabelType: .text("、"), unpressedKeyColorType: .normal, pressActions: [.input("、")], longPressActions: [])
            case .flick_hira_tab:
                return SimpleKeyModel(keyType: .functional, keyLabelType: .text("abc"), unpressedKeyColorType: .special, pressActions: [.moveTab(.user_dependent(.japanese))], longPressActions: [])
            case .flick_abc_tab:
                return SimpleKeyModel(keyType: .functional, keyLabelType: .text("abc"), unpressedKeyColorType: .special, pressActions: [.moveTab(.user_dependent(.english))], longPressActions: [])
            case .flick_star123_tab:
                return SimpleKeyModel(keyType: .functional, keyLabelType: .text("☆123"), unpressedKeyColorType: .special, pressActions: [.moveTab(.existential(.flick_numbersymbols))], longPressActions: [])
            }
        case let .custom(value):
            return SimpleKeyModel(
                keyType: .normal,
                keyLabelType: value.design.label.keyLabelType,
                unpressedKeyColorType: value.design.color.simpleKeyColorType,
                pressActions: value.press_action.map{$0.actionType},
                longPressActions: value.longpress_action.map{$0.longpressActionType}
            )
        }
    }
}

struct CustomKeyboardView: View {
    @ObservedObject private var variableStates = VariableStates.shared
    @Environment(\.themeEnvironment) private var theme
    @State private var allowHitTesting = true
    private let custard: Custard
    private let tabDesign: TabDependentDesign

    init(custard: Custard){
        self.custard = custard
        self.tabDesign = custard.interface.tabDesign
    }

    var body: some View {
        switch custard.interface.key_layout{
        case let .gridFit(value):
            switch custard.interface.key_style{
            case .flick:
                let models = custard.interface.flickKeyModels
                ZStack{
                    HStack(spacing: tabDesign.horizontalSpacing){
                        ForEach(0..<value.width, id: \.self){x in
                            VStack(spacing: tabDesign.verticalSpacing){
                                ForEach(0..<value.height, id: \.self){y in
                                    if let model = models[.grid_fit(GridFitPositionSpecifier(x: x, y: y))]{
                                        FlickKeyView(model: model, tabDesign: tabDesign)
                                    }
                                }
                            }
                        }
                    }
                    HStack(spacing: tabDesign.horizontalSpacing){
                        ForEach(0..<value.width, id: \.self){x in
                            VStack(spacing: tabDesign.verticalSpacing){
                                ForEach(0..<value.height, id: \.self){y in
                                    if let model = models[.grid_fit(GridFitPositionSpecifier(x: x, y: y))]{
                                        SuggestView(model: model.suggestModel, tabDesign: tabDesign)
                                    }
                                }
                            }
                        }
                    }
                }
            case .qwerty:
                let models = custard.interface.qwertyKeyModels
                VStack(spacing: tabDesign.verticalSpacing){
                    ForEach(0..<value.height, id: \.self){y in
                        HStack(spacing: tabDesign.horizontalSpacing){
                            ForEach(0..<value.width, id: \.self){x in
                                if let model = models[.grid_fit(GridFitPositionSpecifier(x: x, y: y))]{
                                    QwertyKeyView(model: model, tabDesign: tabDesign)
                                }
                            }
                        }
                    }
                }
            }
        case let .gridScroll(value):
            let height = Design.shared.keyboardHeight - (Design.shared.resultViewHeight + 12)
            let models = (0..<custard.interface.keys.count).compactMap{custard.interface.keys[.grid_scroll(GridScrollPositionSpecifier($0))]}
            switch value.direction{
            case .vertical:
                let gridItem = GridItem(.fixed(tabDesign.keyViewWidth), spacing: tabDesign.horizontalSpacing/2)
                ScrollView(.vertical){
                    LazyVGrid(columns: Array(repeating: gridItem, count: value.columnKeyCount), spacing: tabDesign.verticalSpacing/2){
                        ForEach(0..<models.count, id: \.self){i in
                            SimpleKeyView(model: models[i].simpleKeyModel, tabDesign: tabDesign)
                        }
                    }
                }.frame(height: height)
            case .horizontal:
                let gridItem = GridItem(.fixed(tabDesign.keyViewHeight), spacing: tabDesign.verticalSpacing/2)
                ScrollView(.horizontal){
                    LazyHGrid(rows: Array(repeating: gridItem, count: value.columnKeyCount), spacing: tabDesign.horizontalSpacing/2){
                        ForEach(0..<models.count, id: \.self){i in
                            SimpleKeyView(model: models[i].simpleKeyModel, tabDesign: tabDesign)
                        }
                    }
                }.frame(height: height)
            }
        }
    }
}
