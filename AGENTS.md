# Simple Bag Mover

- Lightweight English-only Blizzard bag mover for WoW Forever (Camelot), only.
- Preserve Blizzard inventory behavior. No item-button hooks or gameplay automation.
- Save positions per character and logical bag ID, never pooled frame name.
- Use secure post-hooks; defer layout mutations during combat.
- Run `bash tests/run.sh` before deployment.
- `tools/deploy.sh` is the dedicated Forever-only deploy entry point.
- The user has granted standing authorization to run `tools/deploy.sh` automatically after every verified Simple Bag Mover source change.
- Deployment must preserve WTF/SavedVariables and unrelated addons. No publishing without authorization.
