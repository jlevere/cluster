## This is about creating and using anunattened.xml file to create fully automated windows installs.

Most of this is based on the awesome project [dockur/windows](https://github.com/dockur/windows). This project has a ton of prewritten [answer](https://github.com/dockur/windows/tree/master/assets) files in the assets directory that are great starting places, and sometimes all that you need for an install.

These answer files can be manually edited with your favorite xml editor like vscode, or you can use the [Windows System Image Manager](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install) toolkit that is super helpful with a nice GUI.

The tool likes to have a window image file, a *.wim* or *.clg* file, which are bundled in the normal install ISO files.  You can download windows ISO install media using a tool such as [Midos](https://github.com/ElliotKillick/Mido), or through other means.
