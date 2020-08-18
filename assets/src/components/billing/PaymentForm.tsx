import React from 'react';
import {Box} from 'theme-ui';
import {useStripe, useElements, CardElement} from '@stripe/react-stripe-js';
import {Button} from '../common';
import * as API from '../../api';
import CardInputSection from './CardInputSection';

const PaymentForm = () => {
  const [isSubmitting, setSubmitting] = React.useState(false);
  const stripe = useStripe();
  const elements = useElements();

  const handleSubmit = async (e: any) => {
    e.preventDefault();

    if (!stripe || !elements) {
      // Stripe.js has not yet loaded.
      return console.log('Stripe elements not found!', {stripe, elements});
    }

    const cardElement = elements.getElement(CardElement);

    if (!cardElement) {
      return console.log('Could not find card element!', {
        elements,
        cardElement,
      });
    }

    setSubmitting(true);

    const {error, paymentMethod} = await stripe.createPaymentMethod({
      type: 'card',
      card: cardElement,
    });

    if (error) {
      console.log('Failed to create payment method', error);
    } else if (paymentMethod && paymentMethod.id) {
      console.log('Payment method:', paymentMethod);

      const result = await API.createPaymentMethod(paymentMethod);
      // TODO: set payment method on account
      console.log('Successfully added payment method!', result);
    }

    setSubmitting(false);
  };

  return (
    <form onSubmit={handleSubmit}>
      <Box mb={2} sx={{maxWidth: 480}}>
        <CardInputSection />
      </Box>

      <Button
        htmlType="submit"
        type="primary"
        disabled={!stripe}
        loading={isSubmitting}
      >
        Update payment information
      </Button>
    </form>
  );
};

export default PaymentForm;
