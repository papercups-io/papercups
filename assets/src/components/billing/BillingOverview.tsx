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
  Select,
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

type SubscriptionPlan = 'starter' | 'team';

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

const getPlanInfo = (plan: SubscriptionPlan) => {
  switch (plan) {
    case 'team':
      return {
        name: 'Team plan',
        includes: [
          {feature: '5 seats'},
          {feature: 'Unlimited messages'},
          {feature: 'Slack integration'},
          {feature: 'Webhooks'},
        ],
      };
    case 'starter':
    default:
      return {
        name: 'Starter plan',
        includes: [
          {feature: '2 seats'},
          {feature: '100,000 messages'},
          {feature: 'Slack integration'},
        ],
      };
  }
};

const BillingBreakdownTable = ({
  loading,
  plan,
  price,
}: {
  loading?: boolean;
  plan: SubscriptionPlan;
  price: number;
}) => {
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
            {price < 0 ? '-' : ''}${Math.abs(price / 100).toFixed(2)}
          </Text>
        );
      },
    },
  ];
  const {name, includes} = getPlanInfo(plan);
  // Just hard-coding for now
  const data = [
    {
      key: 'plan',
      feature: name,
      includes,
      price,
    },
    // {key: 'discount', feature: 'Discount', price},
    {key: 'total', feature: 'Total', price},
  ];

  return (
    <Table
      loading={loading}
      dataSource={data}
      columns={columns}
      pagination={false}
    />
  );
};

type Props = {};
type State = {
  loading: boolean;
  updating: boolean;
  refreshing: boolean;
  displayPricingModal: boolean;
  displayCreditCardModal: boolean;
  defaultPaymentMethod: any;
  subscription: any;
  selectedSubscriptionPlan: SubscriptionPlan;
};

class BillingOverview extends React.Component<Props, State> {
  state = {
    loading: true,
    updating: false,
    refreshing: false,
    displayPricingModal: false,
    displayCreditCardModal: false,
    defaultPaymentMethod: null,
    subscription: null,
    selectedSubscriptionPlan: 'starter' as SubscriptionPlan,
  };

  async componentDidMount() {
    await this.refreshBillingInfo();
  }

  refreshBillingInfo = async () => {
    this.setState({refreshing: true});

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
      subscription,
      loading: false,
      refreshing: false,
      selectedSubscriptionPlan: selectedSubscriptionPlan || 'starter',
    });
  };

  calculateSubscriptionPrice = (subscription: any) => {
    if (!subscription || !subscription.prices) {
      return 0;
    }

    const {prices = []} = subscription;

    return prices.reduce((total: number, price: any) => {
      const {
        active,
        currency,
        interval,
        interval_count: intervalCount,
        unit_amount: amount = 0,
      } = price;
      const isValidPrice =
        currency.toLowerCase() === 'usd' &&
        interval === 'month' &&
        intervalCount === 1;

      if (!isValidPrice) {
        throw new Error(`Unrecognized price: ${JSON.stringify(price)}`);
      }

      if (active) {
        return total + amount;
      }

      return total;
    }, 0);
  };

  handleOpenCreditCardModal = () => {
    this.setState({displayCreditCardModal: true});
  };

  handleCloseCreditCardModal = () => {
    this.setState({displayCreditCardModal: false});
    // TODO: just being lazy and refreshing the page to make sure the
    // selected subscription plan is accurately reflected in the UI
    this.refreshBillingInfo();
  };

  handleUpdatePaymentMethod = (paymentMethod: any) => {
    this.setState({
      defaultPaymentMethod: paymentMethod,
      displayCreditCardModal: false,
    });

    notification.success({
      message: 'Success!',
      description: "You've successfully updated your billing information.",
      duration: 10, // 10 seconds
    });

    this.refreshBillingInfo();
  };

  handleOpenPricingModal = () => {
    this.setState({displayPricingModal: true});
  };

  handleCancelPricingModal = () => {
    this.setState({displayPricingModal: false});
  };

  createOrUpdateSubscription = async (plan: SubscriptionPlan) => {
    if (this.state.subscription) {
      await API.updateSubscriptionPlan(plan);
    } else {
      await API.createSubscriptionPlan(plan);
    }
  };

  handleSelectSubscriptionPlan = (plan: SubscriptionPlan) => {
    console.log('Selected plan!', plan);

    this.setState({selectedSubscriptionPlan: plan}, async () => {
      const {defaultPaymentMethod} = this.state;

      if (defaultPaymentMethod) {
        this.setState({updating: true});
        await this.createOrUpdateSubscription(plan);
        this.setState({
          displayPricingModal: false,
          updating: false,
        });
        await this.refreshBillingInfo();
      } else {
        this.setState({
          displayPricingModal: false,
          displayCreditCardModal: true,
        });
      }
    });
  };

  getNextDueDate = (subscription: any) => {
    if (!subscription || !subscription.current_period_start) {
      return null;
    }

    const {current_period_start: currentPeriodStart} = subscription;
    const date = dayjs(new Date(currentPeriodStart * 1000));

    return date.add(1, 'month').format('MMMM DD, YYYY');
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
      refreshing,
      displayPricingModal,
      displayCreditCardModal,
      defaultPaymentMethod,
      selectedSubscriptionPlan,
      subscription,
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

    const {name: planName} = getPlanInfo(selectedSubscriptionPlan);
    const subscriptionPlanPrice = this.calculateSubscriptionPrice(subscription);
    const nextDueDate = this.getNextDueDate(subscription);

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
            <Flex sx={{alignItems: 'center'}}>
              <Box mr={3}>
                <Text>
                  You are currently on the <Text strong>{planName}</Text>
                </Text>
              </Box>

              <Button
                icon={<RightCircleOutlined />}
                onClick={this.handleOpenPricingModal}
              >
                Update subscription plan
              </Button>
            </Flex>

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
          <BillingBreakdownTable
            loading={refreshing}
            plan={selectedSubscriptionPlan}
            price={subscriptionPlanPrice}
          />
        </Box>

        <Flex mb={3} sx={{alignItems: 'center'}}>
          <Box mr={2}>{this.formatPaymentMethodInfo(defaultPaymentMethod)}</Box>
          <Button
            type="primary"
            size="small"
            ghost
            onClick={this.handleOpenCreditCardModal}
          >
            {!!defaultPaymentMethod ? 'Edit' : 'Add'} card
          </Button>
        </Flex>

        <Box mb={4}>
          <Text type="secondary">
            Next due date: <Text strong>{nextDueDate}</Text>
          </Text>
        </Box>

        <Modal
          title="Update credit card information"
          visible={displayCreditCardModal}
          onCancel={this.handleCloseCreditCardModal}
          footer={null}
        >
          <Box mb={3}>
            <Box mb={1}>
              <Text strong>Subscription plan</Text>
            </Box>
            <Select
              style={{width: '100%', maxWidth: 400}}
              defaultValue={selectedSubscriptionPlan}
              value={selectedSubscriptionPlan}
              onChange={(plan) =>
                this.setState({selectedSubscriptionPlan: plan})
              }
            >
              <Select.Option value="starter">
                Starter plan ($0/month)
              </Select.Option>
              <Select.Option value="team">Team plan ($40/month)</Select.Option>
            </Select>
          </Box>
          {/* TODO: maybe just try Stripe Checkout instead? */}
          <Elements stripe={stripe}>
            <PaymentForm
              plan={selectedSubscriptionPlan}
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
