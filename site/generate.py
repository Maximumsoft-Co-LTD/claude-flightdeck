#!/usr/bin/env python3
"""
claude-flightdeck — static site generator.

> Why this exists (CLAUDE.md rule 7): the marketing/usage site must never
> drift from the template. Instead of a hand-maintained HTML site, this
> generator DERIVES the data-driven pages from the repo's own sources of
> truth, so a `git push` always reflects reality:
>   - changelog.html  ← CHANGELOG.md
>   - research.html   ← docs/research/INDEX.md  (incl. the shipped scoreboard)
>   - agents.html     ← core/.claude/agents/*.md  (+ presets/*/agents)
>   - skills.html     ← core/.claude/skills/*/SKILL.md  (+ presets/*/skills)
>   - index/workflow  ← hand-authored bodies in content/*.html.part
>     (curated explanation) with live counts injected.
>
> Zero third-party dependencies — runs on any python3. Output → site/dist/,
> which the GitHub Actions Pages workflow uploads. Run locally with:
>     python3 site/generate.py && open site/dist/index.html
"""
import os
import re
import html
import glob
import posixpath

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DIST = os.path.join(HERE, "dist")
CONTENT = os.path.join(HERE, "content")

GH = "https://github.com/Maximumsoft-Co-LTD/claude-flightdeck"
GH_BLOB = GH + "/blob/main"

NAV = [
    ("index.html", "Home"),
    ("workflow.html", "Workflow"),
    ("agents.html", "Agents"),
    ("skills.html", "Skills"),
    ("research.html", "Research"),
    ("changelog.html", "Changelog"),
]


