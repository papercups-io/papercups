import React from 'react';
import {Box} from 'theme-ui';
import {Elements} from '@stripe/react-stripe-js';
import {loadStripe} from '@stripe/stripe-js';
import {Paragraph, Text, Title} from '../common';
import PaymentForm from './PaymentForm';

const stripe = loadStripe(
  process.env.REACT_APP_STRIPE_PUBLIC_KEY || 'pk_test_xxxxx'
);

type Props = {};
type State = {};

class BillingOverview extends React.Component<Props, State> {
  render() {
    return (
      <Box p={4}>
        <Box mb={5}>
          <Title level={3}>Billing Settings</Title>
          <Paragraph>
            <Text>
              Manage your payment information here
              <span role="img" aria-label="$">
                🏦
              </span>
            </Text>
          </Paragraph>

          <Elements stripe={stripe}>
            <PaymentForm />
          </Elements>
        </Box>
      </Box>
    );
  }
}

export default BillingOverview;
