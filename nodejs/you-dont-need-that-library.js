// Collection of useful snippets. All of them require node v4.

// Converts a node-style async function with a callback as last argument
// to a function returning a promise.
function promisify(nodefunc) {
    return function() { return new Promise((accept, reject) => {
        nodefunc.apply(this, [].slice.call(arguments).concat(
            (error, result) => {
                if (error) reject(error);
                else accept(result);
            }));
    }); };
}

// Emulate async/await using generators.
// usage:
//      const my_async_fun = async(function*(...) {
//          ...
//          try {
//              let result = yield a_promise;
//          } catch (e) {
//              ...
//          }
//          ...
//          return something;
//      })
function async(gfunc) {
    return function() {
        let g = gfunc.apply(this, arguments);
        try {
            return (function reinject(r) {
                if (r.done) return Promise.resolve(r.value);
                else return Promise.resolve(r.value).then(
                    (val) => reinject(g.next(val)),
                    (err) => reinject(g.throw(err)));
            })(g.next());
        } catch (err) {
            return Promise.reject(err);
        }
    }
}

function downloadfile(url, dest) {
    return new Promise((accept, reject) => {
        var file = fs.createWriteStream(dest);
        var request = https.get(url, function(response) {
            response.pipe(file);
            file.on('finish', function() {
                file.close();
                accept(null);
            });
        }).on('error', function(err) { // Handle errors
            fs.unlink(dest); // Delete the file async. (But we don't check the result)
            reject(err.message);
        });
    });
}
