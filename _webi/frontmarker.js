'use strict';

var fs = require('fs');
var marked = require('marked').marked;

var frontmatter = '---';
var keyValRe = /(\w+): (.*)/;

function parseYamlish(txt) {
  var end = false;
  var cfg = { title: '', tagline: '', description: '', examples: '' };
  var block = false;

  var lines = txt.trim().split('\n');
  var last;

  if (frontmatter !== lines.shift()) {
    throw new Error('no frontmatter marker at beginning of file');
  }

  function unblock() {
    cfg[block] = marked.parse(cfg[block]);
    block = false;
  }

  lines.some(function (line, i) {
    if (frontmatter === line) {
      // end of frontmatter
      end = true;
      return;
    }

    if (end) {
      if (line.trim()) {
        throw new Error('missing newline after frontmatter');
      }
      last = i;
      return true;
    }

    if (!line[0]) {
      if (block) {
        cfg[block] += '\n';
      } else {
        throw new Error('invalid blank line in frontmatter');
      }
    }

    if (block) {
      if (!line || '  ' === line.slice(0, 2)) {
        cfg[block] += line.slice(2) + '\n';
        return;
      }
      unblock();
    }

    var m = line.match(keyValRe);
    if (!m) {
      throw new Error(
        'invalid key format for: ' + JSON.stringify(line) + ' ' + i,
      );
    }
    if ('|' === m[2]) {
      block = m[1];
      return;
    }
    cfg[m[1]] = m[2];
  });

  if (block) {
    cfg[block] = marked.parse(cfg[block]);
  }
  cfg.examples = marked.parse(lines.slice(last).join('\n'));

  return cfg;
}

module.exports.parse = parseYamlish;

if (require.main === module) {
  console.info(
    parseYamlish(fs.readFileSync(__dirname + '/../node/README.md', 'utf8')),
  );
}
