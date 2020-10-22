https://iterm2colorschemes.com/

```js
"wget '" +
  $$('a[href^="https://raw.githubusercontent.com"')
    .map(function (a) {
      if (/\.itermcolors/.test(a.href)) {
        // a.innerText "Tomorrow Night"
        return a.href;
      }
    })
    .filter(Boolean)
    .join("'\nwget '") +
  "'";
```
