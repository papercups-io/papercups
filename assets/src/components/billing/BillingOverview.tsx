import React from 'react';
import {capitalize} from 'lodash';
import dayjs from 'dayjs';
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

type CreditCardBrand =
  | 'amex'
  | 'cartes_bancaires'
  | 'diners_club'
  | 'discover'
  | 'jcb'
  | 'mastercard'
  | 'visa'
  | 'unionpay'
  | string;

const getBrandName = (brand: CreditCardBrand) => {
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
    const {
      subscription,
      product,
      num_users: numUsers,
      num_messages: numMessages,
      payment_method: defaultPaymentMethod,
      subscription_plan: subscriptionPlan,
    } = await API.fetchBillingInfo();

    console.log({
      subscription,
      product,
      numUsers,
      numMessages,
      defaultPaymentMethod,
      subscriptionPlan,
    });

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
        <Text type="secondary">
          No credit card information has been entered yet.
        </Text>
      );
    }

    const {brand, last4, exp_month, exp_year} = paymentMethod;
    const brandName = getBrandName(brand);
    const expiresAt = dayjs()
      .set('month', exp_month - 1)
      .set('year', exp_year)
      .format('MMM YYYY');

    return (
      <Text type="secondary">
        Billed to <CreditCardTwoTone twoToneColor={colors.primary} />{' '}
        {brandName} ending in {last4} (expires {expiresAt})
      </Text>
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

        <Box mb={4}>{this.formatPaymentMethodInfo(defaultPaymentMethod)}</Box>

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
