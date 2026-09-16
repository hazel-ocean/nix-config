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
