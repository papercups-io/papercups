import React, {FunctionComponent} from 'react';
import {capitalize, debounce} from 'lodash';
import {Box} from 'theme-ui';
import {TwitterPicker} from 'react-color';
import {ChatWidget, Papercups} from '@papercups-io/chat-widget';
import {Prism as SyntaxHighlighter} from 'react-syntax-highlighter';
import {prism as syntaxHighlightingLanguage} from 'react-syntax-highlighter/dist/esm/styles/prism';
import * as API from '../../api';
import {Account, User, WidgetIconVariant} from '../../types';
import {
  colors,
  Paragraph,
  Popover,
  Input,
  Select,
  Switch,
  Text,
  Title,
  Tabs,
} from '../common';
import {InfoCircleTwoTone} from '../icons';
import {BASE_URL, FRONTEND_BASE_URL} from '../../config';
import logger from '../../logger';

type Props = {};
type State = {
  accountId: string | null;
  account: Account | null;
  color: string;
  title: string;
  subtitle: string;
  greeting?: string;
  awayMessage?: string;
  newMessagePlaceholder?: string;
  currentUser: User | null;
  showAgentAvailability: boolean;
  agentAvailableText?: string;
  agentUnavailableText?: string;
  requireEmailUpfront: boolean;
  iconVariant: WidgetIconVariant;
};

class GettingStartedOverview extends React.Component<Props, State> {
  state: State = {
    accountId: null,
    account: null,
    currentUser: null,
    color: colors.primary,
    title: 'Welcome!',
    subtitle: 'Ask us anything in the chat window below 😊',
    greeting: '',
    awayMessage: '',
    newMessagePlaceholder: 'Start typing...',
    showAgentAvailability: false,
    agentAvailableText: `We're online right now!`,
    agentUnavailableText: `We're away at the moment.`,
    requireEmailUpfront: false,
    iconVariant: 'outlined',
  };

  async componentDidMount() {
    const currentUser = await API.me();
    const account = await API.fetchAccountInfo();
    const {
      id: accountId,
      company_name: company,
      widget_settings: widgetSettings,
    } = account;

    if (widgetSettings && widgetSettings.id) {
      const {
        color,
        title,
        subtitle,
        greeting,
        new_message_placeholder: newMessagePlaceholder,
        show_agent_availability: showAgentAvailability,
        agent_available_text: agentAvailableText,
        agent_unavailable_text: agentUnavailableText,
        require_email_upfront: requireEmailUpfront,
        icon_variant: iconVariant,
        away_message: awayMessage,
      } = widgetSettings;

      this.setState({
        accountId,
        account,
        currentUser,
        greeting,
        awayMessage,
        color: color || this.state.color,
        subtitle: subtitle || this.state.subtitle,
        title: title || `Welcome to ${company}`,
        newMessagePlaceholder: newMessagePlaceholder || 'Start typing...',
        showAgentAvailability:
          showAgentAvailability || this.state.showAgentAvailability,
        agentAvailableText: agentAvailableText || this.state.agentAvailableText,
        agentUnavailableText:
          agentUnavailableText || this.state.agentUnavailableText,
        requireEmailUpfront:
          requireEmailUpfront || this.state.requireEmailUpfront,
        iconVariant: iconVariant || this.state.iconVariant,
      });
    } else {
      this.setState({
        accountId,
        account,
        currentUser,
        title: `Welcome to ${company}`,
      });
    }
  }

  debouncedUpdateWidgetSettings = debounce(
    () => this.updateWidgetSettings(),
    400
  );

