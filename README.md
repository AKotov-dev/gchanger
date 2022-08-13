# GChanger - GRUB theme Changer for Mageia Linux

**Dependencies:** gtk2 polkit grub2-mageia-theme  
  
The program is designed to easily replace the GRUB theme.

Opportunities:
--
+ contains 32 preset themes for various screen resolutions (1080p/2k/4k)
+ allows you to download new themes from external directories, delete themes, change the background (png, jpeg, jpg)
+ sets the selected timeout (pause until the system boots)
+ allows you to roll back to the original Mageia settings (`maggy` theme)
+ when you delete the rpm package, the theme settings automatically return to the `maggy` theme (`1024x768x32`)

In addition to those already present, you can install other themes. You can download [GRUB2 themes here](https://www.gnome-look.org/browse?cat=109&ord=latest). You need to download and unpack the theme archive. To load a theme, click the `Load` button and open the unpacked theme directory, which contains the file `theme.txt`. To install the theme, click the `Apply` button. If the background, screen resolution or pause has changed, you should click the `Apply` button again.

Recommendations:
--
+ When replacing the theme background, try to choose a picture of dark tones and with less detail
+ If the system was installed on EFI, when specifying the screen resolution, it makes sense to press the `S` button

Disclaimer: The program is provided `As Is`. The author is not responsible for your actions. Be careful when specifying parameters and settings.

**Similar programs:** [PChanger](https://github.com/AKotov-dev/pchanger) - Plymouth changer: quickly change the system boot screen.
  
![](https://github.com/AKotov-dev/gchanger/blob/main/ScreenShots/gchanger1.png)  
  
![](https://github.com/AKotov-dev/gchanger/blob/main/ScreenShots/gchanger3.png)
