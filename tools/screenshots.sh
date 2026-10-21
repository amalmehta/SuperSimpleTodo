#!/bin/zsh
# Retakes the README screenshots (docs/images/tasks.png, calendar.png, activity.png) from a test copy of
# the app running on generated sample data. Your real tasks are never read or changed.
# The first run may ask to allow screen recording for your terminal app.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

xcodebuild -project SuperSimpleTodo.xcodeproj -scheme "Super Simple Todo" -derivedDataPath build build -quiet

# A copy with its own app ID, so it can't share settings or windows with the real app.
cp -R "build/Build/Products/Debug/Super Simple Todo.app" "$WORK/Demo.app"
rm -rf "$WORK/Demo.app/Contents/PlugIns"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.amalmehta.SuperSimpleTodo.demo" "$WORK/Demo.app/Contents/Info.plist"
codesign --force --deep --sign - "$WORK/Demo.app" 2>/dev/null

# Sample tasks and two weeks of activity, dated relative to today.
mkdir -p "$WORK/data"
python3 - "$WORK/data" <<'PY'
import json, sys, uuid, random, datetime as dt
d = sys.argv[1]; random.seed(7); now = dt.datetime.now(dt.timezone.utc)
iso = lambda t: t.strftime("%Y-%m-%dT%H:%M:%SZ")
today = dt.date.today()
due = lambda days: None if days is None else (today + dt.timedelta(days=days)).isoformat()
rows = [("Pay rent", 3, False, ["Daily"], 0), ("Finish quarterly report", 3, False, ["Work"], -1),
        ("Run 5k", 2, False, ["Fitness"], 2), ("Review chapter 4 notes", 2, False, ["Study"], 9),
        ("Call the dentist", 1, False, [], 1), ("Water the plants", 0, False, ["Daily"], None),
        ("Book flights", 1, False, ["Work"], 16), ("Stretch for 10 minutes", 1, True, ["Fitness", "Daily"], None),
        ("Read that article", 0, True, ["Study"], 0)]
tasks = []
for i, (t, p, done, tags, days) in enumerate(rows):
    task = {"id": str(uuid.uuid4()).upper(), "title": t, "priority": p, "isDone": done, "tags": tags,
            "createdAt": iso(now - dt.timedelta(hours=i))}
    if days is not None: task["deadline"] = due(days)
    tasks.append(task)
json.dump(tasks, open(f"{d}/Tasks.json", "w"), indent=1)
json.dump(["Daily", "Fitness", "Work", "Study"], open(f"{d}/Tags.json", "w"))
names = [("Run 5k", ["Fitness"]), ("Email Sam", ["Work"]), ("Groceries", ["Daily"]), ("Flashcards", ["Study"]),
         ("Laundry", ["Daily"]), ("Ship report", ["Work"]), ("Call the dentist", [])]
kinds = ["added"] * 5 + ["completed"] * 4 + ["deleted"] * 2 + ["uncompleted", "priorityChanged"]
events = []
for day in range(13, -1, -1):
    for _ in range(random.choice([1, 2, 3, 3, 4, 5])):
        k = random.choice(kinds); title, tags = random.choice(names)
        t = now - dt.timedelta(days=day, hours=random.randint(0, 8), minutes=random.randint(0, 59))
        e = {"id": str(uuid.uuid4()).upper(), "date": iso(min(t, now)), "kind": k, "taskTitle": title, "tags": tags}
        if k == "priorityChanged": e["detail"] = random.choice(["High", "Medium", "Low"])
        events.append(e)
json.dump(sorted(events, key=lambda e: e["date"]), open(f"{d}/Activity.json", "w"), indent=1)
PY

cat > "$WORK/winid.swift" <<'SWIFT'
import CoreGraphics
let pid = Int32(CommandLine.arguments[1])!
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
if let w = windows.first(where: { ($0[kCGWindowOwnerPID as String] as? Int32) == pid && ($0[kCGWindowLayer as String] as? Int) == 0 }) {
    print(w[kCGWindowNumber as String]!)
}
SWIFT

shoot() {  # $1 = tab, $2 = output file
  open -n "$WORK/Demo.app" --args -TasksFile "$WORK/data/Tasks.json" -StartTab "$1" -activityDays 14
  sleep 3
  osascript -e 'tell application id "com.amalmehta.SuperSimpleTodo.demo" to activate' 2>/dev/null || true
  sleep 1
  local pid=$(pgrep -f "$WORK/Demo.app/Contents/MacOS" | tail -1)
  local win=$(swift "$WORK/winid.swift" "$pid")
  screencapture -x -o -l "$win" "$2"
  kill "$pid"; sleep 1
  echo "Saved $2"
}
shoot tasks "$ROOT/docs/images/tasks.png"
shoot calendar "$ROOT/docs/images/calendar.png"
shoot activity "$ROOT/docs/images/activity.png"
