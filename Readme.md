# Torrent Parrot

[![CircleCI](https://circleci.com/gh/h3nnn4n/torrential-parrot.svg?style=shield)](https://app.circleci.com/pipelines/github/h3nnn4n/torrential-parrot?branch=master)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/cbba03ee214941c7896f9137e1b01776)](https://app.codacy.com/manual/h3nnn4n/torrent-parrot?utm_source=github.com&utm_medium=referral&utm_content=h3nnn4n/torrent-parrot&utm_campaign=Badge_Grade_Dashboard)
[![codecov](https://codecov.io/gh/h3nnn4n/torrential-parrot/branch/master/graph/badge.svg)](https://codecov.io/gh/h3nnn4n/torrential-parrot)

A ruby bittorrent client, parrots included.

![](https://cultofthepartyparrot.com/parrots/hd/parrot.gif)
![](https://cultofthepartyparrot.com/parrots/hd/middleparrot.gif)
![](https://cultofthepartyparrot.com/parrots/hd/reverseparrot.gif)

This BitTorrent client is/was an exercise both on how the BitTorrent protocol
works and on ruby programming. The goals of this software are purely educational.
Feel free to contact me if you have any questions, comments, or feedback.

As of now, the client is somewhat usable. It can download files. If it is closed
all the progress will be lost. It is also very resource hungry. It can easily
make my MacBook pro scream. The download rates are also pretty bad.

For a more up to date status check the `Projects` tab of this repository.

## License

All the ruby code in this repository is released under the MIT license. See
[LICENSE](LICENSE) for full details.

Some torrent files containing data that is not of my autorship is also contained in this repository.
- `all_parrots.torrent` containts the gifs from
[cultofthepartyparrot.com](https://cultofthepartyparrot.com/), with some
folders that I used to debug folder creation.
- `archlinux.torrent` was taken from the [archlinux download
  page](https://www.archlinux.org/download/). It was used to debug some
  encoding issues.
- `debian.torrent` was taked from the [debian download page](https://www.debian.org/CD/torrent-cd/).
- `parrots.torrent` is a torrent that I created and contains two txt files.
- `pi6.torrent` contains the first 1 million digits of pi. It was used as an
  exercise of building files after downloading all the chunks. I took this file
  from the internet, but I cannot remember from where exactly.
- `potato.torrent` contains a txt file with 'potato' as its content.
