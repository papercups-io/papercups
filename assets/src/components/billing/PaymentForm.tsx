import React from 'react';
import {Box, Flex} from 'theme-ui';
import {useStripe, useElements, CardElement} from '@stripe/react-stripe-js';
import {Button, Text} from '../common';
import * as API from '../../api';
import CardInputSection from './CardInputSection';

type Props = {
  onSuccess?: (paymentMethod: any) => void;
};

const PaymentForm = ({onSuccess}: Props) => {
  const [isSubmitting, setSubmitting] = React.useState(false);
  const [error, setErrorMessage] = React.useState('');
  const stripe = useStripe();
  const elements = useElements();

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
      <Text strong>Update payment information</Text>

      <Flex mt={1} mb={2} sx={{maxWidth: 480, alignItems: 'center'}}>
        <CardInputSection />
      </Flex>

      <Flex sx={{alignItems: 'center'}}>
        <Button
          htmlType="submit"
          type="primary"
          disabled={!stripe}
          loading={isSubmitting}
        >
          Update
        </Button>

        {error && (
          <Box ml={3}>
            <Text type="danger">{error}</Text>
          </Box>
        )}
      </Flex>
    </form>
  );
};

export default PaymentForm;
