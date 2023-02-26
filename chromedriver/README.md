---
title: ChromeDriver
homepage: https://chromedriver.chromium.org
tagline: |
  ChromeDriver: WebDriver for Chrome
---

To update or switch versions, run `webi chromedriver@stable` (or `@v2`, `@beta`,
etc).

## Cheat Sheet

> WebDriver is an open source tool for automated testing of webapps across many
> browsers. ChromeDriver is a WebDriver created by the Chromium (Google Chrome)
> team - for Selenium and such.

You probably won't run `chromedriver` manually, but it must be installed for
some testing frameworks.

Also, **Chrome must be installed first** in order for ChromeDriver to work.

### How to Install Chrome on Linux

On Debian (and Ubuntu) Linux you should be able to install Chrome with `dpkg`
and `apt`:

```sh
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt install -y google-chrome-stable
sudo apt --fix-broken install -y
```

You may get an error like this:

```text
chromedriver: error while loading shared libraries: libnss3.so: cannot open shared object file: No such file or directory
```

If so, try installing `chromium-browser`:

```sh
sudo apt install -y chromium-browser
sudo apt --fix-broken install -y
```

### Other Notes

On Windows `chromedriver.exe` _should_ Just Work&trade;.

On macOS you may need to install XCode Command Line Tools with
`xcode-select --install`.
