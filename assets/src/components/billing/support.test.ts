import {merge} from 'lodash';
import {
  getNextDueDate,
  getTrialEndDate,
  calculateSubscriptionPrice,
  calculateSubscriptionDiscount,
} from './support';

/**
 * Example subscription:
 *
 * {
 *    id: 'sub_test_id',
 *    current_period_end: 1601745400,
 *    current_period_start: 1599153400,
 *    discount: {
 *      amount_off: null,
 *      currency: null,
 *      duration: 'forever',
 *      name: 'Early Adopter',
 *      percent_off: 50,
 *      valid: true,
 *    },
 *    livemode: false,
 *    prices: [
 *      {
 *        active: true,
 *        amount_decimal: null,
 *        billing_scheme: 'per_unit',
 *        currency: 'usd',
 *        id: 'price_test_id',
 *        interval: 'month',
 *        interval_count: 1,
 *        product_id: 'prod_test_id',
 *        unit_amount: 4000,
 *      },
 *    ],
 *    quantity: 1,
 *    start_date: 1599100000,
 *    status: 'trialing',
 *    trial_end: 1601700000,
 *    trial_start: 1599100000,
 *  };
 */

const getTestSubscription = (overrides = {}) => {
  const start = +new Date('2020-06-01T12:00:00') / 1000;

  return merge(
    {
      id: 'sub_test_id',
      status: 'active',
      prices: [],
      quantity: 1,
      start_date: start,
      current_period_start: start,
    },
    overrides
  );
};

describe('getNextDueDate', () => {
  test('returns null if no subscription exists', () => {
    const subscription = null;

    expect(getNextDueDate(subscription)).toBeNull();
  });

  test('returns 1 month from the start of the current period if no trial exists', () => {
    const date = +new Date('2020-06-01T12:00:00') / 1000;
    const subscription = getTestSubscription({
      start_date: date,
      current_period_start: date,
    });

    expect(getNextDueDate(subscription)).toEqual('July 01, 2020');
  });

  test('returns 1 month from the end of the trial period', () => {
    const currentStartDate = +new Date('2020-06-01T12:00:00') / 1000;
    const trialEndDate = +new Date('2020-07-01T12:00:00') / 1000;
    const subscription = getTestSubscription({
      start_date: currentStartDate,
      current_period_start: currentStartDate,
      trial_start: currentStartDate,
      trial_end: trialEndDate,
    });

    expect(getNextDueDate(subscription)).toEqual('August 01, 2020');
  });
});

describe('getTrialEndDate', () => {
  test('returns null if no subscription exists', () => {
    const subscription = null;

    expect(getTrialEndDate(subscription)).toBeNull();
  });

  test('the next due date is in 1 month from the end of the trial period', () => {
    const currentStartDate = +new Date('2020-06-01T12:00:00') / 1000;
    const trialEndDate = +new Date('2020-07-01T12:00:00') / 1000;
    const subscription = getTestSubscription({
      start_date: currentStartDate,
      current_period_start: currentStartDate,
      trial_start: currentStartDate,
      trial_end: trialEndDate,
    });

    expect(getTrialEndDate(subscription)).toEqual('July 01, 2020');
  });
});

describe('calculateSubscriptionPrice', () => {
  test('returns 0 if no subscription exists', () => {
    const subscription = null;

    expect(calculateSubscriptionPrice(subscription)).toEqual(0);
  });

  test('returns 0 if no prices exist', () => {
    const subscription = getTestSubscription({
      prices: [],
    });

    expect(calculateSubscriptionPrice(subscription)).toEqual(0);
  });

  test('returns the total of all prices if they are valid', () => {
    const subscription = getTestSubscription({
      prices: [
        {
          active: true,
          currency: 'usd',
          interval: 'month',
          interval_count: 1,
          unit_amount: 4000,
        },
        {
          active: true,
          currency: 'usd',
          interval: 'month',
          interval_count: 1,
          unit_amount: 500,
        },
      ],
    });

    expect(calculateSubscriptionPrice(subscription)).toEqual(4500);
  });

  test('ignores inactive prices', () => {
    const subscription = getTestSubscription({
      prices: [
        {
          active: true,
          currency: 'usd',
          interval: 'month',
          interval_count: 1,
          unit_amount: 4000,
        },
        {
          active: false, // inactive
          currency: 'usd',
          interval: 'month',
          interval_count: 1,
          unit_amount: 500,
        },
      ],
    });

    expect(calculateSubscriptionPrice(subscription)).toEqual(4000);
  });
});

describe('calculateSubscriptionDiscount', () => {
  test('returns 0 if no subscription exists', () => {
    const subscription = null;

    expect(calculateSubscriptionDiscount(subscription)).toEqual(0);
  });

  test('returns 0 if no discount exist', () => {
    const subscription = getTestSubscription({
      discount: null,
    });

    expect(calculateSubscriptionDiscount(subscription)).toEqual(0);
  });

  test('handles percent_off discounts', () => {
    const subscription = getTestSubscription({
      prices: [
        {
          active: true,
          currency: 'usd',
          interval: 'month',
          interval_count: 1,
          unit_amount: 4000,
        },
      ],
      discount: {
        duration: 'forever',
        name: 'Early Adopter',
        percent_off: 50,
        valid: true,
      },
    });

    expect(calculateSubscriptionDiscount(subscription)).toEqual(2000);
  });

  test('handles amount_off discounts', () => {
    const subscription = getTestSubscription({
      prices: [
        {
          active: true,
          currency: 'usd',
          interval: 'month',
          interval_count: 1,
          unit_amount: 4000,
        },
      ],
      discount: {
        amount_off: 1000,
        currency: 'usd',
        duration: 'forever',
        name: 'Early Adopter',
        valid: true,
      },
    });

    expect(calculateSubscriptionDiscount(subscription)).toEqual(3000);
  });
});
