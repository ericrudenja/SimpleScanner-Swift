//
//  Transcripts+CoreDataProperties.swift
//  BusinessCompanion
//
//  Created by Eric Rudenja on 17.04.2021.
//  Copyright © 2021 Apple. All rights reserved.
//
//

import Foundation
import CoreData


extension Transcripts {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transcripts> {
        return NSFetchRequest<Transcripts>(entityName: "Transcripts")
    }

    @NSManaged public var transcriptBody: String?
    @NSManaged public var createdAt: Date?

}

extension Transcripts : Identifiable {

}
