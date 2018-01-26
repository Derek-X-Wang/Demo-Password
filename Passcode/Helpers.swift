//
//  Helpers.swift
//  Passcode
//
//  Created by Xinzhe Wang on 1/26/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import Foundation
import AWSDynamoDB
import Contacts
import AWSAuthCore

func contactBatchWrite(_ contacts: [CNContact]) {
    let tableName = "demopasscode-mobilehub-1983560859-PCContact"
    let dynamoDB = AWSDynamoDB.default()
    
    var batchWriteRequests = [AWSDynamoDBWriteRequest]()
    
    for contact in contacts {
        let userId = AWSDynamoDBAttributeValue()
        userId?.s = AWSIdentityManager.default().identityId!
        let contactId = AWSDynamoDBAttributeValue()
        contactId?.s = UUID().uuidString
        let familyName = AWSDynamoDBAttributeValue()
        familyName?.s = contact.familyName.isEmpty ? "empty" : contact.familyName
        let givenName = AWSDynamoDBAttributeValue()
        givenName?.s = contact.givenName.isEmpty ? "empty" : contact.givenName
        
        let writeRequest = AWSDynamoDBWriteRequest()
        writeRequest?.putRequest = AWSDynamoDBPutRequest()
        
        writeRequest?.putRequest?.item = ["userId": userId!, "contactId": contactId!, "firstName": givenName!, "LastName": familyName!]
        batchWriteRequests.append(writeRequest!)
    }
    
    let batchWriteItemInput = AWSDynamoDBBatchWriteItemInput()

    batchWriteItemInput?.requestItems = [tableName: batchWriteRequests]
    
    dynamoDB.batchWriteItem(batchWriteItemInput!).continueWith { (task) -> Any? in
        if let error = task.error as? NSError {
            print("error: \(error.userInfo["__type"] as? String)")
            print("msg: \(error.userInfo["message"] as? String)")
            return nil
        }
        print("dynamoDB batch saved")
        return nil
    }
}
