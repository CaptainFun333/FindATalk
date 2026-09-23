'use strict';

var core = require('@capacitor/core');

const InAppReview = core.registerPlugin('InAppReview', {
    web: () => Promise.resolve().then(function () { return web; }).then((m) => new m.InAppReviewWeb()),
});

class InAppReviewWeb extends core.WebPlugin {
    async requestReview() {
        throw this.unimplemented('Not implemented on web.');
    }
}

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    InAppReviewWeb: InAppReviewWeb
});

exports.InAppReview = InAppReview;
//# sourceMappingURL=plugin.cjs.js.map
