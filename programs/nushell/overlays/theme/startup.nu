# Sourced from config.nu. `source` needs a parse-time const path, and env.nu's
# `theme write-startup` wrote the target before this file was parsed.
const nu_theme_active_file = $nu.data-dir | path join "theme-active.nu"
source $nu_theme_active_file

# Record the boot polarity so the pre_prompt hook only re-themes on a flip.
$env.NU_THEME_ACTIVE = (theme resolve)
$env.NU_THEME_ACTIVE_POLARITY = (theme detect-polarity)
$env.config.hooks.pre_prompt = (
  $env.config.hooks.pre_prompt? | default [] | append {|| theme sync }
)

# A string hook is parsed when it runs, so this `source` reads the snippet as
# `theme sync` just wrote it. env_change hooks run after pre_prompt in the same
# cycle. The counter is unset at boot, so the first prompt does not fire it.
$env.config.hooks.env_change.NU_THEME_GENERATION = (
  $env.config.hooks.env_change.NU_THEME_GENERATION?
  | default []
  | append $"source '($nu_theme_active_file)'"
)
