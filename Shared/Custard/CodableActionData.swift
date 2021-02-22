//
//  CodableActionData.swift
//  KanaKanjier
//
//  Created by β α on 2021/02/21.
//  Copyright © 2021 DevEn3. All rights reserved.
//

import Foundation
import SwiftUI

enum CodableTabData: Codable {
    case system(SystemTab)
    case custom(String)

    enum SystemTab: String, Codable {
        case user_hira
        case user_abc
        case flick_hira
        case flick_abc
        case flick_numbersymbols
        case qwerty_hira
        case qwerty_abc
        case qwerty_number
        case qwerty_symbols
    }
}

extension CodableTabData{
    enum CodingKeys: CodingKey{
        case system
        case custom
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .system(value):
            try container.encode(value, forKey: .system)
        case let .custom(value):
            try container.encode(value, forKey: .custom)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else{
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode enum."
                )
            )
        }
        switch key {
        case .system:
            let value = try container.decode(
                SystemTab.self,
                forKey: .system
            )
            self = .system(value)
        case .custom:
            let value = try container.decode(
                String.self,
                forKey: .custom
            )
            self = .custom(value)
        }
    }
}

extension CodableTabData{
    var tab: Tab {
        switch self{
        case let .system(tab):
            switch tab{
            case .flick_hira:
                return .flick_hira
            case .flick_abc:
                return .flick_abc
            case .flick_numbersymbols:
                return .flick_numbersymbols
            case .qwerty_hira:
                return .qwerty_hira
            case .qwerty_abc:
                return .qwerty_abc
            case .qwerty_number:
                return .qwerty_number
            case .qwerty_symbols:
                return .qwerty_symbols
            case .user_hira:
                return .user_dependent(.japanese)
            case .user_abc:
                return .user_dependent(.english)
            }
        case let .custom(identifier):
            //FIXME: ここをインポートで作業するように変更
            print("identifier")
            return .custard(.hieroglyph)
        }
    }
}

extension CodableTabData: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs){
        case let(.system(ltab), .system(rtab)):
            return ltab == rtab
        case let (.custom(ltab), .custom(rtab)):
            return ltab == rtab
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self{
        case let .system(tab):
            hasher.combine(tab)
            hasher.combine(CodingKeys.system)
        case let .custom(tab):
            hasher.combine(tab)
            hasher.combine(CodingKeys.custom)
        }
    }
}

enum CodableActionData: Codable {
    case input(String)
    case exchangeCharacter
    case delete(Int)
    case smoothDelete
    case enter
    case moveCursor(Int)
    case moveTab(CodableTabData)
    case toggleCursorMovingView
    case toggleCapsLockState
    case toggleTabBar
    case openApp(String)    //iOSのバージョンによって消える可能性がある

    var hasAssociatedValue: Bool {
        switch self{
        case .delete(_), .input(_), .moveCursor(_), .moveTab(_), .openApp(_): return true
        case .enter, .exchangeCharacter, .smoothDelete,.toggleCapsLockState, .toggleCursorMovingView, .toggleTabBar: return false
        }
    }

    var label: String {
        switch self{
        case let .delete(value): return "\(value)文字削除"
        case .enter: return "確定"
        case .exchangeCharacter: return "大文字/小文字、拗音/濁音/半濁音の切り替え"
        case let .input(value): return "「\(value)」を入力"
        case let .moveCursor(value): return "\(value)文字分カーソルを移動"
        case .moveTab(_): return "タブの移動"
        case .openApp(_): return "アプリを開く"
        case .smoothDelete: return "文頭まで削除"
        case .toggleCapsLockState: return "CapslockのモードのON/OFF"
        case .toggleCursorMovingView: return "カーソル移動画面のON/OFF"
        case .toggleTabBar: return "タブ移動画面のON/OFF"
        }
    }
}

extension CodableActionData{
    var actionType: ActionType {
        switch self{
        case let .input(value):
            return .input(value)
        case .exchangeCharacter:
            return .changeCharacterType
        case let .delete(value):
            return .delete(value)
        case .smoothDelete:
            return .smoothDelete
        case .enter:
            return .enter
        case let .moveCursor(value):
            return .moveCursor(value)
        case let .moveTab(value):
            return .moveTab(value.tab)
        case .toggleCursorMovingView:
            return .toggleShowMoveCursorView
        case .toggleCapsLockState:
            switch VariableStates.shared.aAKeyState{
            case .normal:
                return .changeCapsLockState(state: .capslock)
            case .capslock:
                return .changeCapsLockState(state: .normal)
            }
        case .toggleTabBar:
            return .toggleTabBar
        case let .openApp(value):
            return .openApp(value)
        }
    }

