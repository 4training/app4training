# Launch Screen Assets

The three `LaunchImage*.png` files are the app logo at 127pt (1x/2x/3x),
generated from `../AppIcon.appiconset/4training logo_1024x1024.png` with the
white corners made transparent (so it also works on the dark launch
background, see `../LaunchBackground.colorset`). 127pt matches the logo size
of the Android splash screen (`android/app/src/main/res/values/dimens.xml`).

To regenerate after changing the logo, resize the transparent-corner source
to 127, 254 and 381 px and replace the files here; `Contents.json` needs no
change as long as the file names stay the same.
