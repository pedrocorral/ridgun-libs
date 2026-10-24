"""Puts generated Ridgun source in the style `ridgunc --strict` requires: declared names use spaces, not "_"
(in the `fn ::` / `op ::` header and in each clause), and tuple types are space-separated ("(Int String)").
Calls may keep "_": the compiler treats `a_b c` and `a b c` as the same name."""
import re

HEADER = re.compile(r"^(fn|op) :: (.*)$")


def _name_words(rest):
    words = rest.split(" ")
    name = []
    for w in words:
        if not w or w[0].isupper() or w[0] in "[(" or w == "=>":
            break
        name.append(w)
    return name


def strict(src):
    lines = src.split("\n")
    names = {}
    for i, l in enumerate(lines):
        m = HEADER.match(l)
        if not m:
            continue
        rest = m.group(2)
        name = _name_words(rest)
        under = " ".join(name)
        spaced = under.replace("_", " ")
        if "_" in under:
            names[under] = spaced
        tail = rest[len(under):]
        tail = re.sub(r"\(([A-Z][A-Za-z0-9\[\] ]*?), ", lambda mm: "(" + mm.group(1) + " ", tail)
        while re.search(r"\(([A-Z][A-Za-z0-9\[\] ]*), ([A-Z])", tail):
            tail = re.sub(r"\(([A-Z][A-Za-z0-9\[\] ]*), ([A-Z])", r"(\1 \2", tail)
        lines[i] = f"{m.group(1)} :: {spaced}{tail}"
    for i, l in enumerate(lines):
        if l.startswith("      ") and not l.startswith("       "):
            body = l[6:]
            for under in sorted(names, key=len, reverse=True):
                if body.startswith(under + " ") or body == under:
                    lines[i] = "      " + names[under] + body[len(under):]
                    break
    return "\n".join(lines)


if __name__ == "__main__":
    import sys
    for p in sys.argv[1:]:
        s = open(p).read()
        open(p, "w").write(strict(s))
        print(f"strict style: {p}")
