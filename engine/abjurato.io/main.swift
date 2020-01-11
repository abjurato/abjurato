//
//  main.swift
//  abjurato.io
//
//  Created by Anatoly Rosencrantz on 07/01/2020.
//  Copyright © 2020 Anatoly Rosencrantz. All rights reserved.
//

import Foundation
import Plot



let topcards: [(String, String)] = [
    ("dump keychain on iOS 11 with Electra", "images/1.jpeg"),
    ("find resources of an app (on jailbroken device)", "images/2.jpeg"),
    ("re-sign unencrypted binary (with Apple Developer account)", "images/3.jpeg"),
    ("decrypt iOS app (from jailbroken device memory)", "images/4.jpeg"),
    ("lib injection (on jailbroken device)", "images/5.jpeg"),
    ("Untitled 6", "images/6.jpeg")
]

let stories: [(String, String)] = [
    ("23/06/2019", "Iterating over SwiftUI views delivered in a Swift Package"),
    ("24/03/2018", "24/7 Accelerometer Tracking with Apple Watch"),
    ("16/03/2018", "Using Raspberry Pi as an Apple TimeMachine"),
    ("09/07/2017", "Adaptive Design in iOS"),
    ("15/03/2017", "OWASP for iOS: M1 - Improper Platform usage, Part 2"),
    ("29/01/2017", "Unified Logging and Activity Tracing"),
    ("24/12/2016", "OWASP for iOS: M1 - Improper Platform usage, Part 1"),
    ("04/05/2016", "Swift, Perfect, mustache and PostgreSQL on Heroku - 4"),
    ("03/05/2016", "Swift, Perfect, mustache and PostgreSQL on Heroku - 3"),
    ("01/05/2016", "Swift, Perfect, mustache and PostgreSQL on Heroku - 2"),
    ("30/04/2016", "Swift, Perfect, mustache and PostgreSQL on Heroku")
]


struct CSS {
    var code: String
    func render() -> String { return self.code }
    init(_ code: String) { self.code = code }
}

extension Node {
    static func card(_ node: Node<HTML.BodyContext>, bgpath: String) -> Node<HTML.BodyContext> {
        .div(.class("item flex-item"), .h2(node), .style("color: white; background: url('\(bgpath)') center center no-repeat"))
    }
}

extension Node  {
    static func row(_ date: Node<HTML.BodyContext>, _ text: Node<HTML.BodyContext>) -> Node<HTML.TableContext> {
        .tr(
            .td(.span(date, .style("color: #D3D3D3; font-style: bold;"))),
            .td(.span(" ")),
            .td(.span(text, .style("font-style: italic")))
        )
    }
}

struct Website {
    var general = CSS("""
    :root {
        color-scheme: light dark;
        --special-text-color: hsla(60, 100%, 50%, 0.5);
        --border-color: black;
    }
    body {
        padding-left: 120px;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
    }

    .list {
        padding-left: 20px;
    }

    .comment {
        font-style: italic;
    }
    """)
    var cards = CSS("""
    .container {
        margin: 5px;
        width: auto;
        height: 420px;
    }

    .item {
        display: flex;
        justify-content: center;
        align-items: center;
        margin: 30px;
        padding-left: 5px;
        width: 222px;
        height: 360px
        box-shadow: 0 0 10px rgba(0,0,0,0.3);
        border-radius: 10px;
    }

    .flex {
        display: flex;
        flex-wrap: nowrap;
        overflow-y: auto;
    }

    .flex-item {
        flex: 0 0 auto;
    }
    """)
    
    var index = HTML(
        .head(
            .title("Head"),
            .stylesheet("cards.css"),
            .stylesheet("general.css")
        ),
        .body(
            .h1("do {"),
            .p (
                .div(
                    .class("container flex"),
                    .forEach(topcards) { .card(.text($0.0), bgpath: $0.1) }
                )
            ),
            
            .h1("} catch _ {"),
            .table (
                .class("list"),
                .forEach(stories) { .row(.text($0.0), .text($0.1)) }
            ),
            
            .h1("}"),
            .div("mailto:rosencrantz[at]protonmail.com", .class("comment")),
            .h6("This website is written in Swift and generated by Plot and hosted on GitHub Pages")
        )
    )
    

    
    static func render() {
        let base = URL(fileURLWithPath: CommandLine.arguments.last!, isDirectory: true)
        let website = Website()
        
        let mirror = Mirror(reflecting: website)
        
        mirror.children.forEach { child in
            if let filename = child.label, let code = child.value as? HTML {
                try! code.render().write(to: base.appendingPathComponent(filename).appendingPathExtension("html"),
                                         atomically: true,
                                         encoding: .utf8)
            }
            if let filename = child.label, let code = child.value as? CSS {
                try! code.render().write(to: base.appendingPathComponent(filename).appendingPathExtension("css"),
                                         atomically: true,
                                         encoding: .utf8)
            }
        }
    }
}



Website.render()

