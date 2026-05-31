#!/usr/bin/env python3
"""Strip 'Color Schemes' menuItem blocks. Walks back two levels of <menuItem>
nesting from each setBWColorScheme: action to reach the Color Schemes wrapper,
then deletes that wrapper plus its matching close."""
import sys, re, pathlib

OPEN_RE = re.compile(r'<menuItem\b[^>]*?(?<!/)>')   # opening tag, not self-closing

def open_on_line(line):
    return OPEN_RE.search(line) and '/>' not in line.split('<menuItem', 1)[1].split('>', 1)[0]

def walk_back_n_menuitems(lines, idx, n):
    """Return the line index of the n-th ancestor <menuItem> opener."""
    depth = 0
    pos = idx
    found = 0
    for j in range(idx, -1, -1):
        line = lines[j]
        if '</menuItem>' in line:
            depth += 1
        if open_on_line(line):
            if depth == 0:
                found += 1
                if found == n:
                    return j
            else:
                depth -= 1
    return None

def matching_close(lines, start):
    depth = 1
    for k in range(start + 1, len(lines)):
        line = lines[k]
        if open_on_line(line):
            depth += 1
        if '</menuItem>' in line:
            depth -= 1
            if depth == 0:
                return k
    return None

def strip(path: pathlib.Path) -> int:
    text = path.read_text()
    lines = text.splitlines(keepends=True)
    if 'setBWColorScheme' not in text:
        return 0
    removed = 0
    while True:
        idx = next((i for i, ln in enumerate(lines) if 'setBWColorScheme' in ln), None)
        if idx is None:
            break
        # walk back 2 menuItem openers: parent (B/W item) and grandparent (Color Schemes wrapper).
        start = walk_back_n_menuitems(lines, idx, 2)
        if start is None:
            lines[idx] = ''  # safety scrub
            continue
        end = matching_close(lines, start)
        if end is None:
            lines[idx] = ''
            continue
        del lines[start:end + 1]
        removed += 1
    new_text = ''.join(lines)
    if new_text != text:
        path.write_text(new_text)
    return removed

if __name__ == '__main__':
    for arg in sys.argv[1:]:
        p = pathlib.Path(arg)
        n = strip(p)
        print(f'{p}: removed {n} Color Schemes block(s)')
