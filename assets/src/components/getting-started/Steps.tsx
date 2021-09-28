import React from 'react';
import {Box} from 'theme-ui';
import {Link} from 'react-router-dom';

import type {Inbox, OnboardingStatus} from '../../types';
import {colors, Button, Divider, Text} from '../common';
import {CheckOutlined} from '../icons';

type StepMetadata = {
  completed?: boolean;
  ctaHref: string;
  ctaText: string;
  text: React.ReactElement;
};

type StepsProps = {
  onboardingStatus: OnboardingStatus;
  inbox: Inbox;
};

const Steps = ({onboardingStatus, inbox}: StepsProps) => {
  const stepsMetadata: Array<StepMetadata> = getStepsMetadata(
    onboardingStatus,
    inbox
  );

  return (
    <>
      {stepsMetadata.map((stepMetadata, index) => (
        <Step {...stepMetadata} value={index + 1} key={stepMetadata.ctaText} />
      ))}
    </>
  );
};

const getStepsMetadata = (
  onboardingStatus: OnboardingStatus,
  inbox: Inbox
): Array<StepMetadata> => {
  const {id: inboxId} = inbox;

  return [
    {
      completed: onboardingStatus.has_configured_inbox,
      ctaHref: `/inboxes/${inboxId}`,
      ctaText: 'Configure your inbox',
      text: (
        <>
          <Text strong>Configure your inbox</Text> to start receiving messages
          via <Link to={`/inboxes/${inboxId}/chat-widget`}>live chat</Link> and
          many other channels.
        </>
      ),
    },
    {
      completed: onboardingStatus.has_configured_profile,
      ctaHref: '/settings/profile',
      ctaText: 'Set up profile',
      text: (
        <>
          <Text strong>Set up your profile</Text> to personalize the experience
          with your customers.
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
          with and supporting your customers.
        </>
      ),
    },
    {
      completed: onboardingStatus.has_integrations,
      ctaHref: '/integrations',
      ctaText: 'Add integrations',
      text: (
        <>
          <Text strong>Connect more integrations</Text> to make the most of
          Papercups.
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
  const opacity = completed ? 0.6 : 1;

  return (
    <>
      <Box p={3} sx={{display: 'flex', alignItems: 'center'}}>
        <StepIcon value={value} completed={completed} />
        <Box mx={3} mr={4} sx={{flexGrow: 1, opacity}}>
          {text}
        </Box>
        <Link
          to={ctaHref}
          style={{
            alignContent: 'flex-end',
          }}
        >
          <Button type="default">{ctaText}</Button>
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
    height: '32px',
    justifyContent: 'center',
    minWidth: '32px',
    width: '32px',
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
