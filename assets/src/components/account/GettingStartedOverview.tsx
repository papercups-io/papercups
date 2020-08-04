import React from 'react';
import {Box} from 'theme-ui';
import {TwitterPicker} from 'react-color';
import SyntaxHighlighter from 'react-syntax-highlighter';
import {atomOneLight} from 'react-syntax-highlighter/dist/esm/styles/hljs';
import ChatWidget from '@papercups-io/chat-widget';
import * as API from '../../api';
import {Paragraph, Input, colors, Text, Title} from '../common';
import {BASE_URL} from '../../config';

type Props = {};
type State = {
  accountId: string | null;
  color: string;
  title: string;
  subtitle: string;
};

class GettingStartedOverview extends React.Component<Props, State> {
  state: State = {
    accountId: null,
    color: colors.primary,
    title: 'Welcome!',
    subtitle: 'Ask us anything in the chat window below 😊',
  };

  async componentDidMount() {
    const account = await API.fetchAccountInfo();
    const {
      id: accountId,
      company_name: company,
      widget_settings: widgetSettings,
    } = account;

    this.setState({accountId, title: `Welcome to ${company}`});

    if (widgetSettings && widgetSettings.id) {
      const {color, title, subtitle} = widgetSettings;

      this.setState({
        color: color || this.state.color,
        subtitle: subtitle || this.state.subtitle,
        title: title || `Welcome to ${company}`,
      });
    }
  }

  handleChangeTitle = (e: any) => {
    this.setState({title: e.target.value});
  };

  handleChangeSubtitle = (e: any) => {
    this.setState({subtitle: e.target.value});
  };

  handleChangeColor = (color: any) => {
    this.setState({color: color.hex}, () => {
      this.updateWidgetSettings();
    });
  };

  updateWidgetSettings = async () => {
    const {color, title, subtitle} = this.state;

    API.updateWidgetSettings({color, title, subtitle})
      .then((res) => console.log('Updated widget settings:', res))
      .catch((err) => console.log('Error updating widget settings:', err));
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
        baseUrl='${BASE_URL}'
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
      baseUrl: '${BASE_URL}'
    },
  };
</script>
<script
  type="text/javascript"
  async
  defer
  src="${BASE_URL}/widget.js"
></script>
  `.trim();
    return {REACT_CODE, HTML_CODE};
  };

  render() {
    const {color, title, subtitle, accountId} = this.state;

    if (!accountId) {
      return null; // TODO: better loading state
    }

    return (
      <Box
        p={4}
        sx={{
          maxWidth: 720,
        }}
      >
        <Box mb={4}>
          <Title>Getting Started</Title>
          <Paragraph>
            <Text>
              Before you can start chatting with your customers, you'll need to
              install our chat component on your website.
            </Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Title level={3}>Customize your widget</Title>
          <Paragraph>
            <Text>
              Customize your widget with the form and color picker. It will
              update the preview to the right as well as the code below so you
              can easily copy and paste it into your website looking just the
              way you like!
            </Text>
          </Paragraph>

          <Box mb={3}>
            <label htmlFor="title">Update the title:</label>
            <Input
              id="title"
              type="text"
              placeholder="Welcome!"
              value={title}
              onChange={this.handleChangeTitle}
              onBlur={this.updateWidgetSettings}
            />
          </Box>

          <Box mb={3}>
            <label htmlFor="subtitle">Update the subtitle:</label>
            <Input
              id="subtitle"
              type="text"
              placeholder="How can we help you?"
              value={subtitle}
              onChange={this.handleChangeSubtitle}
              onBlur={this.updateWidgetSettings}
            />
          </Box>

          <Box mb={3}>
            <Paragraph>Try changing the color:</Paragraph>
            <TwitterPicker
              color={this.state.color}
              onChangeComplete={this.handleChangeColor}
            />
          </Box>

          <ChatWidget
            title={title || 'Welcome!'}
            subtitle={subtitle}
            primaryColor={color}
            accountId={accountId}
            baseUrl={BASE_URL}
            defaultIsOpen
          />
        </Box>

        <Box mb={4}>
          <Title level={3}>Installing the widget</Title>
          <Paragraph>
            <Text>
              Before you can start receiving messages here in your dashboard,
              you'll need to install the chat widget into your website.{' '}
              <span role="img" aria-label=":)">
                😊
              </span>
            </Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
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
        </Box>

        <Box mb={4}>
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
        </Box>

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
  }
}

export default GettingStartedOverview;
