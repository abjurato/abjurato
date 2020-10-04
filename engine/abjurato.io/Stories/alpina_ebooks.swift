//
//  alpina_ebooks.swift
//  abjurato.io
//
//  Created by Anatoly Rosencrantz on 04/10/2020.
//  Copyright © 2020 Anatoly Rosencrantz. All rights reserved.
//

import Foundation
import Plot

extension Stories {
    static func alpina_ebooks(_ base: URL, _ parent: URL) -> HTMLConstructor {
        let storyname = "alpinaEbooks"
        let filename = storyname + ".html"
        let address = parent.appendingPathComponent(filename)
        let image = base.appendingPathComponent("images").appendingPathComponent("0.jpeg")
        let generalCss = base.appendingPathComponent("general.css")
        let title = "iOS App Forensics and eBooks Smuggling"
        let date = "04/10/2020"
        
        return { HTML (
            .head(
                .stylesheet(generalCss.absoluteString),
                .title(title),
                .socialImageLink(image.absoluteString),
                .twitterCardType(.summary),
                .description(title),
                .url(address.absoluteString)
            ),
            .body (
                .a(.text("(lldb) thread step-out"), .href(base)), .class("comment"),
                
                .h1("\(title)"),
                
                .div(.i("Disclaimer: results of this research were sent to app developers back in February 2020. Since then a major release was rolled out, so I assume developers had fixed everything they had wanted to.")),
                
                .br(),
                .p(
                    .text("I read a lot, and love non-fiction. But when it comets to ebooks, I prefer native Books.app of iOS - I got used to its controls, animations, and feeling of a “one-stop shop” for all the books I've read lately. So, every time I happen to buy a ebook, first thing I look for is - how can this book be imported into Books.app?")
                ),
                
                .p(
                    .text("Same was the case with a books of a prominent Russian publisher Alpina Digital (https://ebook.alpina.ru) back in February. I've bough a book in their Alpina.Books iOS app and only then noticed that there's no Export button. Is that a problem for reverse engineer? Nope!")
                ),
                
                .p (
                    .text("First thing first, all iOS apps have 3 locations in the file system where their stuff can be stored:"),
                    .ol(
                        .li("application bundle - executable and resources installed from AppStore"),
                        .li("user data sandbox - everything that the app generates during it lifetime - saved files, local databases, UserDefaults plist, pre-backgrounding screenshot, etc"),
                        .li("shared App Groups - same as sandbox, but shared among one or more applications of one developer")
                    )
                ),
                
                .p(
                    .text("On my jailbroken test device, I've found where the user data sandbox is located (somewhere under "), .inline("/var/mobile/Containers/Data/Application/"), .text(") and transferred it to my mac via SSH using "), .inline("scp"), .text(" command. What do we have there?"),
                    .screenshot(.src(base.appendingPathComponent("images").appendingPathComponent(storyname + "_01.png")))
                ),
                
                .h2("Local Database"),
                
                .p(
                    .text("Cool, let's try to open this Realm database with an official RealmBrowser. A lot of tables:"),
                    .screenshot(.src(base.appendingPathComponent("images").appendingPathComponent(storyname + "_02.png")))
                ),
                
                .p (
                    .text("Let's peek at "), .inline("DBUser"), .text(" - it's pretty simple and had only 2 rows in my case, and one of them has a string with email address I've used during registration. It also has a reference to some "), .inline("DBItem"), .text(" in a column "), .inline("inventoryArray"), .text(", and that table looks more interesting:"),
                    .screenshot(.src(base.appendingPathComponent("images").appendingPathComponent(storyname + "_03.png")))
                ),
                
                .p(
                    .text("Following looks curious: "),
                    .ol(
                        .li("title - same as the book I've bought"),
                        .li(.text("book - reference to "), .inline("DBBook"), .text(" table") ),
                        .li(.text("dbFiles - reference to "), .inline("DBFiles"), .text(" table" ))
                    ),

                    .text("Let's check the last one:"),
                    .screenshot(.src(base.appendingPathComponent("images").appendingPathComponent(storyname + "_04.png"))),
                    .text("And here we go, just copy the downloadLink into our browser and full unprotected ebook is downloaded.")
                ),
                
                .h3("Mitigation"),
                .p (
                    .text("Realm database has an encryption mechanism built-in. Enabling it, all developers will need to care about is key management.")
                ),
                
                .br(),
                .h2("File System Artefacts"),
                
                .p(
                    .text("Another interesting thing in working directory is files folder with some strangely named contents (and similar to something we've already seen in DBBook table):"),
                    .screenshot(.src(base.appendingPathComponent("images").appendingPathComponent(storyname + "_05.png"))),
                    
                    .text("Inside the 33294 folder we can see subfolders Text with a bunch of html files, Images with illustrations we've previously seen in the book, and file named mimetype. Lets read what's inside:"),
                    .snippet("abjurato@Macintosh ~ % cat mimetype"),
                    .text("says this file is just a epub archive:"),
                    .snippet(.i("application/epub+zip%"))
                ),
                
                .p (
                    .text("Here we go, just rename 33294.zip to 33294.epub and we've got the book:"),
                    .screenshot(.src(base.appendingPathComponent("images").appendingPathComponent(storyname + "_06.png"))),
                    .text("What is more curious, this folder is not excluded from the backup and is not protected with data protection keys - which means attacker does not even need a jailbroken device because all downloaded books will be included into a device backup that is stored on their computer and can be inspected using iExplorer utility.")
                ),
                
                .h3("Mitigation"),
                
                .p (
                    .text("first, all the sensitive info that may be transferred from server should be excluded from backups. Backups can be stolen, they can be inspected, etc. Settings data protection key will also protect data at rest:"),
                    .gist(.src("https://gist.github.com/abjurato/57bc8a48751b190dbb70a767e96d9f4d.js")),
                    .text("On a jailbroken device, verification of data protection keys can be performed using FileDp tool by @satishb3.")
                ),
                    
                .p(.text("Then, the hard part is protection of data on a compromised device - in the extreme case it may be encrypted with a key that is never stored on device and it input by a user at runtime, similar to AppKey architecture we've implemented at ProtonMail. For a ebooks library tho (as we'll see in an upcoming article about Amazon Kindle app), custom book file format can work really well.")),
                    
                .br(),
                .h2("Sources"),
                .p(.a(.href("https://mobile-security.gitbook.io/mobile-security-testing-guide/ios-testing-guide/0x06d-testing-data-storage"), .text("[1] Mobile Security Testing Guide - Data storage on iOS"))),
                .p(.a(.href("https://protonmail.com/blog/ios-security-recommendations/"), .text("[2] ProtonMail AppKey local storage protection"))),
                
                .br(),
                .h2("Tools"),
                .p(.a(.href("https://realm.io/docs/swift/latest/#encryption"), .text("[3] Realm encryption APIs"))),
                .p(.a(.href("https://macroplant.com/iexplorer"), .text("[4] iExplorer"))),
                .p(.a(.href("https://github.com/abjurato/FileDp-Source"), .text("[5] FileDp"))),
                
                .br(),
                .div(.text(date), .class("comment"))
            )
        ) }
    }
}
