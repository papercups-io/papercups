import {capitalize} from 'lodash';
import dayjs from 'dayjs';

export type SubscriptionPlan = 'starter' | 'team';

export type CreditCardBrand =
  | 'amex'
  | 'cartes_bancaires'
  | 'diners_club'
  | 'discover'
  | 'jcb'
  | 'mastercard'
  | 'visa'
  | 'unionpay'
  | string;

export type Subscription = {
  id: string;
  status: string;
  current_period_end?: number;
  current_period_start?: number;
  days_until_due?: number;
  discount?: any;
  livemode?: boolean;
  prices: Array<any>;
  quantity: number;
  start_date: number;
  trial_end?: number;
  trial_start?: number;
};

export const getBrandName = (brand: CreditCardBrand) => {
  switch (brand) {
    case 'visa':
      return 'Visa';
    case 'mastercard':
      return 'MasterCard';
    case 'amex':
      return 'American Express';
    case 'discover':
      return 'Discover';
    case 'unionpay':
      return 'UnionPay';
    case 'diners_club':
      return 'Diners Club';
    case 'cartes_bancaires':
      return 'Cartes Bancaires';
    case 'jcb':
      return 'JCB';
    default:
      return brand
        .split('_')
        .map((str) => capitalize(str))
        .join(' ');
  }
};

export const getPlanInfo = (plan: SubscriptionPlan) => {
  switch (plan) {
    case 'team':
      return {
        name: 'Team plan',
        includes: [
          {feature: '5 seats'},
          {feature: 'Unlimited messages'},
          {feature: 'Slack integration'},
          {feature: 'Webhooks'},
        ],
      };
    case 'starter':
    default:
      return {
        name: 'Starter plan',
        includes: [
          {feature: '2 seats'},
          {feature: '100,000 messages'},
          {feature: 'Slack integration'},
        ],
      };
  }
};

type SubscriptionUsage = {
  numUsers?: number;
  numMessages?: number;
};

export const shouldRequirePlanUpdate = (
  plan: SubscriptionPlan,
  usage: SubscriptionUsage
) => {
  const {numUsers = 1, numMessages = 0} = usage;

  switch (plan) {
    case 'starter':
      return numUsers > 2 || numMessages > 100000;
    case 'team':
    default:
      return false;
  }
};

export const getFirstOfNextMonth = () => {
  return dayjs().startOf('month').add(1, 'month').format('MMM DD');
};

export const getNextDueDate = (subscription: Subscription | null) => {
  if (!subscription || !subscription.current_period_start) {
    return null;
  }

  const {
    current_period_start: currentPeriodStart,
    trial_end: trialEndsAt,
  } = subscription;
  const date = dayjs(new Date((trialEndsAt || currentPeriodStart) * 1000));

  return date.add(1, 'month').format('MMMM DD, YYYY');
};

export const getTrialEndDate = (subscription: Subscription | null) => {
  if (!subscription || !subscription.trial_end) {
    return null;
  }

  const {trial_end: trialEndsAt} = subscription;
  const date = dayjs(new Date(trialEndsAt * 1000));

  return date.format('MMMM DD, YYYY');
};

export const calculateSubscriptionPrice = (
  subscription: Subscription | null
) => {
  if (!subscription || !subscription.prices) {
    return 0;
  }

  const {prices = []} = subscription;

  return prices.reduce((total: number, price: any) => {
    const {
      active,
      currency,
      interval,
      interval_count: intervalCount,
      unit_amount: amount = 0,
    } = price;
    const isValidPrice =
      currency.toLowerCase() === 'usd' &&
      interval === 'month' &&
      intervalCount === 1;

    if (!isValidPrice) {
      throw new Error(`Unrecognized price: ${JSON.stringify(price)}`);
    }

    if (active) {
      return total + amount;
    }

    return total;
  }, 0);
};

export const calculateSubscriptionDiscount = (
  subscription: Subscription | null
) => {
  if (!subscription || !subscription.discount) {
    return 0;
  }

  const total = calculateSubscriptionPrice(subscription);

  if (!total) {
    return 0;
  }

  const {discount = {}} = subscription;
  const {
    percent_off: percentOff,
    amount_off: amountOff,
    currency,
    valid,
  } = discount;

  if (!amountOff && !percentOff) {
    return 0;
  }

  const isValidCurrency = currency ? currency.toLowerCase() === 'usd' : true;

  if (!valid || !isValidCurrency) {
    throw new Error(`Invalid discount: ${JSON.stringify(discount)}`);
  }

  if (amountOff) {
    return total - amountOff;
  } else if (percentOff) {
    return total * (percentOff / 100);
  } else {
    return 0;
  }
};
