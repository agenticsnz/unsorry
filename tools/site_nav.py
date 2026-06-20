"""Shared top-navigation for the generated docs pages (ADR-038, ADR-066).

The site's pages — home, leaderboard, proof graph, queue — share one top-nav. The
*list of pages* is the single load-bearing fact; defining it once here keeps the
generators (`tools.visualiser`, `tools.queue_board`) from drifting out of step
when a page is added or renamed. The two static, hand-authored shells
(`docs/index.html`, `docs/leaderboard.html`) restate the same list — HTML cannot
import Python — and are kept in step by review; every generator-rendered page
imports this module so it never has to.
"""
from __future__ import annotations

#: (href, label) for each site page, in nav order — the single source of truth.
NAV_ITEMS: tuple[tuple[str, str], ...] = (
    ("index.html", "Home"),
    ("leaderboard.html", "Leaderboard"),
    ("proofs-contributors-visualisation.html", "Proof graph"),
    ("queue.html", "Queue"),
)

#: Tailwind classes for the active / inactive nav links (shared design language).
ACTIVE_CLASS = "px-3 py-1.5 rounded-lg bg-slate-100 text-slate-800"
INACTIVE_CLASS = (
    "px-3 py-1.5 rounded-lg text-slate-500 hover:bg-slate-100 "
    "hover:text-slate-800 transition-colors"
)

#: The `<nav>` wrapper class used by the generated card pages (inset + bottom rule).
CARD_WRAPPER_CLASS = (
    "flex items-center gap-1 px-6 md:px-10 py-3 text-sm font-medium "
    "border-b border-slate-100"
)


def render_nav(
    current_href: str,
    *,
    wrapper_class: str = CARD_WRAPPER_CLASS,
    indent: str = "  ",
) -> str:
    """Render the shared ``<nav>`` block, marking ``current_href`` as current.

    ``wrapper_class`` is the page-specific class on the ``<nav>`` element so a page
    can match its own layout while sharing the link list and styling.
    """
    links: list[str] = []
    for href, label in NAV_ITEMS:
        if href == current_href:
            links.append(
                f'{indent}  <a href="{href}" aria-current="page" '
                f'class="{ACTIVE_CLASS}">{label}</a>'
            )
        else:
            links.append(
                f'{indent}  <a href="{href}" class="{INACTIVE_CLASS}">{label}</a>'
            )
    return (
        f'{indent}<nav class="{wrapper_class}" aria-label="Primary">\n'
        + "\n".join(links)
        + f"\n{indent}</nav>"
    )
