import React from 'react';
import {Flex} from 'theme-ui';
import {useStripe, useElements, CardElement} from '@stripe/react-stripe-js';
import {Button, Text} from '../common';
import * as API from '../../api';
import CardInputSection from './CardInputSection';

type Props = {
  onSuccess?: (paymentMethod: any) => void;
};

const PaymentForm = ({onSuccess}: Props) => {
  const [isSubmitting, setSubmitting] = React.useState(false);
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

    const {error, paymentMethod} = await stripe.createPaymentMethod({
      type: 'card',
      card: cardElement,
    });

    if (error) {
      console.error('Failed to create payment method', error);
    } else if (paymentMethod && paymentMethod.id) {
      const result = await API.createPaymentMethod(paymentMethod);
      console.log('Successfully added payment method!', result);

      onSuccess && onSuccess(result);
    }

    setSubmitting(false);
  };

  return (
    <form onSubmit={handleSubmit}>
      <Text strong>Update payment information</Text>

      <Flex mt={1} mb={2} sx={{maxWidth: 480, alignItems: 'center'}}>
        <CardInputSection />
      </Flex>

      <Button
        htmlType="submit"
        type="primary"
        disabled={!stripe}
        loading={isSubmitting}
      >
        Update
      </Button>
    </form>
  );
};

export default PaymentForm;