  handleChangeTitle = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({title: e.target.value}, this.debouncedUpdateWidgetSettings);
  };

  handleChangeSubtitle = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState(
      {subtitle: e.target.value},
      this.debouncedUpdateWidgetSettings
    );
  };

  handleChangeGreeting = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState(
      {greeting: e.target.value},
      this.debouncedUpdateWidgetSettings
    );
  };

  handleChangeAwayMessage = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState(
      {awayMessage: e.target.value},
      this.debouncedUpdateWidgetSettings
    );
  };

  handleChangeNewMessagePlaceholder = (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    this.setState(
      {newMessagePlaceholder: e.target.value},
      this.debouncedUpdateWidgetSettings
    );
  };

  handleChangeRequireEmailUpfront = (isChecked: boolean) => {
    this.setState(
      {requireEmailUpfront: isChecked},
      this.debouncedUpdateWidgetSettings
    );
  };

  handleChangeShowingAgentAvailability = (isChecked: boolean) => {
    this.setState(
      {showAgentAvailability: isChecked},
      this.debouncedUpdateWidgetSettings
    );
  };

  handleChangeAgentAvailableText = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState(
      {agentAvailableText: e.target.value},
      this.debouncedUpdateWidgetSettings
    );
  };

  handleChangeAgentUnavailableText = (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    this.setState(
      {agentUnavailableText: e.target.value},
      this.debouncedUpdateWidgetSettings
    );
  };

  handleChangeIconVariant = (variant: 'outlined' | 'filled') => {
    // Ensure the chat is closed to view the icon
    Papercups.close();

    this.setState({iconVariant: variant}, this.debouncedUpdateWidgetSettings);
  };

  handleChangeColor = (color: any) => {
    this.setState({color: color.hex}, this.debouncedUpdateWidgetSettings);
  };

  updateWidgetSettings = async () => {
    const {
      color,
      title,
      subtitle,
      greeting,
      awayMessage,
      newMessagePlaceholder,
      showAgentAvailability,
      agentAvailableText,
      agentUnavailableText,
      requireEmailUpfront,
      iconVariant,
    } = this.state;

    API.updateWidgetSettings({
      color,
      title,
      subtitle,
      greeting,
      away_message: awayMessage,
      new_message_placeholder: newMessagePlaceholder,
      show_agent_availability: showAgentAvailability,
      agent_available_text: agentAvailableText,
      agent_unavailable_text: agentUnavailableText,
      require_email_upfront: requireEmailUpfront,
      icon_variant: iconVariant,
    })
      .then((res) => logger.debug('Updated widget settings:', res))
      .catch((err) => logger.error('Error updating widget settings:', err));
  };

  getUserMetadata = () => {
    const {account, currentUser} = this.state;

    if (!account || !currentUser) {
      return {};
    }

    const {id, email} = currentUser;

    // TODO: include name if available
    return {
      email: email,
      external_id: [id, email].join('|'),
      metadata: {
        company_name: account.company_name,
        subscription_plan: account.subscription_plan,
      },
    };
  };

  render() {
    const {
      accountId,
      color,
      title,
      subtitle,
      greeting,
      awayMessage,
      newMessagePlaceholder,
      showAgentAvailability,
      agentAvailableText,
      agentUnavailableText,
      requireEmailUpfront,
      iconVariant,
    } = this.state;

    if (!accountId) {
      return null; // TODO: better loading state
    }

    const customer = this.getUserMetadata();

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
            <label htmlFor="greeting">
              Set a greeting (requires page refresh to view):
            </label>
            <Input
              id="greeting"
              type="text"
              placeholder="Hello! Any questions?"
              value={greeting}
              onChange={this.handleChangeGreeting}
              onBlur={this.updateWidgetSettings}
            />
          </Box>

          <Box mb={3}>
            <label htmlFor="away_message">
              Set an away message (will replace greeting message outside working
              hours):
            </label>
            <Input
              id="away_message"
              type="text"
              placeholder="Sorry, we're away at the moment!"
              value={awayMessage}
              onChange={this.handleChangeAwayMessage}
              onBlur={this.updateWidgetSettings}
            />
          </Box>

          <Box mb={3}>
            <label htmlFor="new_message_placeholder">
              Update the new message placeholder text:
            </label>
            <Input
              id="new_message_placeholder"
              type="text"
              placeholder="Start typing..."
              value={newMessagePlaceholder}
              onChange={this.handleChangeNewMessagePlaceholder}
              onBlur={this.updateWidgetSettings}
            />
          </Box>

          <Box mb={4}>
            <Paragraph>Try changing the color:</Paragraph>
            <TwitterPicker
              color={this.state.color}
              onChangeComplete={this.handleChangeColor}
            />
          </Box>

          <Box mb={4}>
            <label htmlFor="icon_variant">
              Icon style (close the chat to view)
            </label>

            <Box>
              <Select
                id="icon_variant"
                style={{width: 280}}
                value={iconVariant}
                onChange={this.handleChangeIconVariant}
                options={['outlined', 'filled'].map((variant) => {
                  return {value: variant, label: capitalize(variant)};
                })}
              />
            </Box>
          </Box>

          <Box mb={1}>
            <label htmlFor="require_email_upfront">
              Require unidentified customers to provide their email upfront?{' '}
              <Popover
                content={
                  <Box sx={{maxWidth: 200}}>
                    This will only show up for anonymous users. To see an
                    example of what this looks like, visit{' '}
                    <a
                      href="https://papercups.io"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      https://papercups.io
                    </a>{' '}
                    and open the chat.
                  </Box>
                }
                title={null}
              >
                <InfoCircleTwoTone twoToneColor={colors.primary} />
              </Popover>
            </label>
          </Box>
          <Box mb={3}>
            <Switch
              checked={requireEmailUpfront}
              onChange={this.handleChangeRequireEmailUpfront}
            />
          </Box>

          <Box mb={1}>
            <label htmlFor="show_agent_availability">
              Show agent availability?
            </label>
          </Box>
          <Box mb={3}>
            <Switch
              checked={showAgentAvailability}
              onChange={this.handleChangeShowingAgentAvailability}
            />
          </Box>

          <Box mb={3}>
            <label htmlFor="agent_available_text">
              Set the text displayed when agents are available:
            </label>
            <Input
              id="agent_available_text"
              type="text"
              placeholder="We're online right now!"
              value={agentAvailableText}
              onChange={this.handleChangeAgentAvailableText}
              onBlur={this.updateWidgetSettings}
            />
          </Box>

          <Box mb={3}>
            <label htmlFor="agent_unavailable_text">
              Set the text displayed when agents are unavailable:
            </label>
            <Input
              id="agent_unavailable_text"
              type="text"
              placeholder="We're away at the moment."
              value={agentUnavailableText}
              onChange={this.handleChangeAgentUnavailableText}
              onBlur={this.updateWidgetSettings}
            />
          </Box>

          <ChatWidget
            title={title || 'Welcome!'}
            subtitle={subtitle}
            primaryColor={color}
            greeting={greeting}
            awayMessage={awayMessage}
            showAgentAvailability={showAgentAvailability}
            agentAvailableText={agentAvailableText}
            agentUnavailableText={agentUnavailableText}
            requireEmailUpfront={requireEmailUpfront}
            newMessagePlaceholder={newMessagePlaceholder}
            accountId={accountId}
            customer={customer}
            baseUrl={BASE_URL}
            iconVariant={iconVariant}
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

        <CodeSnippet
          accountId={accountId}
          title={title}
          subtitle={subtitle}
          color={color}
          greeting={greeting}
          awayMessage={awayMessage}
          newMessagePlaceholder={newMessagePlaceholder}
          showAgentAvailability={showAgentAvailability}
          agentAvailableText={agentAvailableText}
          agentUnavailableText={agentUnavailableText}
          requireEmailUpfront={requireEmailUpfront}
          iconVariant={iconVariant}
        />

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

enum Languages {
  HTML = 'HTML',
  REACT = 'REACT',
}

const StandardSyntaxHighlighter: FunctionComponent<{language: string}> = ({
  language,
  children,
}) => {
  return (
    <SyntaxHighlighter language={language} style={syntaxHighlightingLanguage}>
      {children}
    </SyntaxHighlighter>
  );
};

const CodeSnippet: FunctionComponent<Pick<
  State,
  | 'accountId'
  | 'title'
  | 'subtitle'
  | 'color'
  | 'greeting'
  | 'awayMessage'
  | 'newMessagePlaceholder'
  | 'showAgentAvailability'
  | 'agentAvailableText'
  | 'agentUnavailableText'
  | 'requireEmailUpfront'
  | 'iconVariant'
>> = ({
  accountId,
  title,
  subtitle,
  color,
  greeting,
  awayMessage,
  newMessagePlaceholder,
  showAgentAvailability,
  agentAvailableText,
  agentUnavailableText,
  requireEmailUpfront,
  iconVariant,
}) => {
  return (
    <Tabs
      defaultActiveKey={Languages.HTML}
      type="card"
      className="GettingStartedCode"
    >
      <Tabs.TabPane tab="HTML" key={Languages.HTML}>
        <Box mb={4}>
          <Title level={3}>Usage in HTML</Title>
          <Paragraph>
            <Text>
              Paste the code below between your <Text code>{'<head>'}</Text> and{' '}
              <Text code>{'</head>'}</Text> tags:
            </Text>
          </Paragraph>

          <StandardSyntaxHighlighter language="html">
            {`
<script>
window.Papercups = {
  config: {
    accountId: "${accountId}",
    title: "${title}",
    subtitle: "${subtitle}",
    primaryColor: "${color}",
    greeting: "${greeting || ''}",
    awayMessage: "${awayMessage || ''}",
    newMessagePlaceholder: "${newMessagePlaceholder || ''}",
    showAgentAvailability: ${showAgentAvailability},
    agentAvailableText: "${agentAvailableText}",
    agentUnavailableText: "${agentUnavailableText}",
    requireEmailUpfront: ${requireEmailUpfront},
    iconVariant: "${iconVariant}",
    baseUrl: "${BASE_URL}",
    // Optionally include data about your customer here to identify them
    // customer: {
    //   name: __CUSTOMER__.name,
    //   email: __CUSTOMER__.email,
    //   external_id: __CUSTOMER__.id,
    //   metadata: {
    //     plan: "premium"
    //   }
    // }
  },
};
</script>
<script
type="text/javascript"
async
defer
src="${FRONTEND_BASE_URL}/widget.js"
></script>
`.trim()}
          </StandardSyntaxHighlighter>
        </Box>
      </Tabs.TabPane>

      <Tabs.TabPane tab="React" tabKey={Languages.REACT}>
        <Box mb={4}>
          <Title level={3}>Usage in React</Title>
          <Paragraph>
            <Text>
              First, install the <Text code>@papercups-io/chat-widget</Text>{' '}
              package:
            </Text>
          </Paragraph>

          <Paragraph>
            <StandardSyntaxHighlighter language="bash">
              npm install --save @papercups-io/chat-widget
            </StandardSyntaxHighlighter>
          </Paragraph>

          <Paragraph>
            <Text>
              Your account token has been prefilled in the code below. Simply
              copy and paste the code into whichever pages you would like to
              display the chat widget!
            </Text>
          </Paragraph>

          <StandardSyntaxHighlighter language="typescript">
            {`
import React from "react";
import {ChatWidget} from "@papercups-io/chat-widget";

const ExamplePage = () => {
  return (
    <>
      {/*
        Put <ChatWidget /> at the bottom of whatever pages you would
        like to render the widget on, or in your root/router component
        if you would like it to render on every page
      */}
      <ChatWidget
        accountId="${accountId}"
        title="${title}"
        subtitle="${subtitle}"
        primaryColor="${color}"
        greeting="${greeting || ''}"
        awayMessage="${awayMessage || ''}"
        newMessagePlaceholder="${newMessagePlaceholder}"
        showAgentAvailability={${showAgentAvailability}}
        agentAvailableText="${agentAvailableText}"
        agentUnavailableText="${agentUnavailableText}"
        requireEmailUpfront={${requireEmailUpfront}}
        iconVariant="${iconVariant}"
        baseUrl="${BASE_URL}"
        // Optionally include data about your customer here to identify them
        // customer={{
        //   name: __CUSTOMER__.name,
        //   email: __CUSTOMER__.email,
        //   external_id: __CUSTOMER__.id,
        //   metadata: {
        //     plan: "premium"
        //   }
        // }}
      />
    </>
  );
};
`.trim()}
          </StandardSyntaxHighlighter>
        </Box>
      </Tabs.TabPane>
    </Tabs>
  );
};

export default GettingStartedOverview;
