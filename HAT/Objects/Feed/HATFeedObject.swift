/**
 * Copyright (C) 2018 HAT Data Exchange Ltd
 *
 * SPDX-License-Identifier: MPL2
 *
 * This file is part of the Hub of All Things project (HAT).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/
 */

// MARK: Struct

public struct HATFeedObject: HATObject {
    
    // MARK: - Variables
    
    /// The date of the feed object
    public var date: HATFeedDateObject = HATFeedDateObject()
    /// The source of the feed item
    public var source: String = ""
    /// The content of the feed item
    public var content: HATFeedContentObject?
    /// The title of the feed item
    public var title: HATFeedTitleObject = HATFeedTitleObject()
    /// The types of events, for google calendar
    public var types: [String]?
    /// The title of the feed item
    public var location: HATFeedLocationObject?
    
    public init() {
        
    }
}
