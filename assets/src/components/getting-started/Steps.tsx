import React from 'react';
import {Box} from 'theme-ui';
import {Link} from 'react-router-dom';

import type {OnboardingStatus} from '../../types';
import {colors, Button, Divider, Text} from '../common';
import {CheckOutlined} from '../icons';

type StepMetadata = {
  completed?: boolean;
  ctaHref: string;
  ctaText: string;
  text: React.ReactElement;
};

type StepsProps = {
  onboardingStatus: Partial<OnboardingStatus>;
};

const Steps = ({onboardingStatus}: StepsProps) => {
  const stepsMetadata: Array<StepMetadata> = getStepsMetadata(onboardingStatus);

  return (
    <>
      {stepsMetadata.map((stepMetadata, index) => (
        <Step {...stepMetadata} value={index + 1} key={stepMetadata.ctaText} />
      ))}
    </>
  );
};

const getStepsMetadata = (
  onboardingStatus: Partial<OnboardingStatus>
): Array<StepMetadata> => {
  return [
    {
      completed: onboardingStatus.is_chat_widget_installed,
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
      completed: onboardingStatus.has_invited_teammates,
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
      completed: onboardingStatus.has_configured_profile,
      ctaHref: '/settings/profile',
      ctaText: 'Configure profile',
      text: (
        <>
          <Text strong>Configure your profile</Text> by adding your name and
          photo so your customers know who they're talking to.
        </>
      ),
    },
    {
      completed: onboardingStatus.has_integrations,
      ctaHref: '/integrations',
      ctaText: 'Set up integrations',
      text: (
        <>
          <Text strong>Set up integrations</Text> like Slack, Gmail, and SMS to
          add more channels for your customer communication.
        </>
      ),
    },
    {
      completed: onboardingStatus.has_configured_storytime,
      ctaHref: '/sessions/setup',
      ctaText: 'Set up Storytime',
      text: (
        <>
          <Text strong>Set up Storytime</Text> to view how customers are using
          your website.
        </>
      ),
    },
    {
      completed: onboardingStatus.has_upgraded_subscription,
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
};

type StepProps = {
  completed?: boolean;
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

type StepIconProps = {
  completed?: boolean;
  value: number;
};

const StepIcon = ({completed, value}: StepIconProps) => {
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

export default Steps;
