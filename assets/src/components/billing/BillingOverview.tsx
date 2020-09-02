import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Elements} from '@stripe/react-stripe-js';
import {loadStripe} from '@stripe/stripe-js';
import * as API from '../../api';
import {
  colors,
  notification,
  Button,
  Modal,
  Paragraph,
  Table,
  Text,
  Title,
} from '../common';
import {CreditCardTwoTone, RightCircleOutlined} from '../icons';
import Spinner from '../Spinner';
import PaymentForm from './PaymentForm';
import {PricingOptionsModal} from './PricingOverview';
import './Billing.css';

const stripe = loadStripe(
  process.env.REACT_APP_STRIPE_PUBLIC_KEY || 'pk_test_xxxxx'
);

enum Alignment {
  Right = 'right',
  Left = 'left',
  Center = 'center',
}

const BillingBreakdownTable = () => {
  const columns = [
    {
      title: 'Subscription',
      dataIndex: 'feature',
      key: 'feature',
      render: (value: string, record: any) => {
        const {includes = []} = record;

        return (
          <Box>
            <Box mb={includes.length ? 2 : 0}>
              <Text strong>{value}</Text>
            </Box>
            {includes.map((included: any) => {
              const {feature} = included;

              return (
                <Flex key={feature} mb={2} sx={{alignItems: 'center'}}>
                  <Box mr={2}>
                    <RightCircleOutlined />
                  </Box>
                  <Text type="secondary">{feature}</Text>
                </Flex>
              );
            })}
          </Box>
        );
      },
    },
    {
      title: 'Price per month',
      dataIndex: 'price',
      key: 'price',
      align: Alignment.Right,
      className: 'BillingBreakdownTable-priceCell',
      render: (price: number) => {
        return (
          <Text strong>
            {price < 0 ? '-' : ''}${Math.abs(price).toFixed(2)}
          </Text>
        );
      },
    },
  ];
  // Just hard-coding for now
  const data = [
    {
      key: 'plan',
      feature: 'Starter plan',
      includes: [
        {feature: '2 seats'},
        {feature: '100,000 messages'},
        {feature: 'Slack integration'},
      ],
      price: 0,
    },
    {key: 'discount', feature: 'Discount', price: 0},
    {key: 'total', feature: 'Total', price: 0},
  ];

  return <Table dataSource={data} columns={columns} pagination={false} />;
};

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

    notification.success({
      message: 'Payment method updated!',
      description:
        "Don't worry, you won't be charged unless you upgrade your account.",
      duration: 10, // 10 seconds
    });
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

          {/* TODO: implement logic to select subscription plan */}
          {false && (
            <Box>
              <Button>Select plan</Button>

              <Modal
                title="Select plan"
                visible={false}
                width={800}
                onOk={console.log}
                onCancel={console.log}
              >
                <PricingOptionsModal />
              </Modal>
            </Box>
          )}
        </Box>

        <Box mb={4}>
          <BillingBreakdownTable />
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