    var longpressActionType: KeyLongPressActionType {
        switch self{
        case let .input(value):
            return .input(value)
        case .delete:
            return .delete
        case let .moveCursor(value):
            return .moveCursor(value < 0 ? .left : .right)
        default:
            return .doOnce(self.actionType)
        }
    }
}

extension CodableActionData: Hashable {
    static func == (lhs: CodableActionData, rhs: CodableActionData) -> Bool {
        switch (lhs, rhs){
        case let (.input(l), .input(r)):
            return l == r
        case let (.delete(l), .delete(r)):
            return l == r
        case (.smoothDelete, .smoothDelete):
            return true
        case let (.moveCursor(l),.moveCursor(r)):
            return l == r
        case (.toggleTabBar, .toggleTabBar):
            return true
        case (.toggleCursorMovingView,.toggleCursorMovingView):
            return true
        case (.enter, .enter):
            return true
        case (.exchangeCharacter, .exchangeCharacter):
            return true
        case (.toggleCapsLockState,.toggleCapsLockState):
            return true
        case let (.moveTab(l), .moveTab(r)):
            return l == r
        case let (.openApp(l), .openApp(r)):
            return l == r
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        let key: CodingKeys
        switch self {
        case let .input(value):
            hasher.combine(value)
            key = .input
        case .exchangeCharacter:
            key = .exchange_character
        case let .delete(value):
            hasher.combine(value)
            key = .delete
        case .smoothDelete:
            key = .smooth_delete
        case .enter:
            key = .enter
        case let .moveCursor(value):
            hasher.combine(value)
            key = .move_cursor
        case let .moveTab(destination):
            hasher.combine(destination)
            key = .move_tab
        case .toggleCursorMovingView:
            key = .toggle_cursor_moving_view
        case .toggleTabBar:
            key = .toggle_tab_bar
        case .toggleCapsLockState:
            key = .toggle_caps_lock_state
        case let .openApp(value):
            hasher.combine(value)
            key = .open_app
        }
        hasher.combine(key)
    }
}

extension CodableActionData{
    enum CodingKeys: CodingKey{
        case input
        case exchange_character
        case delete
        case smooth_delete
        case enter
        case move_cursor
        case move_tab
        case toggle_cursor_moving_view
        case toggle_tab_bar
        case toggle_caps_lock_state
        case open_app
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .input(value):
            try container.encode(value, forKey: .input)
        case .exchangeCharacter:
            try container.encode(true, forKey: .exchange_character)
        case let .delete(value):
            try container.encode(value, forKey: .delete)
        case .smoothDelete:
            try container.encode(true, forKey: .smooth_delete)
        case .enter:
            try container.encode(true, forKey: .enter)
        case let .moveCursor(value):
            try container.encode(value, forKey: .move_cursor)
        case let .moveTab(destination):
            try container.encode(destination, forKey: .move_tab)
        case .toggleCursorMovingView:
            try container.encode(true, forKey: .toggle_cursor_moving_view)
        case .toggleTabBar:
            try container.encode(true, forKey: .toggle_tab_bar)
        case .toggleCapsLockState:
            try container.encode(true, forKey: .toggle_caps_lock_state)
        case let .openApp(value):
            try container.encode(value, forKey: .open_app)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else{
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode enum."
                )
            )
        }
        switch key {
        case .input:
            let value = try container.decode(
                String.self,
                forKey: .input
            )
            self = .input(value)
        case .exchange_character:
            self = .exchangeCharacter
        case .delete:
            let value = try container.decode(
                Int.self,
                forKey: .delete
            )
            self = .delete(value)
        case .smooth_delete:
            self = .smoothDelete
        case .enter:
            self = .enter
        case .move_cursor:
            let value = try container.decode(
                Int.self,
                forKey: .move_cursor
            )
            self = .moveCursor(value)
        case .move_tab:
            let destination = try container.decode(
                CodableTabData.self,
                forKey: .move_tab
            )
            self = .moveTab(destination)
        case .toggle_cursor_moving_view:
            self = .toggleCursorMovingView
        case .toggle_caps_lock_state:
            self = .toggleCapsLockState
        case .toggle_tab_bar:
            self = .toggleTabBar
        case .open_app:
            let destination = try container.decode(
                String.self,
                forKey: .open_app
            )
            self = .openApp(destination)
        }
    }
}
