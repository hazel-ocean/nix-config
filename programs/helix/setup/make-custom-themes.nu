def main [ themeDir: path, destinationDir: path ] {
  ls $themeDir
  | get name
  | path parse
  | where extension == "toml"
  | get stem
  | each {|theme|
    let destination = [
        $destinationDir
        $"_($theme).toml"
      ]
      | path join

    print $"Creating a new theme for ($theme) at `($destination)`"

    let contents = [
        $"inherits = \"($theme)\""
        ""
        "[\"ui.background\"]"
      ]
      | str join "\n"

    print $"Contents:\n($contents)"

    $contents | save $destination --force

    print "Success!"
  }

  print "\nAll done!"
}
