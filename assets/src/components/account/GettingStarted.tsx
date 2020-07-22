import React from 'react';
import {Box} from 'theme-ui';
import {colors, Paragraph, Text, Title} from '../common';
import SyntaxHighlighter from 'react-syntax-highlighter';
import {atomOneLight} from 'react-syntax-highlighter/dist/esm/styles/hljs';

const GettingStarted = ({
  accountId,
  primaryColor = '#13c2c2',
  subtitle,
  title,
}: {
  accountId: string;
  primaryColor?: string;
  subtitle: string;
  title: string;
}) => {
  const REACT_CODE = `
import React from 'react';
import ChatWidget from '@papercups-io/chat-widget';

const ExamplePage = () => {
  return (
    <>
      {/*
        Put <ChatWidget /> at the bottom of whatever pages you would
        like to render the widget on, or in your root/router component
        if you would like it to render on every page
      */}
      <ChatWidget
        title='${title}'
        subtitle= '${subtitle}'
        primaryColor='${primaryColor}'
        accountId='${accountId}'
      />
    </>
  );
};
  `.trim();

  const HTML_CODE = `
<script>
  window.Papercups = {
    config: {
      accountId: '${accountId}',
      title: '${title}',
      subtitle: '${subtitle}',
      primaryColor: '${primaryColor}',
    },
  };
</script>
<script
  type="text/javascript"
  async
  defer
  src="https://app.papercups.io/widget.js"
></script>
  `.trim();

  return (
    <Box>
      <Paragraph>
        <Text>
          Before you can start receiving messages here in your dashboard, you'll
          need to install the chat widget into your website.{' '}
          <span role="img" aria-label=":)">
            😊
          </span>
        </Text>
      </Paragraph>

      <Title level={3}>Usage in HTML</Title>
      <Paragraph>
        <Text>
          Paste the code below between your <Text code>{'<head>'}</Text> and{' '}
          <Text code>{'</head>'}</Text> tags:
        </Text>
      </Paragraph>

      <SyntaxHighlighter language="html" style={atomOneLight}>
        {HTML_CODE}
      </SyntaxHighlighter>

      <Title level={3}>Usage in React</Title>
      <Paragraph>
        <Text>
          First, install the <Text code>@papercups-io/chat-widget</Text>{' '}
          package:
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
          <Box p={3}>npm install --save @papercups-io/chat-widget</Box>
        </pre>
      </Paragraph>
      <Paragraph>
        <Text>
          Your account token has been prefilled in the code below. Simply copy
          and paste the code into whichever pages you would like to display the
          chat widget!
        </Text>
      </Paragraph>
      <SyntaxHighlighter language="typescript" style={atomOneLight}>
        {REACT_CODE}
      </SyntaxHighlighter>

      <Title level={3}>Learn more</Title>
      <Paragraph>
        <Text>
          See the code and star our{' '}
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
