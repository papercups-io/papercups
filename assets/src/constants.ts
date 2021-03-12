import {isEuEdition} from './config';

export const STARTER_PRICE = isEuEdition ? 7 : 0;
export const LITE_PRICE = isEuEdition ? 39 : 32;
export const TEAM_PRICE = isEuEdition ? 99 : 94;
