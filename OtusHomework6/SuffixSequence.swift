import Foundation

struct SuffixSequence: Sequence {
    
    let word: String
    
    func makeIterator() -> some IteratorProtocol {
        SuffixIterator(word: word)
    }
}
