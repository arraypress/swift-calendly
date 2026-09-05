# swift-calendly

Calendly on a personal access token, not OAuth.

```swift
import Calendly

let calendly = Calendly(token: myToken)

try await calendly.me()                        // and everything keys off this
try await calendly.eventTypes()                // what can be booked
try await calendly.upcoming()                  // bookings still to come
try await calendly.availableTimes(for: type)   // open slots, with booking links
try await calendly.availabilitySchedules()     // the weekly pattern behind them
```

## Why a token and not OAuth

A personal access token is scoped and made in the web UI in a minute — no
OAuth flow, no client secret, no server. That is what lets a scheduling tool
exist as a CLI at all. OAuth is only needed when each user connects their own
account without pasting anything, which is a consumer app's problem.

**Take read scopes only** unless you need to cancel or create. Under
*Scheduling* and *User management* — you need the second even for read-only,
because every endpoint takes your user URI and you get that from `/users/me`.

## The organising idea

**Everything is addressed by URI**, a full `https://api.calendly.com/...` URL,
never a bare id. Listing your own event types means passing your own user URI
as a query parameter:

```
GET /event_types?user=https://api.calendly.com/users/74bcca0b
```

So `/users/me` is a *mandatory first call* before almost anything else. This
client fetches it once and remembers it, rather than making every caller thread
it through — pass `user:` explicitly to skip even that.

## Three things measured, not assumed

**A past start time is rejected outright.** Calendly answers with a bare
`"The supplied parameters are invalid."` that names no cause. This refuses
locally, before spending the call. The window itself is generous — a fortnight
was accepted in testing.

**An empty interval list is a day off**, not missing data. A weekly schedule
has seven rules; the ones with no intervals are the days you do not work.
`schedule.workingDays` filters them, and `rule.isAvailable` says it outright.

**Timestamps carry microseconds** (`2026-09-05T14:16:45.503059Z`), which the
non-fractional ISO 8601 style refuses to parse.

All verified against a live account on 2026-09-05.

## Flattened on the way out

A booking's `location` is a typed object whose useful field depends on its
type — a join URL for a video call, an address for a place. It comes out as one
string. The invitee counter comes out as two plain numbers. Re-encoding writes
the flat shape, not Calendly's.

## Tested

16 tests. Fourteen offline on recorded bodies — both response envelopes, the
URI-addressing, the identity being fetched once, the day-off rule, each HTTP
status. Two run against a real account, skipped unless you ask:

```console
$ CALENDLY_TOKEN=… swift test --filter LiveTests
```

Those passed 2026-09-05 and are **read-only** — nothing in this library's test
suite creates, cancels or modifies anything.

## Requirements

macOS 14+ / iOS 16+ · Swift 6 · no dependencies

## Installation

```swift
.package(url: "https://github.com/arraypress/swift-calendly.git", from: "0.1.0")
```

## Licence

MIT