# ----------------------------------------------------------------------------
# tiny, dependency-free helpers
# ----------------------------------------------------------------------------
def read(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def style_placeholders(text):
    """Wrap {{PROJECT_NAME}}-style template tokens in a chip so the site
    visibly communicates 'this is rendered per-project'."""
    return re.sub(r"\{\{([A-Z0-9_]+)\}\}", r'<span class="ph">{{\1}}</span>', text)


def inline(text, base_dir=None):
    """Inline markdown → HTML on an HTML-escaped string."""
    text = html.escape(text, quote=False)
    text = re.sub(r"`([^`]+)`", lambda m: "<code>" + m.group(1) + "</code>", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)

    def link(m):
        label, url = m.group(1), m.group(2)
        if not url.startswith("http") and not url.startswith("#"):
            # resolve a repo-relative .md link to a GitHub blob URL
            joined = url if base_dir is None else posixpath.normpath(
                posixpath.join(base_dir, url))
            url = GH_BLOB + "/" + joined.lstrip("/")
        return '<a href="%s">%s</a>' % (url, label)

    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", link, text)
    text = style_placeholders(text)
    return text


def md_to_html(md, base_dir=None):
    """A small block-level markdown renderer scoped to what our docs use:
    headings, fenced code, tables, blockquotes, hr, nested bullet lists,
    and paragraphs. Inline handled by inline()."""
    lines = md.split("\n")
    out, stack = [], []
    i, n = 0, len(lines)

    def close_lists(to=-1):
        while stack and stack[-1] > to:
            out.append("</ul>")
            stack.pop()

    while i < n:
        line = lines[i]

        # fenced code
        if line.strip().startswith("```"):
            close_lists()
            code, i = [], i + 1
            while i < n and not lines[i].strip().startswith("```"):
                code.append(lines[i])
                i += 1
            i += 1
            out.append("<pre><code>" + html.escape("\n".join(code)) + "</code></pre>")
            continue

        # table (header row followed by a |---|---| separator)
        if ("|" in line and i + 1 < n
                and re.match(r"^\s*\|?[\s:|-]*-[\s:|-]*\|?\s*$", lines[i + 1])):
            close_lists()
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            out.append('<div class="tbl"><table><thead><tr>')
            out.extend("<th>" + inline(c, base_dir) + "</th>" for c in cells)
            out.append("</tr></thead><tbody>")
            i += 2
            while i < n and "|" in lines[i] and lines[i].strip():
                row = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                out.append("<tr>" + "".join(
                    "<td>" + inline(c, base_dir) + "</td>" for c in row) + "</tr>")
                i += 1
            out.append("</tbody></table></div>")
            continue

        # hr
        if re.match(r"^\s*---+\s*$", line):
            close_lists()
            out.append("<hr>")
            i += 1
            continue

        # headings
        m = re.match(r"^(#{1,6})\s+(.*)$", line)
        if m:
            close_lists()
            lvl = len(m.group(1))
            out.append("<h%d>%s</h%d>" % (lvl, inline(m.group(2), base_dir), lvl))
            i += 1
            continue

        # blockquote (gather, render recursively)
        if line.strip().startswith(">"):
            close_lists()
            q, i = [], i
            while i < n and lines[i].strip().startswith(">"):
                q.append(re.sub(r"^\s*>\s?", "", lines[i]))
                i += 1
            out.append("<blockquote>" + md_to_html("\n".join(q), base_dir) + "</blockquote>")
            continue

        # list item (2-space indent = one nesting level)
        m = re.match(r"^(\s*)[-*]\s+(.*)$", line)
        if m:
            level = len(m.group(1)) // 2
            while stack and stack[-1] > level:
                out.append("</ul>")
                stack.pop()
            if not stack or stack[-1] < level:
                out.append("<ul>")
                stack.append(level)
            out.append("<li>" + inline(m.group(2), base_dir) + "</li>")
            i += 1
            continue

        # list-item continuation: an indented, non-bullet line while inside a
        # list folds into the preceding <li> (markdown soft-wrap inside a bullet)
        if stack and re.match(r"^\s+\S", line) and line.strip():
            if out and out[-1].startswith("<li>") and out[-1].endswith("</li>"):
                out.append(out.pop()[:-5] + " " + inline(line.strip(), base_dir) + "</li>")
                i += 1
                continue

        # blank
        if not line.strip():
            close_lists()
            i += 1
            continue

        # paragraph
        close_lists()
        para = [line]
        i += 1
        while (i < n and lines[i].strip()
               and "|" not in lines[i]
               and not re.match(r"^(#{1,6}\s|\s*[-*]\s|>|```|\s*---+\s*$)", lines[i])):
            para.append(lines[i])
            i += 1
        out.append("<p>" + inline(" ".join(para), base_dir) + "</p>")

    close_lists()
    return "\n".join(out)


def frontmatter(path):
    """Parse the leading --- YAML block. Handles single-line and quoted
    multi-line `description:` values; returns a plain dict of strings."""
    text = read(path)
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    block = text[3:end].strip("\n").split("\n")
    data, key = {}, None
    for ln in block:
        m = re.match(r"^([a-zA-Z_]+):\s*(.*)$", ln)
        if m and not ln.startswith(" "):
            key = m.group(1)
            data[key] = m.group(2).strip()
        elif key and (ln.startswith(" ") or ln.startswith("\t")):
            data[key] = (data.get(key, "") + " " + ln.strip()).strip()
    for k, v in data.items():
        v = v.strip()
        if len(v) >= 2 and v[0] in "\"'" and v[-1] == v[0]:
            v = v[1:-1]
        data[k] = v
    return data


# ----------------------------------------------------------------------------
# shell + nav
# ----------------------------------------------------------------------------
SHELL = read(os.path.join(CONTENT, "_shell.html"))


def page(slug, title, body, hero=False):
    nav = []
    for href, label in NAV:
        cls = ' class="active"' if href == slug else ""
        nav.append('<a href="%s"%s>%s</a>' % (href, cls, label))
    doc = (SHELL
           .replace("__TITLE__", html.escape(title))
           .replace("__NAV__", "\n".join(nav))
           .replace("__GH__", GH)
           .replace("__HEROCLASS__", "has-hero" if hero else "")
           .replace("__BODY__", body))
    write(os.path.join(DIST, slug), doc)


# ----------------------------------------------------------------------------
# data-driven page builders
# ----------------------------------------------------------------------------
def count_shipped():
    idx = os.path.join(ROOT, "docs/research/INDEX.md")
    if not os.path.exists(idx):
        return 0
    return len(re.findall(r"^\|\s*\d{4}-\d{2}-\d{2}\s*\|", read(idx), re.M))


def model_badge(model):
    model = (model or "").lower()
    if model in ("opus", "sonnet", "haiku"):
        return '<span class="badge m-%s">%s</span>' % (model, model)
    return ""


def agent_cards(paths):
    cards = []
    for p in sorted(paths):
        fm = frontmatter(p)
        name = fm.get("name", os.path.basename(p)[:-3])
        desc = fm.get("description", "")
        cards.append(
            '<article class="card reveal">'
            '<header><h3>%s</h3>%s</header>'
            '<p>%s</p></article>'
            % (style_placeholders(html.escape(name)),
               model_badge(fm.get("model")),
               style_placeholders(html.escape(desc))))
    return "\n".join(cards)


def skill_cards(paths):
    cards = []
    for p in sorted(paths):
        fm = frontmatter(p)
        name = fm.get("name", os.path.basename(os.path.dirname(p)))
        desc = fm.get("description", "")
        inv = fm.get("user_invocable", "").lower() == "true"
        badge = '<span class="badge cmd">/%s</span>' % html.escape(name) if inv else ""
        cards.append(
            '<article class="card reveal">'
            '<header><h3>%s</h3>%s</header>'
            '<p>%s</p></article>'
            % (style_placeholders(html.escape(name)), badge,
               style_placeholders(html.escape(desc))))
    return "\n".join(cards)


def build_agents():
    core = glob.glob(os.path.join(ROOT, "core/.claude/agents/*.md"))
    preset = glob.glob(os.path.join(ROOT, "presets/*/agents/*.md"))
    body = ['<section class="sheet"><div class="wrap">',
            '<p class="eyebrow">// roster</p>',
            "<h1>Specialized agents</h1>",
            '<p class="lede">Every dispatched agent runs the pre-task ritual '
            'and is reviewed by the 6-gate loop. Names with '
            '<span class="ph">{{TOKENS}}</span> render per-project at install.</p>',
            '<div class="grid">', agent_cards(core), "</div>"]
    if preset:
        body += ['<h2>Preset agents <span class="muted">(opt-in)</span></h2>',
                 '<div class="grid">', agent_cards(preset), "</div>"]
    body.append("</div></section>")
    page("agents.html", "Agents", "\n".join(body))


def build_skills():
    core = glob.glob(os.path.join(ROOT, "core/.claude/skills/*/SKILL.md"))
    preset = glob.glob(os.path.join(ROOT, "presets/*/skills/*/SKILL.md"))
    body = ['<section class="sheet"><div class="wrap">',
            '<p class="eyebrow">// flight controls</p>',
            "<h1>User-invocable skills</h1>",
            '<p class="lede">Slash-commands that drive the workflow. Type '
            '<code>/&lt;name&gt;</code> in Claude Code.</p>',
            '<div class="grid">', skill_cards(core), "</div>"]
    if preset:
        body += ['<h2>Preset skills <span class="muted">(opt-in)</span></h2>',
                 '<div class="grid">', skill_cards(preset), "</div>"]
    body.append("</div></section>")
    page("skills.html", "Skills", "\n".join(body))


def build_doc_page(slug, title, eyebrow, src_path, base_dir):
    md = read(os.path.join(ROOT, src_path))
    body = ('<section class="sheet doc"><div class="wrap">'
            '<p class="eyebrow">// %s</p>'
            '<div class="prose">%s</div>'
            '<p class="src-note">Auto-generated from '
            '<a href="%s/%s"><code>%s</code></a> — edits to that file flow here on the next build.</p>'
            "</div></section>"
            % (eyebrow, md_to_html(md, base_dir), GH_BLOB, src_path, src_path))
    page(slug, title, body)


def build_part(slug, title, part_file, hero=False, tokens=None):
    body = read(os.path.join(CONTENT, part_file))
    for k, v in (tokens or {}).items():
        body = body.replace(k, str(v))
    page(slug, title, body, hero=hero)


# ----------------------------------------------------------------------------
def main():
    if os.path.isdir(DIST):
        for f in glob.glob(os.path.join(DIST, "*")):
            os.remove(f)
    os.makedirs(DIST, exist_ok=True)

    # static assets → dist (flat, relative links so it works under /repo/ on Pages)
    for asset in glob.glob(os.path.join(HERE, "assets", "*")):
        write(os.path.join(DIST, os.path.basename(asset)), read(asset))
    write(os.path.join(DIST, ".nojekyll"), "")

    counts = {
        "__N_AGENTS__": len(glob.glob(os.path.join(ROOT, "core/.claude/agents/*.md"))),
        "__N_SKILLS__": len(glob.glob(os.path.join(ROOT, "core/.claude/skills/*/SKILL.md"))),
        "__N_RULES__": len(glob.glob(os.path.join(ROOT, "core/.claude/rules/*.md"))),
        "__N_SHIPPED__": count_shipped(),
        "__GH__": GH,
    }

    build_part("index.html", "claude-flightdeck — Claude Code control plane",
               "index.html.part", hero=True, tokens=counts)
    build_part("workflow.html", "Workflow", "workflow.html.part", tokens=counts)
    build_agents()
    build_skills()
    build_doc_page("research.html", "Research", "research workspace",
                   "docs/research/INDEX.md", "docs/research")
    build_doc_page("changelog.html", "Changelog", "changelog",
                   "CHANGELOG.md", "")

    print("built %d pages → %s" % (len(NAV), DIST))
    for f in sorted(glob.glob(os.path.join(DIST, "*.html"))):
        print("  ", os.path.basename(f))


if __name__ == "__main__":
    main()
