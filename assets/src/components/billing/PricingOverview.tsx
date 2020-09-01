import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Paragraph, Text, Title} from '../common';

type Props = {};
type State = {};

class PricingOverview extends React.Component<Props, State> {
  state = {};

  async componentDidMount() {
    //
  }

  render() {
    return (
      <Box p={4}>
        <Box mb={4}>
          <Title level={2}>Pricing Overview</Title>
          <Paragraph>
            <Text>Pricing details will go here!</Text>
          </Paragraph>
        </Box>

        <Flex mx={-2} sx={{maxWidth: 960}}>
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
            <Title level={3}>Starter</Title>
            <Paragraph>Basic live chat and inbox to get started</Paragraph>
            <Box>$0</Box>
            <Box>forever</Box>

            <Box my={2}>
              <Button type="primary" size="large" block>
                Create free account
              </Button>
            </Box>

            <Box>2 agents</Box>
            <Box>Unlimited conversations</Box>
            <Box>Customizable chat widget</Box>
            <Box>Slack integration</Box>
          </Box>

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
            <Title level={3}>Team</Title>
            <Paragraph>Supercharge your customer messaging</Paragraph>

            <Box>$40</Box>
            <Box>per month</Box>

            <Box my={2}>
              <Button type="primary" size="large" block>
                Create an account
              </Button>
            </Box>

            <Box>5 agents</Box>
            <Box>Everything in Community plus:</Box>
            <Box>Chat bots</Box>
            <Box>Additional integrations</Box>
            <Box>Webhooks</Box>
          </Box>

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
            <Title level={3}>Custom</Title>
            <Paragraph>Advanced workflows and support</Paragraph>

            <Box>Custom</Box>
            <Box>contact us</Box>

            <Box my={2}>
              <Button type="primary" size="large" block>
                Chat with us
              </Button>
            </Box>

            <Box>Unlimited agents</Box>
            <Box>Everything in Team plus:</Box>
            <Box>First-class support</Box>
            <Box>Custom integrations</Box>
          </Box>
        </Flex>
      </Box>
    );
  }
}

export default PricingOverview;
