import React from 'react';
import {Box} from 'theme-ui';
import * as API from '../../api';
import Title from 'antd/lib/typography/Title';
import {Paragraph, Input, colors, Text} from '../common';
import {TwitterPicker} from 'react-color';
import SyntaxHighlighter from 'react-syntax-highlighter';
import ChatWidget from '@papercups-io/chat-widget';
import {atomOneLight} from 'react-syntax-highlighter/dist/esm/styles/hljs';

type Props = {};
type State = {
  account: any;
  color: string;
  title: string;
  subtitle: string;
};

class GettingStartedOverview extends React.Component<Props, State> {
  async componentDidMount() {
    const account = await API.fetchAccountInfo();

    this.setState({account});
  }
  state: State = {
    account: null,
    color: colors.primary,
    title: 'Welcome to Papercups!',
    subtitle: 'Ask us anything in the chat window below 😊',
    // accountId: account.id,
  };

  handleChangeTitle = (e: any) => {
    this.setState({title: e.target.value});
  };

  handleChangeSubtitle = (e: any) => {
    this.setState({subtitle: e.target.value});
  };

  handleChangeColor = (color: any) => {
    this.setState({color: color.hex});
  };

  generateCode = (
    title: string,
    subtitle: string,
    primaryColor: string,
    accountId: string
  ) => {
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
    return {REACT_CODE, HTML_CODE};
  };

  render() {
    const {color, title, subtitle, account} = this.state;

    const accountId = account ? account.id : '';
    return (
      <Box
        p={5}
        sx={{
          maxWidth: 720,
        }}
      >
        <Box mb={4}>
          <Title>Getting Started</Title>
        </Box>
        <Paragraph>
          <Text>
            Customize your widget with the form and color picker. It'll update
            the code below for easy copy and pasting.
          </Text>
        </Paragraph>

        <Box mb={4}>
          <Paragraph>Update the title:</Paragraph>
          <Input type="text" value={title} onChange={this.handleChangeTitle} />
        </Box>

        <Box mb={4}>
          <Paragraph>Update the subtitle:</Paragraph>
          <Input
            type="text"
            value={subtitle}
            onChange={this.handleChangeSubtitle}
          />
        </Box>

        <Box mb={4}>
          <Paragraph>Try changing the color:</Paragraph>
          <TwitterPicker
            color={this.state.color}
            onChangeComplete={this.handleChangeColor}
          />
        </Box>

        <ChatWidget
          title={title || 'Welcome'}
          subtitle={subtitle}
          primaryColor={color}
          accountId={accountId}
          baseUrl={'https://app.papercups.io'}
          defaultIsOpen={true}
        />

        <Box>
          <Title level={2}>Setup Widget</Title>
          <Paragraph>
            <Text>
              Before you can start receiving messages here in your dashboard,
              you'll need to install the chat widget into your website.{' '}
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
            {this.generateCode(title, subtitle, color, accountId).HTML_CODE}
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
              Your account token has been prefilled in the code below. Simply
              copy and paste the code into whichever pages you would like to
              display the chat widget!
            </Text>
          </Paragraph>
          <SyntaxHighlighter language="typescript" style={atomOneLight}>
            {this.generateCode(title, subtitle, color, accountId).REACT_CODE}
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
      </Box>
    );
  }
}

export default GettingStartedOverview;
