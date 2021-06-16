import React from 'react';
import {Box} from 'theme-ui';
import {Link} from 'react-router-dom';
import {colors, Button, Divider, Text, Title} from '../common';
import {CheckOutlined} from '../icons';

import * as API from '../../api';

type GettingStartedStep = {
  completed: boolean;
  ctaHref: string;
  ctaText: string;
  text: React.ReactNode;
};

const GettingStarted = () => {
  API.getGettingStartedSteps()
    .then((response) => console.log('getting started steps', response))
    .catch((error) => console.log({error}));
  const steps: Array<GettingStartedStep> = [
    {
      completed: false,
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
      completed: false,
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
      completed: false,
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
      completed: false,
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
      completed: false,
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
      completed: false,
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
        <Step {...step} value={index + 1} />
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
