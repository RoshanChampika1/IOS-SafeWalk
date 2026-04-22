import CoreData
import Foundation
import Combine

class CoreDataManager: ObservableObject {
    
    static let shared = CoreDataManager()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SafeWalk")
        
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("CoreData migration failed, destroying local store for clean rebuild: \(error)")
                if let url = storeDescription.url {
                    try? FileManager.default.removeItem(at: url)
                }
                container.loadPersistentStores { _, _ in }
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Contact CRUD
    func saveContact(_ contact: Contact, for userID: String) {
        let entity = ContactEntity(context: context)
        entity.update(from: contact, userID: userID)
        saveContext()
    }
    
    func fetchContacts(for userID: String) -> [Contact] {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            return try context.fetch(request).map { $0.toContact() }
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    func deleteContact(id: UUID, for userID: String) {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND userID == %@", id as CVarArg, userID)
        if let entity = try? context.fetch(request).first {
            context.delete(entity)
            saveContext()
        }
    }
    
    func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
}

// MARK: - ContactEntity Extensions
// MARK: - ContactEntity Models
@objc(ContactEntity)
public class ContactEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var phone: String?
    @NSManaged public var email: String?
    @NSManaged public var isGuardian: Bool
    @NSManaged public var imageData: Data?
    @NSManaged public var userID: String?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContactEntity> {
        return NSFetchRequest<ContactEntity>(entityName: "ContactEntity")
    }

    func update(from contact: Contact, userID: String) {
        self.id = contact.id
        self.name = contact.name
        self.phone = contact.phone
        self.email = contact.email
        self.isGuardian = contact.isGuardian
        self.imageData = contact.imageData
        self.userID = userID
    }
    
    func toContact() -> Contact {
        Contact(
            id: id ?? UUID(),
            name: name ?? "",
            phone: phone ?? "",
            email: email ?? "",
            isGuardian: isGuardian,
            imageData: imageData
        )
    }
}
