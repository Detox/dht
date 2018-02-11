# Detox DHT
Recompiled webtorrent-dht for Detox's purposes

Essentially [webtorrent-dht](https://github.com/nazar-pc/webtorrent-dht) with following tweaks for Detox project:
* `bencode`, `simple-peer`, `webrtc-socket`, `webtorrent-dht` and `Buffer` are exported explicitly instead of just `webtorrent-dht` (in order to avoid loading loading the rest twice in browser)
* `simple-sha1` excluded from build, since Detox uses different hash function

## Contribution
Feel free to create issues and send pull requests (for big changes create an issue first and link it from the PR), they are highly appreciated!

## License
Free Public License 1.0.0 / Zero Clause BSD License

https://opensource.org/licenses/FPL-1.0.0

https://tldrlegal.com/license/bsd-0-clause-license
