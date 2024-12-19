'use strict';

let Fetcher = module.exports;

/**
 * @typedef ResponseSummary
 * @prop {Boolean} ok
 * @prop {Headers} headers
 * @prop {Number} status
 * @prop {String} body
 */

/**
 * @param {String} url
 * @param {RequestInit} opts
 * @returns {Promise<ResponseSummary>}
 */
Fetcher.fetch = async function (url, opts) {
  let resp = await fetch(url, opts);
  let summary = Fetcher.throwIfNotOk(resp);

  return summary;
};

/**
 * @param {Response} resp
 * @returns {Promise<ResponseSummary>}
 */
Fetcher.throwIfNotOk = async function (resp) {
  let text = await resp.text();

  if (!resp.ok) {
    let headers = Array.from(resp.headers);
    console.error('[Fetcher] error: Response Headers:', headers);
    console.error('[Fetcher] error: Response Text:', text);
    let err = new Error(`fetch was not ok`);
    Object.assign({
      status: 503,
      code: 'E_FETCH_RELEASES',
      response: {
        status: resp.status,
        headers: headers,
        body: text,
      },
    });
    throw err;
  }

  let summary = {
    ok: resp.ok,
    headers: resp.headers,
    status: resp.status,
    body: text,
  };
  return summary;
};
