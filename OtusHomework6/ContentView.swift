import SwiftUI

struct ContentView: View {
    private let jobQueue = SearchSuffixJobSchedule()
    
    @State private var segmentId: SegmentedId = .main
    
    @StateObject var textObserver = TextFieldObserver()
    
    @State var suffixList: [String: Int] = [:]
    @State var topFilteredSuffixes: [(String, String)] = []
    
    @State var searchTimer: [(String, String)] = []
    
    var body: some View {
        VStack {
            TextField("Введите текст", text: $textObserver.searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onChange(of: textObserver.debouncedText) { item in
                    Task {
                        await suffix(text: item.lowercased())
                    }
                }
            Picker("Main Picker", selection: $segmentId) {
                Text("Main").tag(SegmentedId.main)
                Text("Top").tag(SegmentedId.top)
                Text("History").tag(SegmentedId.history)
            }
            .pickerStyle(.segmented)
            List {
                switch segmentId {
                case .main:
                    ForEach(suffixList.sorted(by: { $0.key < $1.key }), id: \.key) { (key, value) in
                        HStack {
                            Text(key)
                            Spacer()
                            Text("\(value)")
                        }
                    }
                    .scrollContentBackground(.hidden)
                case .top:
                    ForEach(topFilteredSuffixes, id: \.0) { (key, value) in
                        HStack {
                            Text(key)
                            Spacer()
                            Text(value)
                        }
                    }
                    .scrollContentBackground(.hidden)
                case .history:
                    ForEach(searchTimer, id: \.0) { (key, value) in
                        HStack {
                            Text(key)
                            Spacer()
                            Text(value)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
    
    private func search(text: String) async {
        await suffix(text: text.lowercased())
    }
    
    private func suffix(text: String) async {
        await jobQueue.enqueue(
            ScheduledJob(
                task: {
                    let start = DispatchTime.now()
                    
                    let words = text.split(separator: " ")
                    let suffixArray = words.flatMap{ SuffixSequence(word: String($0)).map { $0 } }
                    let suffixes = suffixArray.reduce(into: [:]) { resultSuffixes, suffix in
                        resultSuffixes[suffix as! String, default: 0] += 1
                    }
                    suffixList = suffixes
                    let end = DispatchTime.now()
                    
                    let timeInterval = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000
                    searchTimer.append((text, "\(timeInterval) s"))
                    topSuffixesCalc()
                }
            )
        )
        await jobQueue.run()
    }
    
    private func topSuffixesCalc() {
        let filteredItems = suffixList.filter { $0.value >= 3 && $0.key.count >= 3 }
        let sortedArray = filteredItems.sorted { $0.value > $1.value }
        topFilteredSuffixes = sortedArray.prefix(10).map { (String($0.key), String($0.value)) }
    }
}

#Preview {
    ContentView()
}
