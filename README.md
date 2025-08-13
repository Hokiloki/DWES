## DWES – Digital World Engine Sand

Digital World Engine Sand (Sandbox-Worldmap für TTRPG-Gruppen).
**Status:** MVP in Arbeit.

### Projektübersicht

DWES ist ein interaktives Karten- und Weltsimulations-Tool für das Tabletop-RPG Kantaraya. Es ermöglicht Spielern und Spielleitern nahtloses Erkunden, Planen und Verwalten einer zusammenhängenden Fantasywelt – sowohl bei in-person Spielrunden als auch online.

### Zielplattformen

- Windows
- iOS
- Android
- Cross-Platform-Sync zwischen allen Plattformen

### Technische Architektur

- **Engine:** Godot 4.4 mit GDScript
- **Networking:** Host/Client-Modell über Godot High-Level Multiplayer API (ENet)
- **Host validiert** alle Aktionen (z.B. Marker-Setzen)
- **Echtzeit-Sync** mit minimalem Delay

### Map- & Datenstruktur

- **Weltkarte:** Tilemap mit Chunks für effizientes Laden/Zoomen (4096×2048)
- **Fog of War:** Layer-basiert
  - Layer 0: kein Fog
  - Layer 1: Fog mit Radius
  - Layer 2: Detailkarte ohne Fog
- **Biome-Layer:** statisch mit 6–10 Farbcodes
- **Welt-Saves:** Zentrale Basiswelt + pro Gruppe separate Datei mit individuellen Markern, Fog-Status, POIs

### Barrieren-System (Hard Gates)

- Gesperrte Bereiche in Begehbarkeits-Maske
- Spieler können diese Zonen nicht betreten oder Marker setzen
- Visuelles Overlay "Coming Soon" für gesperrte Gebiete

### Startassets (vom Projektowner bereitgestellt)

- Platzhalter-Weltkarte (PNG, 4096×2048)
- Biome-Liste mit Farbcodes
- Platzhalter-POIs (Testdaten)
- Begehbarkeits-Maske (1-Bit-Image, 1 = begehbar, 0 = gesperrt)

### MVP-Entwicklungsreihenfolge

1. ✅ Weltkarte laden & anzeigen (Zoom + Pan)
2. 🔄 Marker setzen, bewegen, löschen (Multiplayer-Sync)
3. 🔄 Fog of War Layer 1 mit Erkundungsradius
4. 🔄 Biome-Layer umschaltbar
5. 🔄 Gruppenbasierte Welt-Saves

### Aktueller Entwicklungsstand

**Implementierte Systeme:**

- GameManager - Zentrale Spielzustandsverwaltung
- NetworkManager - Multiplayer mit Host/Client-Architektur
- MapSystem - Weltkarte mit Zoom/Pan
- FogOfWarSystem - Layer-basiertes Fog of War
- MarkerSystem - Multiplayer-Marker (Grundstruktur)
- SaveSystem - Gruppenbasierte Speicherung

**Offene TODOs:**

- [ ] Visuelle Implementierung der Marker
- [ ] Laden der echten Weltkarten-Textur
- [ ] Implementierung des Barrieren-Systems (Hard Gates)
- [ ] Chunk-basiertes Laden für Performance-Optimierung
- [ ] UI-Verbesserungen (Join-Dialog, etc.)

### Entwickler-Richtlinien

- Kleine, abgeschlossene Schritte (Feature-für-Feature)
- Minimum Change Possible
- Klare Commits mit beschreibenden Messages
- Keine hardcodierten sensiblen Daten
- Host validiert alle Multiplayer-Aktionen
