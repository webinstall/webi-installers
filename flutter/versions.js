"use strict";

var request = require("@root/request");

// TODO
// get list of supported platforms and archetectures
// get list of channels and versions for such
// return matching versions/channels as well as urls
// map from darwin, linux, windows

module.platforms = async function () {
  return [
    ["macos", "amd64"],
    ["linux", "amd64"],
    ["windows", "amd64"],
  ];
};

module.versions = async function (os, _arch) {
  return request({
    url:
      "https://storage.googleapis.com/flutter_infra/releases/releases_" +
      os +
      ".json",
  });
};
