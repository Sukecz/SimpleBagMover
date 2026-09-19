# Simple Bag Mover

A lightweight Blizzard bag mover for **WoW Forever only**, pilot version 0.1.2.
Drag the title area of an open bag to move it. Positions are saved per character
and logical bag slot across closing/reopening, logout and `/reload`.

- `/sbm lock` — disable dragging; saved positions remain active.
- `/sbm unlock` — enable dragging (default).
- `/sbm reset` — clear saved positions and restore Blizzard layout.
- `/sbm debug` — print client and hook diagnostics.

No libraries, item automation or bag replacement. Bank bags are outside this pilot's
scope. Combined bag support is capability-based and still needs live verification.
Moving and restoring positions is suspended during combat and resumed afterward.
Screen-relative positions adapt to resolution/UI scale; frames are clamped on screen.

## Development and deployment

Run `bash tests/run.sh`. Run `bash tools/deploy.sh` only when deployment is authorized.
The deploy script tests, packages, copies and hash-verifies the runtime files and addon-list icon in
`C:\Games\World of Warcraft\_classic_beta_\Interface\AddOns\SimpleBagMover`.
It does not deploy to Era/Anniversary or touch WTF/SavedVariables.
Restart WoW on first installation so it discovers the new addon.

Interface 16001/Camelot matches the local Forever addon metadata. Layout integration
was checked against Blizzard UI source mirrored at Gethe/wow-ui-source,
classic_beta commit 4d9399a664eb65f2c8d5e96d7a6bf5e234414239, Classic/ContainerFrame_Shared.lua.
This source inspection and simulated Lua tests do not establish live Forever compatibility.

## In-game pilot acceptance

1. Open bags; drag two bags to different positions.
2. Close and reopen in a different order; positions must follow each bag.
3. Run `/reload`, then log out/in; positions must persist.
4. Open all bags and the bank; verify no permanent layout reset.
5. Lock/unlock; check normal item clicks, sorting, tooltips and close buttons.
6. Enter/leave combat; verify positions recover and no blocked-action errors occur.
7. Change UI scale; confirm bags remain reachable. Test `/sbm reset`.

Live client results are pending. For an error, capture the first Lua error and `/sbm debug`.

Version 0.1.1 places the drag handle outside the portrait button and passes right
clicks through to Blizzard controls. Version 0.1.0 movement was user-confirmed;
this context-menu fix still needs in-game confirmation.

Version 0.1.2 renames the addon from MoveBags to Simple Bag Mover. Existing saved
positions are imported automatically from `MoveBagsDB`.
