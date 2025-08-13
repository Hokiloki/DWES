# DWES – Claude/Cline Project Rules (Project Guardrails)

- Scope: Arbeite ausschließlich am MVP (World-Map, Fog-of-War, Zoom-Layer, POI‑Platzhalter).
- Minimum Change Possible: Ändere nur die kleinste nötige Stelle. Kein Re‑Write ganzer Module ohne Freigabe.
- Proposals first: Bei Unsicherheit erst 2–3 Lösungswege kurz skizzieren, dann Umsetzung bestätigen lassen.
- Git hygiene: Kleinteilige Commits mit prägnanten Messages. Keine Secrets in den Code/Repo.
- No refactors unless asked: Keine Architektur‑Umbauten ohne Ticket/Freigabe.
- Comments: Kurze, klare Kommentare an heiklen Stellen. Keine übermäßige Doku‑Wände im Code.
- Non‑blocking TODOs: Lasse offene Punkte als `// TODO:` im Code, kein „blockiert“ ohne Rücksprache.
- Security: Keine Telemetrie/Tracker, keine externen Calls ohne Freigabe. API Keys nur aus Env/Secret Store.
