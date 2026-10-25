# Forkcast design assets

Exported from the Claude Design canvas "Forkcast app redesign"
(https://claude.ai/artifact/2gE4kXZa8PyoY14xHQuTnJ).

- `tokens.json` — the Forkcast design system: colors (light + dark), type
  scale, spacing, radius, shadows, sizes and motion. **Source of truth.**
  Hand-copied into `mobileapp/lib/theme/tokens.dart` and
  `flaskServer/static/tokens.css`; change it here first.
- `bundle.css`, `forkcast-app.css` — the design system's component CSS. The
  website's `components.css` is ported from these.
- `forkcast-mark.svg`, `forkcast-icon-light.svg`, `forkcast-icon-dark.svg` —
  logo mark and app icons.
- `redesign-plan.md` — the phased plan for bringing the design into the app
  and website.

Fonts: Plus Jakarta Sans (SIL Open Font License, see `OFL.txt` next to each
copy). Icons: Phosphor (MIT), via `phosphor_flutter` in the app.
