import React from 'react';
import {Box} from 'theme-ui';
import {colors, Paragraph, Text, Title} from '../common';

const GettingStarted = ({accountId}: {accountId: string}) => {
  const code = `
import React from 'react';
import ChatWidget from '@papercups-io/chat-widget';
import '@papercups-io/chat-widget/dist/index.css';

const ExamplePage = () => {
  return (
    <>
      {/*
        Put <ChatWidget /> at the bottom of whatever pages you would
        like to render the widget on, or in your root/router component
        if you would like it to render on every page
      */}
      <ChatWidget accountId='${accountId}' />;
    </>
  );
};
  `.trim();

  return (
    <Box>
      <Title level={2}>Getting started</Title>
      <Paragraph>
        <Text>
          Before you can start receiving messages here in your dashboard, you'll
          need to install the chat widget into your website. 😊
        </Text>
      </Paragraph>
      <Paragraph>
        <Text strong mark>
          NB: For now, the code below will only work in React apps, but general
          support is coming soon!
        </Text>
      </Paragraph>
      <Title level={3}>Install</Title>
      <Paragraph>
        <pre
          style={{
            backgroundColor: '#f6f8fa',
            color: colors.black,
            fontSize: 12,
          }}
        >
          <Box p={3}>npm install --save @papercups-io/chat-widget</Box>
        </pre>
      </Paragraph>
      <Title level={3}>Usage</Title>
      <Paragraph>
        <Text>
          Your account token has been prefilled in the code below. Simply copy
          and paste the code into whichever pages you would like to display the
          chat widget!
        </Text>
      </Paragraph>
      <Paragraph>
        <pre
          style={{
            backgroundColor: '#f6f8fa',
            color: colors.black,
            fontSize: 12,
          }}
        >
          <Box p={3}>{code}</Box>
        </pre>
      </Paragraph>
      <Paragraph>
        <Text>
          See the code and learn more in our{' '}
          <a
            href="https://github.com/papercups-io/chat-widget"
            target="_blank"
            rel="noopener noreferrer"
          >
            Github repo
          </a>
          .
        </Text>
      </Paragraph>
    </Box>
  );
};

export default GettingStarted;
