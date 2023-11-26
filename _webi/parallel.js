'use strict';

var Parallel = module.exports;
Parallel.run = async function (limit, arr, fn) {
  let index = 0;
  let actives = [];
  let results = [];
  limit = Math.min(limit, arr.length);

  function launch() {
    let _index = index;
    let p = fn(arr[_index], _index, arr);

    // some tasks may be synchronous
    // so we must push before removing
    actives.push(p);

    p.then(function _resolve(result) {
      let i = actives.indexOf(p);
      actives.splice(i, 1);
      results[_index] = result;
    });

    index += 1;
  }

  // start tasks in parallel, up to limit
  for (; actives.length < limit; ) {
    launch();
  }

  // keep the task queue full
  for (; index < arr.length; ) {
    // wait for one task to complete
    await Promise.race(actives);
    // add one task again
    launch();
  }

  // wait for all remaining tasks
  await Promise.all(actives);

  return results;
};
