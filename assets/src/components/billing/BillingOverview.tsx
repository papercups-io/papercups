import React from 'react';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import {Elements} from '@stripe/react-stripe-js';
import {loadStripe} from '@stripe/stripe-js';
import * as API from '../../api';
import {Alignment} from '../../types';
import {
  colors,
  notification,
  Alert,
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
import {
  SubscriptionPlan,
  getBrandName,
  getPlanInfo,
  getNextDueDate,
  getTrialEndDate,
  getFirstOfNextMonth,
  shouldRequirePlanUpdate,
  calculateSubscriptionDiscount,
  calculateSubscriptionPrice,
} from './support';
import logger from '../../logger';
import './Billing.css';

const stripe = loadStripe(
  process.env.REACT_APP_STRIPE_PUBLIC_KEY || 'pk_test_xxxxx'
);

const BillingBreakdownTable = ({
  loading,
  plan,
  price,
  discount = 0,
}: {
  loading?: boolean;
  plan: SubscriptionPlan;
  price: number;
  discount?: number;
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
  const data = [
    {
      key: 'plan',
      feature: name,
      includes,
      price,
    },
    discount
      ? {key: 'discount', feature: 'Discount', price: -1 * discount}
      : null,
    {key: 'total', feature: 'Total', price: price - discount},
  ]
    .filter((item) => !!item)
    .map((item) => item as object);

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
  requiresPlanUpdate: boolean;
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
    requiresPlanUpdate: false,
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

    logger.debug({
      subscription,
      product,
      numUsers,
      numMessages,
      defaultPaymentMethod,
      selectedSubscriptionPlan,
    });

    const plan = selectedSubscriptionPlan || 'starter';

    this.setState({
      defaultPaymentMethod,
      subscription,
      loading: false,
      refreshing: false,
      selectedSubscriptionPlan: plan,
      requiresPlanUpdate: shouldRequirePlanUpdate(plan, {
        numUsers,
        numMessages,
      }),
    });
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

  handleUpdatePaymentMethod = async (paymentMethod: any) => {
    const {selectedSubscriptionPlan} = this.state;

    await this.createOrUpdateSubscription(selectedSubscriptionPlan);

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
    logger.debug('Selected plan!', plan);

    if (plan === this.state.selectedSubscriptionPlan) {
      this.setState({displayPricingModal: false});

      return;
    }

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
      requiresPlanUpdate,
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
    const subscriptionPlanPrice = calculateSubscriptionPrice(subscription);
    const subscriptionPlanDiscount = calculateSubscriptionDiscount(
      subscription
    );
    const nextDueDate = getNextDueDate(subscription);
    const trialEndDate = getTrialEndDate(subscription);

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

          {requiresPlanUpdate && (
            <Box mb={3}>
              <Alert
                message={
                  <Text>
                    It looks like you've exceeded the limits of your current
                    plan. Please upgrade to the <Text strong>Team plan</Text> by{' '}
                    {getFirstOfNextMonth()} to prevent any features from
                    disabling!
                  </Text>
                }
                type="warning"
                showIcon
              />
            </Box>
          )}

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
            discount={subscriptionPlanDiscount}
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

        <Box mb={3}>
          {nextDueDate && (
            <Box mb={3}>
              <Text type="secondary">
                Next billing date: <Text strong>{nextDueDate}</Text>
              </Text>
            </Box>
          )}

          {trialEndDate && (
            <Box mb={3}>
              <Text type="secondary">
                (Free trial ends <Text strong>{trialEndDate}</Text>)
              </Text>
            </Box>
          )}
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
              style={{width: '100%'}}
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
