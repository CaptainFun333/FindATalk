import { WebPlugin } from '@capacitor/core';
import type { InAppReviewPlugin } from './definitions';
export declare class InAppReviewWeb extends WebPlugin implements InAppReviewPlugin {
    requestReview(): Promise<void>;
}
