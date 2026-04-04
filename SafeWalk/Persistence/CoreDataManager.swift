import CoreData
import Foundation

class CoreDataManager: ObservableObject {
    
    static let shared = CoreDataManager()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SafeWalk")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Contact CRUD
    func saveContact(_ contact: Contact) {
        let entity = ContactEntity(context: context)
        entity.update(from: contact)
        saveContext()
    }
    
    func fetchContacts() -> [Contact] {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            return try context.fetch(request).map { $0.toContact() }
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    func deleteContact(id: UUID) {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
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
