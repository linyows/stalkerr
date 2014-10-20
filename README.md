Stalkerr
========

[![Gem Version](https://badge.fury.io/rb/stalkerr.png)][gem]
[![Build Status](https://secure.travis-ci.org/linyows/stalkerr.png?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/linyows/stalkerr.png?travis)][gemnasium]
[![Code Climate](https://codeclimate.com/github/linyows/stalkerr.png)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/linyows/stalkerr/badge.png?branch=master)][coveralls]

[gem]: https://rubygems.org/gems/stalkerr
[travis]: http://travis-ci.org/linyows/stalkerr
[gemnasium]: https://gemnasium.com/linyows/stalkerr
[codeclimate]: https://codeclimate.com/github/linyows/stalkerr
[coveralls]: https://coveralls.io/r/linyows/stalkerr

Stalkerr is IRC Gateway, inspired by [agig](https://github.com/hsbt/agig) and [atig](https://github.com/mzp/atig).

![The Shining](http://goo.gl/7JPKQ)

Installation
------------

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install octospy
```

Usage
-----

Start Stalkerr

```sh
$ stalkerr -D
```

Join channel with username and access_token

```irc
/join #github <username>:<access_token>
```

If use GitHub:Enterprise

```sh
$ env GITHUB_ENTERPRISE_API_ENDPOINT="http://your.enterprise.domain/api/v3/" \
> env GITHUB_ENTERPRISE_WEB_ENDPOINT="http://your.enterprise.domain/" \
> stalkerr -D
```

Support Service

- GitHub
- GitHub:Enterprise
- Qiita
- ~~twitter~~
- ~~facebook~~

Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Author
------

- [linyows](https://github.com/linyows)

License
-------

The MIT License (MIT)
