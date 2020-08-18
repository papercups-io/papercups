import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Elements} from '@stripe/react-stripe-js';
import {loadStripe} from '@stripe/stripe-js';
import * as API from '../../api';
import {colors, Paragraph, Text, Title} from '../common';
import {CreditCardTwoTone} from '../icons';
import Spinner from '../Spinner';
import PaymentForm from './PaymentForm';

const stripe = loadStripe(
  process.env.REACT_APP_STRIPE_PUBLIC_KEY || 'pk_test_xxxxx'
);

type Props = {};
type State = {
  loading: boolean;
  defaultPaymentMethod: any;
};

class BillingOverview extends React.Component<Props, State> {
  state = {loading: true, defaultPaymentMethod: null};

  async componentDidMount() {
    const defaultPaymentMethod = await API.fetchDefaultPaymentMethod();

    this.setState({defaultPaymentMethod, loading: false});
  }

  handleUpdatePaymentMethod = (paymentMethod: any) => {
    this.setState({defaultPaymentMethod: paymentMethod});
  };

  formatPaymentMethodInfo = (paymentMethod?: any) => {
    if (!paymentMethod) {
      return (
        <Flex sx={{alignItems: 'center', my: 1}}>
          <Text type="secondary">None</Text>
        </Flex>
      );
    }

    const {last4, exp_month, exp_year} = paymentMethod;

    return (
      <Flex sx={{alignItems: 'center', my: 1}}>
        <Box mr={2}>
          <CreditCardTwoTone twoToneColor={colors.primary} />
        </Box>
        <Text keyboard style={{letterSpacing: 0.6}}>
          ••••••••••••{last4}
        </Text>
        <Box ml={2}>
          <Text type="secondary">
            expires {exp_month}/{exp_year}
          </Text>
        </Box>
      </Flex>
    );
  };

  render() {
    const {loading, defaultPaymentMethod} = this.state;

    if (loading) {
      return (
        <Flex
          sx={{
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            height: '100%',
          }}
        >
          <Spinner size={40} />
        </Flex>
      );
    }

    return (
      <Box p={4}>
        <Box mb={4}>
          <Title level={3}>Billing Overview</Title>
          <Paragraph>
            <Text>
              Manage your payment information here{' '}
              <span role="img" aria-label="$">
                🏦
              </span>
            </Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Text strong>Default payment method</Text>
          <Box>{this.formatPaymentMethodInfo(defaultPaymentMethod)}</Box>
        </Box>

        <Box mb={4}>
          <Elements stripe={stripe}>
            <PaymentForm onSuccess={this.handleUpdatePaymentMethod} />
          </Elements>
        </Box>
      </Box>
    );
  }
}

export default BillingOverview;
