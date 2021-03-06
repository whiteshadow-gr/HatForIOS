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

public struct HATFeedDate: HATObject {
    
    // MARK: - Coding Keys
    
    /**
     The JSON fields used by the hat
     
     The Fields are the following:
     * `iso` in JSON is `iso`
     * `unix` in JSON is `unix`
     */
    private enum CodingKeys: String, CodingKey {
        
        case iso
        case unix
    }
    
    // MARK: - Variables

    /// The date of the feed item in ISO format
    public var iso: String = ""
    /// The date of the feed item in unix time stamp fromat
    public var unix: Int = 0
}
