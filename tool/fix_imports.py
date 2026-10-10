"""Maintenance script: normalise and repair lib/ imports.

Guarantees:
  * Every `package:skillbridge_python_lab/...` import points at a real file.
  * Broken package imports are repaired by matching the target file's basename.
  * Relative imports that resolve to a real file are converted to package form.
  * Relative imports within the same directory are left as-is.
"""
import os
import re

PKG = "skillbridge_python_lab"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
LIB = os.path.join(ROOT, "lib")
LIB_POSIX = LIB.replace("\\", "/")

import_re = re.compile(r"(import|export)\s+'([^']+)'")

# Index every dart file under lib/ by basename.
by_basename = {}
for dirpath, _dirs, files in os.walk(LIB):
    for name in files:
        if name.endswith(".dart"):
            rel = os.path.relpath(os.path.join(dirpath, name), LIB).replace("\\", "/")
            by_basename.setdefault(name, []).append(rel)


def exists(rel: str) -> bool:
    return os.path.isfile(os.path.join(LIB, rel))


def best_match(basename: str, wrong_rel: str):
    candidates = by_basename.get(basename, [])
    if not candidates:
        return None
    wrong_segments = wrong_rel.split("/")
    best, best_score = None, -1
    for cand in candidates:
        segs = cand.split("/")
        score = 0
        for a, b in zip(reversed(wrong_segments), reversed(segs)):
            if a == b:
                score += 1
            else:
                break
        if score > best_score:
            best, best_score = cand, score
    return best


changed = 0
for dirpath, _dirs, files in os.walk(LIB):
    for name in files:
        if not name.endswith(".dart"):
            continue
        path = os.path.join(dirpath, name)
        with open(path, "r", encoding="utf-8") as fh:
            text = fh.read()
        original = text

        def repl(match):
            kind, url = match.group(1), match.group(2)

            if url.startswith(f"package:{PKG}/"):
                rel = url[len(f"package:{PKG}/"):]
                if exists(rel):
                    return match.group(0)
                fixed = best_match(os.path.basename(rel), rel)
                if fixed:
                    return f"{kind} 'package:{PKG}/{fixed}'"
                return match.group(0)

            if url.startswith(".."):
                target = os.path.normpath(os.path.join(dirpath, url)).replace("\\", "/")
                if target.startswith(LIB_POSIX + "/"):
                    rel = target[len(LIB_POSIX) + 1:]
                    if exists(rel):
                        return f"{kind} 'package:{PKG}/{rel}'"
                fixed = best_match(os.path.basename(url), url)
                if fixed:
                    return f"{kind} 'package:{PKG}/{fixed}'"
            return match.group(0)

        text = import_re.sub(repl, text)
        if text != original:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(text)
            changed += 1
            print(f"fixed {os.path.relpath(path, ROOT)}")

print(f"done: {changed} files changed")
