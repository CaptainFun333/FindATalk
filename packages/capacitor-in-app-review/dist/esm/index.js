import { registerPlugin } from '@capacitor/core';
const InAppReview = registerPlugin('InAppReview', {
    web: () => import('./web').then((m) => new m.InAppReviewWeb()),
});
export * from './definitions';
export { InAppReview };
//# sourceMappingURL=index.js.map