//
//  AWSContactManager.swift
//  Passcode
//
//  Created by Xinzhe Wang on 1/26/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import Foundation
import AWSCore
import AWSAuthCore
import AWSDynamoDB
import Contacts

class AWSContactManager {
    
    var uid: String //= UIDevice.current.identifierForVendor!.uuidString
    
    init(_ id: String) {
        uid = id
    }
    
    func fetchContacts() {
        let store = CNContactStore()
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authStatus == .notDetermined {
            store.requestAccess(for: .contacts, completionHandler: { (authorized, error) in
                if authorized { self.uploadContacts() }
            })
        } else if authStatus == .authorized {
            uploadContacts()
        }
    }
    
    func uploadContacts() {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey]
        
        do {
            let containers = try store.containers(matching: nil)
            print("There are \(containers.count) containers")
            try containers.forEach({
                let predicate = CNContact.predicateForContactsInContainer(withIdentifier: $0.identifier)
                let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
                print("🎈 identifier:\($0.identifier) count:\(contacts.count)")
                let filteredContacts = contacts.filter({ (contact) -> Bool in
                    let firstPhone = contact.phoneNumbers.first
                    let contactString = firstPhone == nil ? "Unknown" : firstPhone!.value.stringValue
                    let number = formatNumber(contactString)
                    let name = formatName(givenName: contact.givenName, familyName: contact.familyName)
                    if number == "Unknown" || name == "Unknown" {
                        return false
                    }
                    return true
                })
                contactBatchWrite(filteredContacts)
            })
        } catch let error {
            print("🎈 error fetching contacts", error.localizedDescription)
        }
    }
    
    func formatName(givenName: String, familyName: String) -> String {
        var res = "Unknown"
        if !givenName.isEmpty && !familyName.isEmpty {
            res = "\(givenName) \(familyName)"
        } else if !givenName.isEmpty {
            res = givenName
        } else if !familyName.isEmpty {
            res = familyName
        }
        return res
    }
    
    func formatNumber(_ number: String) -> String {
        let contactNumber = formatKey(number)
        guard !contactNumber.isEmpty else {
            return "Unknown"
        }
        return contactNumber
    }
    
    func formatKey(_ string: String) -> String {
        /* Replace with better implementation */
        return string.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "/", with: "")
    }
}
