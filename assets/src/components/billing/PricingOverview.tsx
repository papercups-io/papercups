import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Divider, Paragraph, Text, Title} from '../common';

type Props = {};
type State = {};

const PricingCard = ({
  title,
  description,
  cta,
  pricing,
  features,
}: {
  title: string;
  description: string;
  cta: React.ReactElement;
  pricing: React.ReactElement;
  features: React.ReactElement;
}) => {
  return (
    <Box
      mx={2}
      p={3}
      sx={{
        flex: 1,
        border: '1px solid #f5f5f5',
        borderRadius: 4,
        boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 8px',
      }}
    >
      <Title level={3}>{title}</Title>
      <Paragraph style={{minHeight: 44}}>{description}</Paragraph>

      <Box my={3}>{cta}</Box>

      <Box sx={{fontSize: 16}}>{pricing}</Box>

      <Divider />

      {features}
    </Box>
  );
};

const PricingSection = ({
  title,
  description,
  cta,
  pricing,
  features,
  bordered,
}: {
  title: string;
  description: string;
  cta: React.ReactElement;
  pricing: React.ReactElement;
  features: React.ReactElement;
  bordered?: boolean;
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
      <Title level={3}>{title}</Title>
      <Paragraph style={{minHeight: 44}}>{description}</Paragraph>

      <Box my={3}>{cta}</Box>

      <Box sx={{fontSize: 16}}>{pricing}</Box>

      <Divider />

      {features}
    </Box>
  );
};

class PricingOverview extends React.Component<Props, State> {
  state = {};

  async componentDidMount() {
    //
  }

  render() {
    return (
      <Box p={4}>
        <Box mb={4}>
          <Title level={1}>Pricing Overview</Title>
        </Box>

        <Flex mx={-2} sx={{maxWidth: 960}}>
          <PricingCard
            title="Starter"
            description="Basic live chat and inbox to get you started."
            cta={
              <Button type="primary" size="large" block ghost>
                Create free account
              </Button>
            }
            pricing={
              <Text>
                <Text strong>$0</Text> forever
              </Text>
            }
            features={
              <>
                <Paragraph>Comes with:</Paragraph>

                <Paragraph>
                  <li>2 agents</li>
                  <li>Unlimited conversations</li>
                  <li>Customizable chat widget</li>
                  <li>Slack integration</li>
                </Paragraph>
              </>
            }
          />

          <PricingCard
            title="Team"
            description="Supercharge your support, sales, and marketing."
            cta={
              <Button type="primary" size="large" block>
                Create an account
              </Button>
            }
            pricing={
              <Text>
                <Text strong>$40</Text>/month
              </Text>
            }
            features={
              <>
                <Paragraph>
                  Everything in <Text strong>Starter</Text> plus:
                </Paragraph>

                <Paragraph>
                  <li>Includes 5 seats</li>
                  <li>Chat bots</li>
                  <li>Additional integrations</li>
                  <li>Webhooks</li>
                </Paragraph>
              </>
            }
          />

          <PricingCard
            title="Custom"
            description="Advanced workflows, security, and support."
            cta={
              <Button type="primary" size="large" block ghost>
                Chat with us
              </Button>
            }
            pricing={<Text>Custom pricing</Text>}
            features={
              <>
                <Paragraph>
                  Everything in <Text strong>Team</Text> plus:
                </Paragraph>

                <Paragraph>
                  <li>Unlimited agents</li>
                  <li>First-class support</li>
                  <li>Custom integrations</li>
                </Paragraph>
              </>
            }
          />
        </Flex>

        <Divider />

        <Flex mx={-2} sx={{maxWidth: 960}}>
          <PricingSection
            title="Starter"
            description="Basic live chat and inbox to get you started."
            cta={
              <Button type="primary" size="large" block ghost>
                Create free account
              </Button>
            }
            pricing={
              <Text>
                <Text strong>$0</Text> forever
              </Text>
            }
            features={
              <>
                <Paragraph>Comes with:</Paragraph>

                <Paragraph>
                  <li>2 agents</li>
                  <li>Unlimited conversations</li>
                  <li>Customizable chat widget</li>
                  <li>Slack integration</li>
                </Paragraph>
              </>
            }
          />

          <PricingSection
            title="Team"
            description="Supercharge your support, sales, and marketing."
            cta={
              <Button type="primary" size="large" block>
                Create an account
              </Button>
            }
            pricing={
              <Text>
                <Text strong>$40</Text>/month
              </Text>
            }
            features={
              <>
                <Paragraph>
                  Everything in <Text strong>Starter</Text> plus:
                </Paragraph>

                <Paragraph>
                  <li>Includes 5 seats</li>
                  <li>Chat bots</li>
                  <li>Additional integrations</li>
                  <li>Webhooks</li>
                </Paragraph>
              </>
            }
            bordered
          />

          <PricingSection
            title="Custom"
            description="Advanced workflows, security, and support."
            cta={
              <Button type="primary" size="large" block ghost>
                Chat with us
              </Button>
            }
            pricing={<Text>Custom pricing</Text>}
            features={
              <>
                <Paragraph>
                  Everything in <Text strong>Team</Text> plus:
                </Paragraph>

                <Paragraph>
                  <li>Unlimited agents</li>
                  <li>First-class support</li>
                  <li>Custom integrations</li>
                </Paragraph>
              </>
            }
          />
        </Flex>
      </Box>
    );
  }
}

export default PricingOverview;
