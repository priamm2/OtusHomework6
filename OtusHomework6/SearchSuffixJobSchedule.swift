import Foundation
import Combine

actor SearchSuffixJobSchedule {
    private var queue: [ScheduledJob] = []

    func enqueue(_ job: ScheduledJob) {
        queue.append(job)
    }

    func run() {
        guard !queue.isEmpty else {
            print("Job queue is empty.")
            return
        }
        
        while (!queue.isEmpty) {
            let job = queue.removeFirst()
            print("Executing job")
            job.task()
        }
    }
}
