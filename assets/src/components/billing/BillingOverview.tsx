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
    // {key: 'discount', feature: 'Discount', price: 0},
    {key: 'total', feature: 'Total', price: 0},
  ];

  return <Table dataSource={data} columns={columns} pagination={false} />;
};

type Props = {};
type State = {
  loading: boolean;
  updating: boolean;
  displayPricingModal: boolean;
  displayCreditCardModal: boolean;
  defaultPaymentMethod: any;
  selectedSubscriptionPlan: string | null;
};

class BillingOverview extends React.Component<Props, State> {
  state = {
    loading: true,
    updating: false,
    displayPricingModal: false,
    displayCreditCardModal: false,
    defaultPaymentMethod: null,
    selectedSubscriptionPlan: null,
  };

  async componentDidMount() {
    const {
      subscription,
      product,
      num_users: numUsers,
      num_messages: numMessages,
      payment_method: defaultPaymentMethod,
      subscription_plan: selectedSubscriptionPlan,
    } = await API.fetchBillingInfo();

    console.log({
      subscription,
      product,
      numUsers,
      numMessages,
      defaultPaymentMethod,
      selectedSubscriptionPlan,
    });

    this.setState({
      defaultPaymentMethod,
      selectedSubscriptionPlan,
      loading: false,
    });
  }

  handleOpenCreditCardModal = () => {
    this.setState({displayCreditCardModal: true});
  };

  handleCloseCreditCardModal = () => {
    this.setState({displayCreditCardModal: false});
  };

  handleUpdatePaymentMethod = (paymentMethod: any) => {
    this.setState({
      defaultPaymentMethod: paymentMethod,
      displayCreditCardModal: false,
    });

    notification.success({
      message: 'Payment method updated!',
      description: "Don't worry, you haven't been charged for anything yet.",
      duration: 10, // 10 seconds
    });
  };

  handleOpenPricingModal = () => {
    this.setState({displayPricingModal: true});
  };

  handleCancelPricingModal = () => {
    this.setState({displayPricingModal: false});
  };

  handleSelectSubscriptionPlan = (plan: string) => {
    console.log('Selected plan!', plan);

    this.setState({selectedSubscriptionPlan: plan}, async () => {
      const {defaultPaymentMethod} = this.state;

      if (defaultPaymentMethod) {
        this.setState({updating: true});
        await API.updateSubscriptionPlan(plan);
        this.setState({displayPricingModal: false, updating: false});
      } else {
        this.setState({
          displayPricingModal: false,
          displayCreditCardModal: true,
        });
      }
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
    const {
      loading,
      updating,
      displayPricingModal,
      displayCreditCardModal,
      defaultPaymentMethod,
      selectedSubscriptionPlan,
    } = this.state;

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
          <Box>
            <Button
              icon={<RightCircleOutlined />}
              onClick={this.handleOpenPricingModal}
            >
              Update subscription plan
            </Button>

            <Modal
              title="Select plan"
              visible={displayPricingModal}
              width={800}
              onCancel={this.handleCancelPricingModal}
              footer={[
                <Button key="cancel" onClick={this.handleCancelPricingModal}>
                  Cancel
                </Button>,
              ]}
            >
              <PricingOptionsModal
                pending={updating}
                selected={selectedSubscriptionPlan}
                onSelectPlan={this.handleSelectSubscriptionPlan}
              />
            </Modal>
          </Box>
        </Box>

        <Box mb={4}>
          <BillingBreakdownTable />
        </Box>

        <Flex mb={4} sx={{alignItems: 'center'}}>
          <Box mr={2}>{this.formatPaymentMethodInfo(defaultPaymentMethod)}</Box>
          <Button
            type="primary"
            size="small"
            ghost
            onClick={this.handleOpenCreditCardModal}
          >
            Edit card
          </Button>
        </Flex>

        <Modal
          title="Update credit card information"
          visible={displayCreditCardModal}
          onCancel={this.handleCloseCreditCardModal}
          footer={null}
        >
          {/* TODO: maybe just try Stripe Checkout instead? */}
          <Elements stripe={stripe}>
            <PaymentForm
              onSuccess={this.handleUpdatePaymentMethod}
              onCancel={this.handleCloseCreditCardModal}
            />
          </Elements>
        </Modal>
      </Box>
    );
  }
}

export default BillingOverview;
