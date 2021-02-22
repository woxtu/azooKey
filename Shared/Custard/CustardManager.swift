//
//  CustardManager.swift
//  KanaKanjier
//
//  Created by β α on 2021/02/21.
//  Copyright © 2021 DevEn3. All rights reserved.
//

import Foundation

struct CustardManagerIndex: Codable {
    var availableCustards: [String] = []
    var availableTabBars: [Int] = []
}

struct CustardManager {
    private static let directoryName = "custard/"
    private var index = CustardManagerIndex()

    private static func fileURL(name: String) -> URL {
        let directoryPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupKey)!
        let url = directoryPath.appendingPathComponent(directoryName + name)
        return url
    }

    private static func directoryExistCheck() {
        let directoryPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupKey)!
        let filePath = directoryPath.appendingPathComponent(directoryName).path
        if !FileManager.default.fileExists(atPath: filePath){
            do{
                debug("ファイルを新規作成")
                try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true)
            } catch {
                debug(error)
            }
        }
    }

    static func load() -> Self {
        directoryExistCheck()
        let themeIndexURL = fileURL(name: "index.json")
        do{
            let data = try Data(contentsOf: themeIndexURL)
            let index = try JSONDecoder().decode(CustardManagerIndex.self, from: data)
            debug(index)
            return self.init(index: index)
        } catch {
            debug(error)
            return self.init(index: CustardManagerIndex())
        }
    }

    func save() {
        let indexURL = Self.fileURL(name: "index.json")
        do {
            let data = try JSONEncoder().encode(self.index)
            try data.write(to: indexURL, options: .atomicWrite)
        } catch {
            debug(error)
        }
    }

    func custard(identifier: String) throws -> Custard {
        let fileURL = Self.fileURL(name: "\(identifier)_main.custard")
        let data = try Data(contentsOf: fileURL)
        let custard = try JSONDecoder().decode(Custard.self, from: data)
        return custard
    }

    func tabbar(identifier: Int) throws -> TabBarData {
        let fileURL = Self.fileURL(name: "tabbar_\(identifier).tabbar")
        let data = try Data(contentsOf: fileURL)
        let custard = try JSONDecoder().decode(TabBarData.self, from: data)
        return custard
    }

    mutating func saveCustard(custard: Custard) throws {
        //テーマを保存する
        do{
            let encoder = JSONEncoder()
            let data = try encoder.encode(custard)
            let fileURL = Self.fileURL(name: "\(custard.identifier)_main.custard")
            try data.write(to: fileURL)
        }

        if !self.index.availableCustards.contains(custard.identifier){
            self.index.availableCustards.append(custard.identifier)
        }
        self.save()
    }

    mutating func saveTabBarData(tabBarData: TabBarData) throws {
        //テーマを保存する
        do{
            let encoder = JSONEncoder()
            let data = try encoder.encode(tabBarData)
            let fileURL = Self.fileURL(name: "tabbar_\(tabBarData.identifier).tabbar")
            try data.write(to: fileURL)
        }

        if !self.index.availableTabBars.contains(tabBarData.identifier){
            self.index.availableTabBars.append(tabBarData.identifier)
        }
        self.save()
    }

    mutating func removeCustard(identifier: String){
        self.index.availableCustards = self.index.availableCustards.filter{$0 != identifier}
        do{
            let fileURL = Self.fileURL(name: "\(identifier)_main.custard")
            try FileManager.default.removeItem(atPath: fileURL.path)
            self.save()
        }catch{
            debug(error)
        }
    }

    mutating func removeTabBar(identifier: Int){
        self.index.availableTabBars = self.index.availableTabBars.filter{$0 != identifier}
        do{
            let fileURL = Self.fileURL(name: "tabbar_\(identifier).tabbar")
            try FileManager.default.removeItem(atPath: fileURL.path)
            self.save()
        }catch{
            debug(error)
        }
    }


    var availableCustards: [String] {
        return index.availableCustards
    }

    var availableTabBars: [Int] {
        return index.availableTabBars
    }

}