//
//  Entity+CoreDataProperties.swift
//  BusinessCompanion
//
//  Created by Eric Rudenja on 17.04.2021.
//  Copyright © 2021 Apple. All rights reserved.
//
//

import Foundation
import CoreData


extension TranscriptEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TranscriptEntity> {
        return NSFetchRequest<TranscriptEntity>(entityName: "TranscriptEntity")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var transcriptBody: String?

}

extension TranscriptEntity : Identifiable {

}
