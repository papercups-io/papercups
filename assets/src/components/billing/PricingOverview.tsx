import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors, Button, Divider, Paragraph, Text, Title} from '../common';
import {CheckCircleTwoTone} from '../icons';
import {SubscriptionPlan} from './support';
import {LITE_PRICE, STARTER_PRICE, TEAM_PRICE} from '../../constants';

const PricingSection = ({
  title,
  description,
  cta,
  pricing,
  features,
  bordered,
  selected,
}: {
  title: string;
  description: string;
  cta: React.ReactElement;
  pricing: React.ReactElement;
  features: React.ReactElement;
  bordered?: boolean;
  selected?: boolean;
}) => {
  return (
    <Box
      mx={2}
      p={3}
      sx={{
        flex: 1,
        border: bordered ? '1px solid #f5f5f5' : 'none',
      }}
    >
      <Flex sx={{alignItems: 'baseline', justifyContent: 'space-between'}}>
        <Title level={3}>{title}</Title>
        {selected && (
          <CheckCircleTwoTone
            twoToneColor={colors.green}
            style={{fontSize: 16}}
          />
        )}
      </Flex>
      <Paragraph style={{minHeight: 44}}>{description}</Paragraph>

      <Box my={3}>{cta}</Box>

      <Box sx={{fontSize: 16}}>{pricing}</Box>

      <Divider />

      {features}
    </Box>
  );
};

// TODO: move to separate file?
export const PricingOptionsModal = ({
  pending,
  selected = 'starter',
  onSelectPlan,
}: {
  pending?: boolean;
  selected: SubscriptionPlan | null;
  onSelectPlan: (plan: SubscriptionPlan) => void;
}) => {
  const handleSelectStarterPlan = () => onSelectPlan('starter');
  const handleSelectTeamPlan = () => onSelectPlan('team');
  const handleSelectLitePlan = () => onSelectPlan('lite');

  return (
    <Flex mx={-2} sx={{maxWidth: 960}}>
      <PricingSection
        title="Starter"
        description="Basic live chat and inbox to get you started."
        cta={
          <Button
            type="primary"
            size="large"
            block
            ghost={selected !== 'starter'}
            disabled={pending}
            loading={selected === 'starter' && pending}
            onClick={handleSelectStarterPlan}
          >
            Select Starter plan
          </Button>
        }
        pricing={
          <Text>
            <Text strong>${STARTER_PRICE}</Text>/month
          </Text>
        }
        features={
          <>
            <Paragraph>Comes with:</Paragraph>

            <Paragraph>
              <ul>
                <li>2 seats included</li>
                <li>1000 messages/month</li>
                <li>30 day message retention</li>
                <li>Customizable chat widget</li>
              </ul>
            </Paragraph>
          </>
        }
        selected={selected === 'starter'}
      />

      <PricingSection
        title="Lite"
        description="Essential chat functionality for your business."
        cta={
          <Button
            type="primary"
            size="large"
            block
            disabled={pending}
            loading={selected === 'lite' && pending}
            ghost={selected !== 'lite'}
            onClick={handleSelectLitePlan}
          >
            Select Lite plan
          </Button>
        }
        pricing={
          <Text>
            <Text strong>${LITE_PRICE}</Text>/month
          </Text>
        }
        features={
          <>
            <Paragraph>
              Everything in <Text strong>Starter</Text> plus:
            </Paragraph>

            <Paragraph>
              <ul>
                <li>4 seats included</li>
                <li>Unlimited messages</li>
                <li>3 months data retention</li>
                <li>Private notes</li>
                <li>Reply from Slack</li>
              </ul>
            </Paragraph>
          </>
        }
        bordered
        selected={selected === 'lite'}
      />
      <PricingSection
        title="Team"
        description="Supercharge your support, sales, and marketing."
        cta={
          <Button
            type="primary"
            size="large"
            block
            disabled={pending}
            loading={selected === 'team' && pending}
            ghost={selected !== 'team'}
            onClick={handleSelectTeamPlan}
          >
            Select Team plan
          </Button>
        }
        pricing={
          <Text>
            <Text strong>${TEAM_PRICE}</Text>/month
          </Text>
        }
        features={
          <>
            <Paragraph>
              Everything in <Text strong>Lite</Text> plus:
            </Paragraph>

            <Paragraph>
              <ul>
                <li>10 seats included</li>
                <li>Unlimited data retention</li>
                <li>Website screen sharing</li>
                <li>Webhooks</li>
                <li>Priority support</li>
              </ul>
            </Paragraph>
          </>
        }
        bordered
        selected={selected === 'team'}
      />

      <PricingSection
        title="Enterprise"
        description="Advanced workflows, security, and support."
        cta={
          <a href="mailto:founders@papercups.io?Subject=Papercups Enterprise Edition">
            <Button type="primary" size="large" block ghost disabled={pending}>
              Contact sales
            </Button>
          </a>
        }
        pricing={<Text>Custom pricing</Text>}
        features={
          <>
            <Paragraph>
              Everything in <Text strong>Team</Text> plus:
            </Paragraph>

            <Paragraph>
              <ul>
                <li>Unlimited seats</li>
                <li>On-premise deployment</li>
                <li>Custom integrations</li>
              </ul>
            </Paragraph>
          </>
        }
      />
    </Flex>
  );
};
