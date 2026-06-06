import Foundation

class FoodListdataStore {

    static var shared = FoodListdataStore()
    private init() {}

    private var cachedItems: [FoodItem]?

    func loadFoodItems() -> [FoodItem] {

        if let cached = cachedItems {
            return cached
        }

        guard let url = Bundle.main.url(forResource: "csvjson", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("FoodListDataStore: csvjson.json not found in bundle")
            return []
        }

        do {
            let items = try JSONDecoder().decode([FoodItem].self, from: data)
            cachedItems = items
            print("FoodListDataStore: Loaded \(items.count) food items from JSON")
            return items
        } catch {
            print("FoodListDataStore: JSON decode error — \(error)")
            return []
        }
    }

    func foodItem(byId id: Int) -> FoodItem? {
        return loadFoodItems().first { $0.id == id }
    }

    func searchFoodItems(query: String) -> [FoodItem] {
        let items = loadFoodItems()
        if query.isEmpty { return items }
        return items.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
}
