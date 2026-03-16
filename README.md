# LMS Dashboard

Single page dashboard app for [Lyrion Music Server](https://lyrion.org/) (formerly known as Logitech Media Server and Squeezebox Server).

It displays a list of all players connected to your server with wifi signal strength and two buttons per player.

One button power toggle for each player.  Power on also issues a restart of the currently queued song, regardless of player power on setting defined on the server for the player (because if I'm using the app, I want to hear the music, but I have the default server setting to remain stopped on power up since the players don't know the difference between being manually powered on and being powered up after a power outage in the middle of the night).

It has no music content/library searching/queuing/playlist/management -- [Squeezer](https://github.com/kaaholst/android-squeezer) is the app for that.

Squeezebox Touch players can be rebooted if they have telnet service enabled.  Community firmware released in 2024 disables telnet by default, replaced with SSH.  To restore telnet:
- SSH into the device with username `root` and password `1234`
- `cd /etc`
- `vi inetd.conf`
- find and goto `telnet` in the list
- uncomment `telnet` (`x :w :q`)
- `reboot`

Why would you want to reboot a Squeezebox Touch? 

In my case, the players occassionally choke on 24-bit audio when the wifi signal is interrupted.  Upon interruption of 24-bit audio, the players get into a state of:
- playing about 5 seconds of audio
- pausing play for 2-4 seconds to rebuffer additional audio
- repeat until end of song, no problem for remaining 24-bit audio in playlist

Why not restart the server? 

Restarting the server impacts all connected players whereas rebooting the player only affects the one player and the server maintains the playlist.  Upon player reboot, the player continues playing the song without further interruption.  When using random mix playlists, restarting the server instead of rebooting the player causes the active playlist to be reset -- so the song that was afflicted by the rebuffering loop is no longer queued after server restart.

I don't know why the players stop rebuffering 24-bit audio during play once an interruption occurs.  So, I learned a little [Dart](https://dart.dev/) and [Flutter](https://flutter.dev/) to write an Android app to workaround the problem.
