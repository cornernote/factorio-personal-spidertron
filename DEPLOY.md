
```sh
zip -r personal-spidertron_1.0.0.zip ./src/
cp personal-spidertron_1.0.0.zip ~/Library/Application\ Support/factorio/mods/
```

add symlink
```sh
ln -s ~/Sites/factorio-personal-spidertron/src ~/Library/Application\ Support/factorio/mods/personal-spidertron 
```

remove symlink 
```sh
rm -f ~/Library/Application\ Support/factorio/mods/personal-spidertron
```