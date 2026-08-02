# Ensure an ed25519 SSH key exists, generating one if absent and copying the
# public half back into the nix-config repo for this host. No-op when the key
# already exists, so a committed pubkey is never clobbered.
def main [
  --home: string    # user home directory
  --user: string    # username, used for the key comment
  --host: string    # host name, selects the repo pubkey dir
  --repo: string    # path to the nix-config checkout
] {
  let key = $"($home)/.ssh/id_ed25519"
  if ($key | path exists) { return }

  let ssh_dir = $"($home)/.ssh"
  mkdir $ssh_dir
  ^chmod 700 $ssh_dir
  ^ssh-keygen -t ed25519 -N "" -C $"($user)@($host)" -f $key

  let dest = $"($repo)/host/($host)/ssh"
  if ($dest | path dirname | path exists) {
    mkdir $dest
    cp $"($key).pub" $"($dest)/id_ed25519.pub"
    print $"Copied new pubkey into ($dest)/id_ed25519.pub - commit it to the repo."
  } else {
    print $"Generated ($key); repo host dir ($dest | path dirname) missing, skipped copy."
  }
}
