
```sh
zip -r personal-spidertron_1.0.0.zip ./src/
cp personal-spidertron_1.0.0.zip ~/Library/Application\ Support/factorio/mods/
```

add symlink
```sh
ln -s /Users/brett.odonnell/Sites/factorio-personal-spidertron/src /Users/brett.odonnell/Library/Application\ Support/factorio/mods/personal-spidertron 
```

remove symlink 
```sh
rm -f /Users/brett.odonnell/Library/Application\ Support/factorio/mods/personal-spidertron
```