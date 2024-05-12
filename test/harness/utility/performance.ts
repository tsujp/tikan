import { PerformanceObserver } from 'node:perf_hooks'

function performanceObserver(list, observer) {
    for (const entry of list.getEntries()) {
        // if (entry.entryType === 'mark') {
        //     console.log(`${entry.name}'s at: ${entry.startTime}`)
        // }
        if (entry.entryType === 'measure') {
            console.log(`[${entry.name}]: ${entry.duration.toFixed(1)}ms`)
        }
    }

    return observer
}

export function withPerformanceObserver() {
    const observer = new PerformanceObserver(performanceObserver)
    observer.observe({ entryTypes: ['mark', 'measure'] })

    return observer
}
