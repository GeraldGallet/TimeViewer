//
//  Preset.swift
//  TimeViewer
//
//  A reusable timer template: a name plus a raw input string ("1h", "@5pm").
//  The input is resolved against the current time when the preset is launched.
//

import Foundation

struct Preset: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var input: String
}
