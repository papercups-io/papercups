import React from 'react';
import {Box, Flex} from 'theme-ui';
import {useStripe, useElements, CardElement} from '@stripe/react-stripe-js';
import {Button, Text} from '../common';
import * as API from '../../api';
import CardInputSection from './CardInputSection';

// TODO: DRY up!
type SubscriptionPlan = 'starter' | 'team';

type Props = {
  plan?: SubscriptionPlan;
  onSuccess?: (paymentMethod: any) => void;
  onCancel?: () => void;
};

const PaymentForm = ({plan, onSuccess, onCancel}: Props) => {
  const [isSubmitting, setSubmitting] = React.useState(false);
  const [error, setErrorMessage] = React.useState('');
  const stripe = useStripe();
  const elements = useElements();

  const handleCancel = (e: any) => {
    e.preventDefault();

    if (onCancel && typeof onCancel == 'function') {
      onCancel();
    }
  };

  const handleSubmit = async (e: any) => {
    e.preventDefault();

    if (!stripe || !elements) {
      return console.error('Stripe has not loaded yet!', {stripe, elements});
    }

    const cardElement = elements.getElement(CardElement);

    if (!cardElement) {
      return console.error('Could not find card element!', {
        elements,
        cardElement,
      });
    }

    setSubmitting(true);
    setErrorMessage('');

    const {error, paymentMethod} = await stripe.createPaymentMethod({
      type: 'card',
      card: cardElement,
    });

    if (error) {
      console.error('Failed to create payment method', error);

      setErrorMessage(error.message || 'Failed to save card information.');
    } else if (paymentMethod && paymentMethod.id) {
      try {
        const result = await API.createPaymentMethod(paymentMethod);
        console.log('Successfully added payment method!', result);

        if (plan) {
          const subscription = await API.createSubscriptionPlan(plan);
          console.log('Successfully created subscription!', subscription);
        }

        onSuccess && onSuccess(result);
        cardElement.clear();
      } catch (err) {
        console.log('Failed to create payment method:', err);

        setErrorMessage(
          err?.response?.body?.error?.message ||
            err?.message ||
            'Failed to save card information.'
        );
      }
    }

    setSubmitting(false);
  };

  return (
    <form onSubmit={handleSubmit}>
      <Text strong>Credit card number</Text>

      <Flex mt={1} mb={3} sx={{alignItems: 'center'}}>
        <CardInputSection />
      </Flex>

      {error && (
        <Box my={2}>
          <Text type="danger">{error}</Text>
        </Box>
      )}

      <Flex mx={-1} sx={{alignItems: 'center', justifyContent: 'flex-end'}}>
        <Box mx={1}>
          <Button disabled={!stripe || isSubmitting} onClick={handleCancel}>
            Cancel
          </Button>
        </Box>
        <Box mx={1}>
          <Button
            htmlType="submit"
            type="primary"
            disabled={!stripe}
            loading={isSubmitting}
          >
            Update
          </Button>
        </Box>
      </Flex>
    </form>
  );
};

export default PaymentForm;
