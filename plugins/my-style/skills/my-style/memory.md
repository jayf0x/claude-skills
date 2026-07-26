# My React style — memory

Preset rules. Not laws — apply with judgment, note when you deviate and why.

- **Index files split by role.** At a feature boundary, `index.tsx` may act as a
  *Router*: it can hold real logic, but as little as possible. Inside a feature,
  sub-component `index.tsx` files are *Switches*: dumb, no logic. Don't let Router
  behavior spread past the feature boundary — that's just a barrel file with extra
  steps.
- **Colocate small placeholders.** A small extra component may live in the same file
  as the component that owns it, if its footprint stays small. When it grows, split
  it out.
- **Ownership order, top to bottom:** main component first, then the pieces it calls,
  in the order it calls them (newspaper/stepdown style). Extracted/placeholder
  components go at the *bottom* of the file so the main component keeps top billing.
- **Hooks order:** state and derived values first, event handlers next, `useEffect`
  calls last — effects are a last resort and run after everything else has settled,
  so they read last too.
- Don't apply Router/Switch, colocation, or ordering rules dogmatically. If a case
  fights the rule, follow the case and flag it as a candidate for `/my-style add`.

See `.keep/react-code/iteration-1.md` in claude-skills for the sourcing behind these.
