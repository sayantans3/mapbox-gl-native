"use strict";

// Shim to wrap req.respond while preserving callback-passing API

var mbgl = require('../../lib/mapbox_gl_native.node');
var constructor = mbgl.Map.prototype.constructor;

var Map = function(options) {
    if (!(options instanceof Object)) {
        throw TypeError("Requires an options object as first argument");
    }

    if (!options.hasOwnProperty('request') || !(options.request instanceof Function)) {
        throw TypeError("Options object must have a 'request' method");
    }

    var request = options.request;

    return new constructor(Object.assign(options, {
        request: function(req) {
            request(req, function() {
                var args = arguments;
                // Protect ourselves from `request` implementations that try to release Zalgo.
                // http://blog.izs.me/post/59142742143/designing-apis-for-asynchrony
                setImmediate(function() {
                    req.respond.apply(req, args);
                });
            });
        }
    }));
};

Map.prototype = mbgl.Map.prototype;
Map.prototype.constructor = Map;

module.exports = Object.assign(mbgl, { Map: Map });
