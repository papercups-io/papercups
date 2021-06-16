import React from 'react';
import {Box, Flex, Spinner} from 'theme-ui';
import {Link} from 'react-router-dom';
import {colors, Button, Divider, Text, Title} from '../common';
import {CheckOutlined} from '../icons';

import * as API from '../../api';
import {GettingStartedSteps as StepStatuses} from '../../types';
import logger from '../../logger';

type GettingStartedStep = {
  completed: boolean;
  ctaHref: string;
  ctaText: string;
  text: React.ReactElement;
};

const GettingStarted = () => {
  const [stepStatuses, setStepStatuses] = React.useState<StepStatuses>({
    configured_profile: false,
    configured_storytime: false,
    has_integrations: false,
    installed_chat_widget: false,
    invited_teammates: false,
    upgraded_subscription: false,
  });
  const [isLoading, setIsLoading] = React.useState(true);

  React.useEffect(() => {
    (async () => {
      try {
        const statuses = await API.getGettingStartedSteps();
        setStepStatuses(statuses);
      } catch (error) {
        logger.error('Failed to query getting started steps:', error);
      }

      setIsLoading(false);
    })();
  }, []);

  if (isLoading) {
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

  const steps: Array<GettingStartedStep> = [
    {
      completed: stepStatuses.installed_chat_widget,
      ctaHref: '/settings/chat-widget',
      ctaText: 'Configure chat widget',
      text: (
        <>
          <Text strong>Configure and install the chat widget</Text> to start
          receiving messages.
        </>
      ),
    },
    {
      completed: stepStatuses.invited_teammates,
      ctaHref: '/settings/team',
      ctaText: 'Invite teammates',
      text: (
        <>
          <Text strong>Invite your teammates</Text> to join you in connecting
          with your customers.
        </>
      ),
    },
    {
      completed: stepStatuses.configured_profile,
      ctaHref: '/settings/profile',
      ctaText: 'Configure profile',
      text: (
        <>
          <Text strong>Configure your profile</Text> by adding your display name
          and profile photo so your customers know who they're talking to.
        </>
      ),
    },
    {
      completed: stepStatuses.has_integrations,
      ctaHref: '/integrations',
      ctaText: 'Set up integrations',
      text: (
        <>
          <Text strong>Set up integrations</Text> like Slack, Gmail, and SMS to
          add more channels for your customers to contact you.
        </>
      ),
    },
    {
      completed: stepStatuses.configured_storytime,
      ctaHref: '/sessions/setup',
      ctaText: 'Set up StoryTime',
      text: (
        <>
          <Text strong>Set up StoryTime</Text> to view how customers are using
          your website.
        </>
      ),
    },
    {
      completed: stepStatuses.upgraded_subscription,
      ctaHref: '/settings/billing',
      ctaText: 'Upgrade subscription',
      text: (
        <>
          <Text strong>Upgrade your subscription</Text> for access to even more
          features!
        </>
      ),
    },
  ];

  return (
    <Box p={4} sx={{maxWidth: 1080}}>
      <Box mb={4}>
        <Title level={3}>Welcome to Papercups</Title>
      </Box>
      <Divider />
      {steps.map((step, index) => (
        <Step {...step} value={index + 1} key={step.ctaText} />
      ))}
    </Box>
  );
};

type StepProps = {
  completed: boolean;
  ctaHref: string;
  ctaText: string;
  text: React.ReactNode;
  value: number;
};

const Step = ({completed, ctaHref, ctaText, text, value}: StepProps) => {
  const opacity = completed ? 0.5 : 1;

  return (
    <>
      <Box p={3} sx={{display: 'flex', alignItems: 'center'}}>
        <StepIcon value={value} completed={completed} />
        <Box mx={3} sx={{flexGrow: 1, opacity}}>
          {text}
        </Box>
        <Link
          to={ctaHref}
          style={{
            alignContent: 'flex-end',
            opacity,
          }}
        >
          <Button>{ctaText}</Button>
        </Link>
      </Box>
      <Divider />
    </>
  );
};

const StepIcon = ({completed, value}: {completed: boolean; value: number}) => {
  const styles = {
    alignItems: 'center',
    borderRadius: '50%',
    display: 'flex',
    fontSize: '16px',
    height: '40px',
    justifyContent: 'center',
    minWidth: '40px',
    width: '40px',
  };

  if (completed) {
    return (
      <Box
        sx={{
          ...styles,
          backgroundColor: colors.primary,
          color: colors.white,
        }}
      >
        <CheckOutlined />
      </Box>
    );
  } else {
    return (
      <Box
        sx={{
          ...styles,
          border: `1px solid ${colors.primary}`,
          color: colors.primary,
        }}
      >
        {value}
      </Box>
    );
  }
};

export default GettingStarted;
