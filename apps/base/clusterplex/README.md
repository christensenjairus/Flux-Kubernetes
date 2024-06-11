# Setup Instructions
* Log in using a port-forward
* Network Settings
  * Disable support for IPv6
  * Add `10.0.0.0/255.0.0.0` as the LAN network
  * Terminate sessions paused longer than `30` mins
  * Add custom server access URL `https://clusterplex.christensencloud.us`
* Transcode Settings
  * Set as `/transcode`
  * Raise 'Transcoder default throttle buffer' to `180`
  * Disable all hardware acceleration
* Remote Access:
  * Enable
  * Manually specify port if necessary