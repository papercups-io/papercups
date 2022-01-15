import {isEuEdition} from './config';

export const STARTER_PRICE = isEuEdition ? 99 : 49;
export const LITE_PRICE = isEuEdition ? 149 : 99;
export const TEAM_PRICE = isEuEdition ? 299 : 249;
