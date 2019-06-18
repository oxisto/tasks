/*
 Copyright 2019 Christian Banse

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import EventKit
import Foundation

class Tasks {
  var eventStore: EKEventStore!

  func callback(granted _: Bool, error _: Error?) {
    print("callback")
  }

  init() {
    eventStore = EKEventStore()

    let status = EKEventStore.authorizationStatus(for: EKEntityType.reminder)
    var authorized: Bool

    switch status {
    case .authorized:
      authorized = true
    case .restricted, .denied:
      exit(0)
    case .notDetermined:
      print("maybe?")
      eventStore.requestAccess(to: EKEntityType.reminder, completion: callback)
    }

    let calendars = eventStore.calendars(for: EKEntityType.reminder)

    for calendar in calendars {
      print("-", calendar.title)

      let semaphore = DispatchSemaphore(value: 0)

      let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [calendar])
      eventStore.fetchReminders(matching: predicate) { reminders in
        var i = 1
        for reminder in reminders ?? [] {
          if let title = reminder.title {
            print(String(format: " %d. %@  ", i, title))
          }
          i += 1
        }
        semaphore.signal()
      }
      semaphore.wait()
    }
  }
}

var tasks = Tasks()