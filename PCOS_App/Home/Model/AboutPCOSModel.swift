import Foundation

struct AboutPCOSSection {
    let title: String
    let description: String   
       let imageName: String     
    let contentBlocks: [ContentBlock]
}

struct ContentBlock {
    let heading: String?
    let body: String?
    let imageName: String?
}
