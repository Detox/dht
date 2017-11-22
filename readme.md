# detox-dht
Recompiled webtorrent-dht for Detox's purposes

Essentially [webtorrent-dht](https://github.com/nazar-pc/webtorrent-dht) with following tweaks for Detox project:
* `bencode`, `simple-peer`, `webrtc-socket`, `webtorrent-dht` and `Buffer` are exported explicitly instead of just `webtorrent-dht` (in order to avoid loading loading the rest twice in browser)
* `simple-sha1` excluded from build, since Detox uses different hash function

## Contribution
Feel free to create issues and send pull requests (for big changes create an issue first and link it from the PR), they are highly appreciated!

## License
MIT, see license.txt
